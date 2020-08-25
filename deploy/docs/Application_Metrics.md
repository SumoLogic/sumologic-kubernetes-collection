# Application Metrics

Gathering metrics from the applications is complex topic as they can expose it in various
non-well defined formats. Fortunately the most popular formats are supported by the Telegraf
or the applications are able to expose metrics in the prometheus format.
Scraping metrics in prometheus format was described in
[the separate document](./additional_prometheus_configuration.md)

## Nginx

Nginx exposes metrics in it's own format using
[stub_status_module](http://nginx.org/en/docs/http/ngx_http_stub_status_module.html).
Sumologic Kuberentes Collection can scrap metrics from the nginx using
[the nginx-prometheus-exporter](https://github.com/nginxinc/nginx-prometheus-exporter) or the Telegraf Operator.

**Note Some nginx operators/helm chart based installations exposes nginx metrics in prometheus format already.**

### Telegraf

To scrap metrics from the nginx you need to follow [this instruction](./Telegraf.md) using following annotations values:

```yaml
annotations:
  telegraf.influxdata.com/inputs: |+
    [[inputs.nginx]]
    urls = ["http://localhost/nginx_status"]
  telegraf.influxdata.com/class: sumologic-prometheus
```
