# Performance

For larger or more volatile loads, we recommend [enabling Fluentd autoscaling](./Best_Practices.md#Fluentd-Autoscaling), as this will allow Fluentd to automatically scale to support your data volume. However, the following examples will help you get an idea of the resources required to run collection on your cluster.

## Up to 500 application pods
Our test cluster had 70 nodes running 500 application pods, each generating 128KB/s logs and 1200 DPM metrics.

Data type | Rate per pod | # pods   | Total rate
--------- | ------------ | -------- | ----------
Logs      | 128 KB/s     | 500 pods | 64 MB/s = **5.5 TB/day**
Metrics   | 1200 DPM     | 500 pods | **600K DPM**

We observed **35 Fluentd-logs** pods and **25 Fluentd-metrics** pods were sufficient for handling this load with the default resource limits.

Prometheus memory consumption reached a maximum of **28GiB**.

## Up to 2000 application pods
Our test cluster had 210 nodes running 200 application pods, each generating 128KB/s logs and 1200 DPM metrics.

Data type | Rate per pod | # pods   | Total rate
--------- | ------------ | -------- | ----------
Logs      | 128 KB/s     | 2000 pods | 256 MB/s = **22 TB/day**
Metrics   | 1200 DPM     | 2000 pods | **2.4M DPM**

We observed **135 Fluentd-logs** pods and **100 Fluentd-metrics** pods were sufficient for handling this load with the default resource limits. Additionally the **Fluentd-events** pod had to be given a 1 GiB memory limit to accommodate the increased events load.

Prometheus memory consumption reached a maximum of **60GiB**.



