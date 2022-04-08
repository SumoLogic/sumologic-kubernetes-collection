# Vagrant

## Prerequisites

Please install the following:

- [VirtualBox](https://www.oracle.com/virtualization/technologies/vm/downloads/virtualbox-downloads.html)
- [Vagrant](https://www.vagrantup.com/)
- [vagrant-disksize](https://github.com/sprotheroe/vagrant-disksize) plugin

### MacOS

```bash
brew cask install virtualbox
brew cask install vagrant
vagrant plugin install vagrant-disksize
```

## Setting up

You can set up the Vagrant environment with just one command:

```bash
vagrant up
```

If you experience following error (MacOS specific) 

```
There was an error while executing `VBoxManage`, a CLI used by Vagrant
for controlling VirtualBox. The command and stderr is shown below.

Command: ["hostonlyif", "create"]

Stderr: 0%...
Progress state: NS_ERROR_FAILURE
VBoxManage: error: Failed to create the host-only adapter
VBoxManage: error: VBoxNetAdpCtl: Error while adding new interface: failed to open /dev/vboxnetctl: No such file or directory
VBoxManage: error: Details: code NS_ERROR_FAILURE (0x80004005), component HostNetworkInterfaceWrap, interface IHostNetworkInterface
VBoxManage: error: Context: "RTEXITCODE handleCreate(HandlerArg *)" at line 95 of file VBoxManageHostonly.cpp```
```

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

This command will prepare environment (namespaces, receiver-mock, etc.)
and after that it will install/upgrade collector in the vagrant environment.

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
