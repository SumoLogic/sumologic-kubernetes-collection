# Monitoring the Monitoring

Once you have Sumo Logic's collection setup installed, you should be primed to have metrics, logs, and events flowing into Sumo Logic. However, as your cluster scales up and down, you might find the need to rescale your fluentd deployment replica count. Here are some tips on how to judge if you're seeing lag in your Sumo Logic collection pipeline.

1. Kubernetes Health Check Dashboard

This dashboard can be found from the `Cluster` level in `Explore`, and is a great way of holistically judging if your collection process is working as expected.

2. Fluentd Queue Length

On the health check dashboard you'll see a panel for fluentd queue length. If you see this length going up over time, chances are that you either have backpressure or you are overwhelming the fluentd pods with requests. If you see any `429` status codes in the fluentd logs, that means you are likely getting throttled and need to contact Sumo Logic to increase your base plan or increase the throttling limit. If you aren't seeing `429` then you likely are in a situation where the incoming traffic into Fluentd is higher than the current replica count can handle. This is a good indication that you should scale up.

3. Check Prometheus Remote Write Metrics

Prometheus has a few metrics to monitor its remote write performance. You should check that the succeeded count is strictly non-zero and if looking at a cumulative metric, it is going up and to the right. Two other great metrics to check are `remote_storage_pending_samples` and `remote_storage_failed_samples`. Higher failure counts and pending counts are good indicators of queue buildup.

4. Check Prometheus Logs

If all else fails, check the prometheus logs. If there is anything suspicious happening with regards to the fluentd connection you'll see it in the Prometheus logs. Any logs that have `connection reset` or `context cancelled` in them are indicative of requests that were terminated or dropped. Too many of those and your data will start to lag.
