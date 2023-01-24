# Vagrant

## Prerequisites

Please install the following:

- [VirtualBox](https://www.oracle.com/virtualization/technologies/vm/downloads/virtualbox-downloads.html)
- [Vagrant](https://www.vagrantup.com/)
- [vagrant-disksize](https://github.com/sprotheroe/vagrant-disksize) plugin

### MacOS

```bash
brew install --cask virtualbox
brew install --cask vagrant
vagrant plugin install vagrant-disksize
```

## Setting up

You can set up the Vagrant environment with just one command:

```bash
vagrant up
```

If you experience following error (MacOS specific)

````
There was an error while executing `VBoxManage`, a CLI used by Vagrant
for controlling VirtualBox. The command and stderr is shown below.

Command: ["hostonlyif", "create"]

Stderr: 0%...
Progress state: NS_ERROR_FAILURE
VBoxManage: error: Failed to create the host-only adapter
VBoxManage: error: VBoxNetAdpCtl: Error while adding new interface: failed to open /dev/vboxnetctl: No such file or directory
VBoxManage: error: Details: code NS_ERROR_FAILURE (0x80004005), component HostNetworkInterfaceWrap, interface IHostNetworkInterface
VBoxManage: error: Context: "RTEXITCODE handleCreate(HandlerArg *)" at line 95 of file VBoxManageHostonly.cpp```
````

go to System Preferences > Security & Privacy Then hit the "Allow" for Oracle VirtualBox

After successfull installation you can ssh to the virtual machine with:

```bash
vagrant ssh
```

NOTICE: The directory with sumo-kubernetes-collection repository on the host is synced with `/sumologic/` directory on the virtual machine.

## Collector

To install or upgrade collector please type:

```bash
sumo-make upgrade
```

or

```bash
/sumologic/vagrant/Makefile upgrade
```

This command will prepare environment (namespaces, receiver-mock, etc.) and after that it will install/upgrade collector in the vagrant
environment.

To remove collector please use:

```bash
sumo-make clean
```

or

```bash
/sumologic/vagrant/Makefile clean
```

List of other useful targets:

- `expose-prometheus` - exposes prometheus on port 9090 of virtual machine
- `expose-grafana` - exposes grafana on port 8080 of virtual machine
- `apply-avalanche` - run one pod deployment of avalanche (metrics generator)

## Test

In order to quickly test whether sumo-kubernetes-collection works, one can use `receiver-mock` for that purpose.

To check receiver-mock logs please use:

```bash
sumo-make test-receiver-mock-logs
```

or

```bash
/sumologic/vagrant/Makefile test-receiver-mock-logs
```

To check metrics exposed by receiver-mock please use:

```bash
sumo-make test-receiver-mock-metrics
```

or

```bash
/sumologic/vagrant/Makefile test-receiver-mock-metrics
```

## Istio

In order to setup istio, please use the following commands:

```bash
# clone istio repository
sumo-make istio-clone
# generate istio certs and enable it in mirok8s
sumo-make istio-certs istio-enable
# upgrade sumologic
sumo-make upgrade
# patch sumologic
sumo-make istio-patch restart-pods
```

**NOTE**: In order to prevent overriding patches, please use `sumo-make helm-upgrade` instead of `sumo-make upgrade`

### Configuration

Prepare sumologic configuration (in `vagrant/values.local.yaml`):

- [Adjust kube-prometheus-stack configuration](#adjust-kube-prometheus-stack-configuration)
- [Adjust receiver-mock configuration](#adjust-receiver-mock-configuration)
- [Adjust setup job configuration](#adjust-setup-job-configuration)
- [Adjust fluent-bit configuration](#adjust-fluent-bit-configuration)

And then upgrade the collection with the following command:

```
sumo-make helm-upgrade
```

#### Adjust kube-prometheus-stack configuration

In order to tell kube-prometheus-stack how to scrape metrics, please add the following modifications:

```yaml
kube-prometheus-stack:
  kube-state-metrics:
    podAnnotations:
      # fix readiness and liveness probes
      sidecar.istio.io/rewriteAppHTTPProbers: "true"
      # fix scraping metrics
      traffic.sidecar.istio.io/excludeInboundPorts: "8080"
  grafana:
    podAnnotations:
      # fix readiness and liveness probes
      sidecar.istio.io/rewriteAppHTTPProbers: "true"
      # fix scraping metrics
      traffic.sidecar.istio.io/excludeInboundPorts: "3000"
  prometheusOperator:
    podAnnotations:
      # fix scraping metrics
      traffic.sidecar.istio.io/excludeInboundPorts: "8080"
  prometheus:
    prometheusSpec:
      podMetadata:
        annotations:
          traffic.sidecar.istio.io/includeInboundPorts: ""   # do not intercept any inbound ports
          traffic.sidecar.istio.io/includeOutboundIPRanges: ""  # do not intercept any outbound traffic
          proxy.istio.io/config: |  # configure an env variable `OUTPUT_CERTS` to write certificates to the given folder
            proxyMetadata:
              OUTPUT_CERTS: /etc/istio-output-certs
          sidecar.istio.io/userVolumeMount: '[{"name": "istio-certs", "mountPath": "/etc/istio-output-certs"}]' # mount the shared volume at sidecar proxy
      volumes:
        - emptyDir:
            medium: Memory
          name: istio-certs
      volumeMounts:
        - mountPath: /etc/prom-certs/
          name: istio-certs
    # https://istio.io/latest/docs/ops/integrations/prometheus/#tls-settings
    additionalServiceMonitors:
      - ...
        endpoints:
          - ...
            # https://istio.io/latest/docs/ops/integrations/prometheus/#tls-settings
            scheme: https
            tlsConfig:
              caFile: /etc/prom-certs/root-cert.pem
              certFile: /etc/prom-certs/cert-chain.pem
              keyFile: /etc/prom-certs/key.pem
              insecureSkipVerify: true
```

#### Adjust receiver-mock configuration

Patch for receiver-mock contains two significant changes:

- additional volume `/etc/prom-certs` which allows to mock prometheus behaviour:

  ```bash
  curl -k --key /etc/prom-certs/key.pem --cert /etc/prom-certs/cert-chain.pem https://10.1.126.170:24231/metrics
  ```

- additional service port `3002`, which is not managed by istio, but points to the standard 3000 port. This change is required for setup job
  to work correctly outside of istio

#### Adjust setup job configuration

Setup job disables istio sidecar, as it finish before sidecar is ready which leads to fail. This is done by the following configuration:

```yaml
sumologic:
  setup:
    job:
      podAnnotations:
        # Disable istio sidecar for setup job
        sidecar.istio.io/inject: "false"
  # Use non-istio rport of receiver-mock
  endpoint: http://receiver-mock.receiver-mock:3002/terraform/api/
```

#### Adjust fluent-bit configuration

The following change is required in order to fix fluent-bit's readiness and liveness probes:

```
fluent-bit:
  podAnnotations:
    sidecar.istio.io/rewriteAppHTTPProbers: "true"
```

### Tips and tricks

- In order to manually take fluentd metrics using receiver-mock, use the following command from receiver-mock container:

  ```bash
  export IP_ADDRESS=<fluentd metrics ip>
  export PORT=<Fluentd metrics port>
  curl --http1.1 -k --key /etc/prom-certs/key.pem --cert /etc/prom-certs/cert-chain.pem  https://${IP_ADDRESS}:${PORT}/metrics
  ```
