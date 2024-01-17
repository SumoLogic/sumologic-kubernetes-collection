# Monitoring the Monitoring

Once you have Sumo Logic's collection setup installed, you should be primed to have metrics, logs, and events flowing into Sumo Logic.

However, as your cluster scales up and down, you might find the need to scale your metadata enrichment Statefulset appropriately. To that
end, you may need to enable autoscaling for metadata enrichment and potentially tweak its settings.

Here are some tips on how to judge if you're seeing lag in your Sumo Logic collection pipeline.

1. Kubernetes Health Check Dashboard

   This dashboard can be found from the `Cluster` level in `Explore`, and is a great way of holistically judging if your collection process
   is working as expected.

1. OpenTelemetry Collector CPU usage

   Whenever your OpenTelemetry Collector Pods' CPU consumption is near the limit you could experience a delay in data ingestion or even a
   data loss in extreme situations. Usually this is caused by insufficient amount of OpenTelemetry Collector instances being available. In
   that case, consider
   [enabling autoscaling](https://help.sumologic.com/docs/send-data/kubernetes/best-practices/#opentelemetry-collector-autoscaling). If
   autoscaling is already enabled, increase `maxReplicas` until the average CPU usage normalizes.

1. OpenTelemetry Collector Queue Length

   The `otelcol_exporter_queue_size` metric can be used to monitor the length of the on-disk queue OpenTelemetry Collector uses for outgoing
   data. If you see this length going up over time, chances are that you either have backpressure or you are overwhelming the OpenTelemetry
   Collector pods with requests. If you see any `429` status codes in the OpenTelemetry Collector logs, that means you are likely getting
   throttled and need to contact Sumo Logic to increase your base plan or increase the throttling limit. If you aren't seeing `429` then you
   likely are in a situation where the incoming traffic into OpenTelemetry Collector is higher than the current replica count can handle.
   This is a good indication that you should scale up. Please see also
   [OpenTelemetry Collector queueing and batching](https://help.sumologic.com/docs/send-data/kubernetes/best-practices/#opentelemetry-collector-queueing-and-batching).

1. Check Prometheus Remote Write Metrics

   Prometheus has a few metrics to monitor its remote write performance. You should check that the succeeded count is strictly non-zero and
   if looking at a cumulative metric, it is going up and to the right. Two other great metrics to check are `remote_storage_pending_samples`
   and `remote_storage_failed_samples`. Higher failure counts and pending counts are good indicators of queue buildup.

1. Check Prometheus Logs

   If all else fails, check the Prometheus logs. If there is anything suspicious happening with regards to the connection to OpenTelemetry
   Collector, you'll see it in the Prometheus logs. Any logs that have `connection reset` or `context cancelled` in them are indicative of
   requests that were terminated or dropped. Too many of those and your data will start to lag.
