# Vagrant

Please install [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/).
After that you can run the Vagrant environment with just one command:

```bash
vagrant up
```

After successfull installation you can ssh to the virtual machine with:

```bash
vagrant ssh
```

## Collector

To install or upgrade collector please type:

```bash
/sumologic/vagrant/Makefile upgrade
```

This command will prepare environment (namespaces, receiver-mock, etc.)
and after that it will install/upgrade collector in the vagrant environment.

To remove collector please use:

```bash
/sumologic/vagrant/Makefile clean
```

List of other useful commands in the Makefile:
  - `expose-prometheus` - exposes prometheus on port 9090 of virtual machine
  - `expose-grafana` - exposes grafana on port 8080 of virtual machine
  - `apply-avalanche` - run one pod deployment of avalanche (metrics generator)
