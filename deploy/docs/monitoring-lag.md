# Monitoring the Monitoring

Once you have Sumo Logic's collection setup installed, you should be primed to have metrics, logs, and events flowing into Sumo Logic. However, as your cluster scales up and down, you might find the need to rescale your fluentd deployment replica count. Here are some tips on how to judge if you're seeing lag in your Sumo Logic collection pipeline.

1. Kubernetes Health Check Dashboard

This dashboard can be found from the `Cluster` level in `Explore`, and is a great way of holistically judging if your collection process is working as expected.

2. Fluentd Queue Length

On the health check dashboard you'll see a panel for fluentd queue length. If you see this length going up over time, chances are that you either have backpressure or you are overwhelming the fluentd pods with requests. If you see any `429` status codes in the fluentd logs, that means you are likely getting throttled and need to contact Sumo Logic to increase your base plan or increase the throttling limit. If you aren't seeing `429` then you likely are in a situation where the incoming traffic into Fluentd is higher than the current replica count can handle. This is a good indication that you should scale up.
