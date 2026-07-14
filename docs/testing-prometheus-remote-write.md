# Testing Prometheus Remote Write Receiver

This document describes how to send test metrics directly to the Prometheus Remote Write v2 receiver running on the metrics collector in
single-layer pipeline mode.

## Prerequisites

- Helm release deployed with `sumologic.metrics.collector.otelcol.singleLayerPipeline.enabled=true`
- The metrics collector pods are running
- Python 3 with `python-snappy` installed (`pip3 install python-snappy`)

## Architecture

In single-layer pipeline mode, the metrics collector exposes a Prometheus Remote Write receiver on **port 9888**. The service URL from
within the cluster is:

```
http://<release-name>-sumologic-metrics-collector.<namespace>:9888/api/v1/write
```

For example, with release `sumo3` in namespace `sumologic3`:

```
http://sumo3-sumologic-metrics-collector.sumologic3:9888/api/v1/write
```

The receiver only accepts **Remote Write v2** protocol (protobuf `io.prometheus.write.v2.Request` with snappy compression).

## Required HTTP Headers

| Header                              | Value                                                         |
| ----------------------------------- | ------------------------------------------------------------- |
| `Content-Type`                      | `application/x-protobuf;proto=io.prometheus.write.v2.Request` |
| `Content-Encoding`                  | `snappy`                                                      |
| `X-Prometheus-Remote-Write-Version` | `2.0.0`                                                       |

## Step 1: Generate the Protobuf Payload

The Remote Write v2 proto schema:

```protobuf
message Request {
  repeated string symbols = 4;
  repeated TimeSeries timeseries = 5;
}

message TimeSeries {
  repeated uint32 labels_refs = 1; // packed, indices into Request.symbols
  repeated Sample samples = 2;
}

message Sample {
  double value = 1;
  int64 timestamp = 2; // milliseconds
}
```

Key points:

- `symbols` is a flat string table; labels reference it by index pairs (name_index, value_index)
- `labels_refs` uses packed encoding
- Timestamps are in milliseconds since epoch

Python script to generate a valid payload:

```python
import struct
import time
import snappy

def encode_varint(value):
    result = b''
    while value > 0x7f:
        result += bytes([0x80 | (value & 0x7f)])
        value >>= 7
    result += bytes([value])
    return result

def encode_field_ld(field_number, data):
    tag = encode_varint((field_number << 3) | 2)
    return tag + encode_varint(len(data)) + data

def encode_field_varint(field_number, value):
    tag = encode_varint((field_number << 3) | 0)
    return tag + encode_varint(value)

def encode_field_fixed64(field_number, value):
    tag = encode_varint((field_number << 3) | 1)
    return tag + struct.pack('<d', value)

def encode_string(field_number, s):
    return encode_field_ld(field_number, s.encode('utf-8'))

# Define metric labels as symbol table entries
symbols = ["__name__", "test_metric_from_claude", "source", "manual_test"]

# Encode symbols (field 4 in Request)
symbols_encoded = b''
for s in symbols:
    symbols_encoded += encode_string(4, s)

# Labels refs: packed uint32 (field 1 in TimeSeries)
# Pairs: (0,1) = __name__:test_metric_from_claude, (2,3) = source:manual_test
labels_refs_data = encode_varint(0) + encode_varint(1) + encode_varint(2) + encode_varint(3)
labels_refs = encode_field_ld(1, labels_refs_data)

# Sample (field 2 in TimeSeries)
now_ms = int(time.time() * 1000)
sample = encode_field_fixed64(1, 42.0) + encode_field_varint(2, now_ms)
sample_encoded = encode_field_ld(2, sample)

# TimeSeries (field 5 in Request)
timeseries = labels_refs + sample_encoded
timeseries_encoded = encode_field_ld(5, timeseries)

# Full WriteRequest
write_request = symbols_encoded + timeseries_encoded

# Snappy compress
compressed = snappy.compress(write_request)

with open('/tmp/remote_write_v2_payload.bin', 'wb') as f:
    f.write(compressed)

print(f"Metric: test_metric_from_claude = 42.0, timestamp: {now_ms}")
```

## Step 2: Send the Payload from Inside the Cluster

Since the service is cluster-internal, send the request from a temporary pod:

```bash
# Generate payload
python3 generate_payload.py

# Base64 encode for transport
PAYLOAD_B64=$(base64 < /tmp/remote_write_v2_payload.bin)

# Send from inside the cluster
kubectl run -n sumologic3 test-rw --rm -i --restart=Never --image=curlimages/curl -- sh -c "
echo '$PAYLOAD_B64' | base64 -d > /tmp/payload.bin
curl -s -w '\nHTTP_CODE:%{http_code}\n' -X POST \
  'http://sumo3-sumologic-metrics-collector.sumologic3:9888/api/v1/write' \
  -H 'Content-Encoding: snappy' \
  -H 'Content-Type: application/x-protobuf;proto=io.prometheus.write.v2.Request' \
  -H 'X-Prometheus-Remote-Write-Version: 2.0.0' \
  --data-binary @/tmp/payload.bin
"
```

## Expected Responses

| HTTP Code | Meaning                                                                                        |
| --------- | ---------------------------------------------------------------------------------------------- |
| 204       | Success — metric accepted                                                                      |
| 400       | Bad request — malformed protobuf or encoding                                                   |
| 415       | Unsupported proto version — wrong `Content-Type` or `X-Prometheus-Remote-Write-Version` header |

## Step 3: Verify in Sumo Logic

Query the metric in Sumo Logic:

```
_collector=<collector-name> metric=test_metric_from_claude
```

## Common Pitfalls

1. **Using Remote Write v1 format** — The upstream `prometheusremotewritereceiver` only supports v2. You must use
   `Content-Type: application/x-protobuf;proto=io.prometheus.write.v2.Request` and the v2 proto schema.

2. **Wrong field numbers** — In v2, `TimeSeries.samples` is field **2** (not 3). `Request.timeseries` is field **5** (not 1). Double-check
   against the proto definition.

3. **Missing snappy compression** — The receiver requires `Content-Encoding: snappy`. Uncompressed payloads will be rejected.

4. **Service URL** — The receiver is only exposed on the metrics collector service (port 9888), not the headless service or monitoring
   service. The URL pattern is:
   ```
   http://<release>-sumologic-metrics-collector.<namespace>:9888/api/v1/write
   ```

## Alternative: Port-Forward for Local Testing

```bash
kubectl port-forward -n sumologic3 svc/sumo3-sumologic-metrics-collector 9888:9888 &

curl -s -w '\n%{http_code}\n' -X POST 'http://localhost:9888/api/v1/write' \
  -H 'Content-Encoding: snappy' \
  -H 'Content-Type: application/x-protobuf;proto=io.prometheus.write.v2.Request' \
  -H 'X-Prometheus-Remote-Write-Version: 2.0.0' \
  --data-binary @/tmp/remote_write_v2_payload.bin
```
