# Performance

For larger or more volatile loads, we recommend [enabling Fluentd autoscaling](./Best_Practices.md#Fluentd-Autoscaling), as this will allow Fluentd to automatically scale to support your data volume. However, the following recommendations and corresponding examples will help you get an idea of the resources required to run collection on your cluster.

## Recommendations

1. At least **6 Fluentd-logs** pods per **1 TB/day** of logs.
2. At least **5 Fluentd-metrics** pods per **120k DPM** of metrics.
3. The Prometheus pod will use on average **2GiB** memory per **120k DPM**; however in our experience this has gone up to **5GiB**, so we recommend allocating ample memory resources for the Prometheus pod if you wish to collect a high volume of metrics for a larger cluster.

## Up to 500 application pods
Our test cluster had 70 nodes running an average of 500 application pods, each generating either 128KB/s logs or 2400 DPM metrics. The application pods had about 20% churn rate.

Data type | Rate per pod | Min # pods | Max # pods | Max Total rate
--------- | ------------ | ---------- | ---------- | --------------
Logs      | 128 KB/s     | 50 pods    | 400 pods   | **4.3 TB/day**
Metrics   | 2400 DPM     | 100 pods   | 450 pods   | **1.3M DPM** (including non-application metrics)

We observed **35 Fluentd-logs** pods and **25 Fluentd-metrics** pods were sufficient for handling this load with the default resource limits.

Prometheus memory consumption reached a maximum of **28GiB**, with an average of **16GiB**.

## Up to 2000 application pods
Our test cluster had 210 nodes running an average of 2000 application pods, each generating either 128KB/s logs or 2400 DPM metrics. The application pods had about 10% churn rate.

Data type | Rate per pod | Min # pods | Max # pods | Max Total rate
--------- | ------------ | ---------- | ---------- | --------------
Logs      | 128 KB/s     | 900 pods   | 1875 pods  | **20 TB/day**
Metrics   | 2400 DPM     | 125 pods   | 1100 pods  | **3.2M DPM** (including non-application metrics)


We observed **135 Fluentd-logs** pods and **100 Fluentd-metrics** pods were sufficient for handling this load with the default resource limits. Additionally the **Fluentd-events** pod had to be given a 1 GiB memory limit to accommodate the increased events load.

Prometheus memory consumption reached a maximum of **60GiB**, with an average of **45GiB**.
