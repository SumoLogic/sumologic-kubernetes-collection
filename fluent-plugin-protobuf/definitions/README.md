# Prometheus protobufs definitions

These files store the protobufs definitions of Prometheus. They will be compiled to ruby source files with [ruby-protobuf](https://github.com/ruby-protobuf/protobuf/wiki/Compiling-Definitions) for parsing requests from Prometheus remote write API.

These files are coming from [Prometheus GitHub repository](https://github.com/prometheus/prometheus/tree/2bd510a63e48ac6bf4971d62199bdb1045c93f1a/prompb).

Download/refresh these files with following commands:

```bash
curl -O https://raw.githubusercontent.com/prometheus/prometheus/2bd510a63e48ac6bf4971d62199bdb1045c93f1a/prompb/remote.proto
curl -O https://raw.githubusercontent.com/prometheus/prometheus/2bd510a63e48ac6bf4971d62199bdb1045c93f1a/prompb/types.proto
curl -o ./gogoproto/gogo.proto -O https://raw.githubusercontent.com/gogo/protobuf/master/gogoproto/gogo.proto
```

And then compile them with:

```bash
protoc -I . --ruby_out ../lib *.proto
```