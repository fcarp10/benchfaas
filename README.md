# BenchFaaS

This repository contains the scripts for the automated deployment of BenchFaaS.

## Performance tests

Five performance tests are defined using JMeter in
`test_scheduler/performance_tests` directory:

1. Overhead: `hello-world` function
2. Payload size: `payload-echo` function
3. Intensive: `img-classifier-hub` function
4. Scalability: `fib-go` function
5. Chains: `payload-echo-workflow` function

Serverless functions used for the benchmarks can be found
[here](https://github.com/fcarp10/openfaas-functions).

## Deployment

### Prerequisites

#### Tester machine

- Linux based OS
- Apache JMeter v5.4.3
  ([download](https://jmeter.apache.org/download_jmeter.cgi))
- K6 v0.39.0
  ([download](https://k6.io/docs/getting-started/installation/))
- (Optional) Local container registry
  ([instructions](https://docs.docker.com/registry/deploying/))

#### Cluster of virtual machines (VMs) or physical machines (PMs)

- VMs (Hypervisor):
  - Linux based OS
  - libvirt/KVM ([Ubuntu](https://ubuntu.com/server/docs/virtualization-libvirt)
    | [Arch Linux](https://wiki.archlinux.org/title/libvirt))
  - Vagrant
    ([installation](https://learn.hashicorp.com/tutorials/vagrant/getting-started-install?in=vagrant/getting-started))
    - Configure password-less sudo for NFS as explained
      [here](https://www.vagrantup.com/docs/synced-folders/nfs#root-privilege-requirement).
  - Vagrant plugins
    ([installation](https://www.vagrantup.com/docs/plugins/usage)): 
    - `vagrant-libvirt`
    - `vagrant-hostmanager`
  - netem (`tc`): already included in most Linux distros.
- PMs:
  - x86_64/ARM64 based devices
  - Linux based OS
  - GbE Switch/Router
  - Nebula ([installation](https://github.com/slackhq/nebula))

For the instructions, it is assumed that all VMs/PMs are on the same LAN network
with static IP addresses. However, by using Nebula the testbed also works with
devices located in different networks even behind NATs or Firewalls. 

All VMs/PMs need additional internet connection for the deployment of required
tools, but not for the execution of benchmarks.

The public SSH key from the tester machine needs to be added to the Hypervisor
and to all PMs.


### User guide

1. Clone this repository to the tester machine. 
2. Modify `config.yml` and `testbed_controller.sh` accordingly to your use case.
   - When using VMs, adjust:
     - `devices.hypervisor.address`: Hypervisor's IP.
     - `devices.hypervisor.login`: Username of the hypervisor.
     - `devices.testmachine.vm_interface`: Tester machine interface connecting
       to the hypervisor.
     - `devices.testmachine.path`: Full path of the locally cloned repo
     - `devices.vm.benchmark_bridge`: Hypervisor's interface to bridge the VMs.
     - `devices.vm.benchmark_ip`: IP that will be reachable from the interface you specified above (e.g. 192.168.1.11 if your testmachine has 192.168.1.10 on that interface)
   - When using PMs, adjust:
      - `devices.testmachine.pm_interface`: Name of the interface connected to
        the PMs.
      - `devices.pm.lighthouse.address` and `devices.pm.lighthouse.port`:
        Nebula's address and port.
      - `devices.pm.devices`: Set of PMs for the testbed. 
        - `ssh_address`: Specific IP address of the PM.
        - `login`: Username for SSH.
        - `qos_interface`: Network interface of the PM to apply WAN emulation.
        - `lighthouse`: True, if the machine is a lighthouse.
    - (Optional) In both cases, local container registry, leave blank when using the default
       public registry specified on the `yaml` files:
       - `*.repoip`: IP of the machine with the local container
         registry.
       - `*.repoport`: port of the machine with the local container
         registry.
       - `*.privaterepo`: Name of the local container registry.
3. On the hypervisor, ensure passwordless sudo permission for your user by adding the following section to the bottom of your sudoers file via `sudo visudo` (note: the user you provided has to be member of the group "sudo" listed in the last statement):
```
# Allow passwordless startup of Vagrant with NFS synced folder option.
Cmnd_Alias VAGRANT_EXPORTS_UPDATE = /usr/bin/chown 0\:0 /tmp/*, /usr/bin/mv -f /tmp/* /etc/exports
Cmnd_Alias VAGRANT_EXPORTS_ADD = /usr/bin/tee -a /etc/exports
Cmnd_Alias VAGRANT_NFSD_CHECK = /usr/bin/systemctl status nfs-server.service, /usr/sbin/systemctl status nfs-server.service
Cmnd_Alias VAGRANT_NFSD_START = /usr/bin/systemctl start nfs-server.service, /usr/sbin/systemctl start nfs-server.service
Cmnd_Alias VAGRANT_NFSD_APPLY = /usr/bin/exportfs -ar, /usr/sbin/exportfs -ar
Cmnd_Alias VAGRANT_EXPORTS_REMOVE = /bin/sed -r -e * d -ibak /tmp/exports, /usr/bin/cp /tmp/exports /etc/exports
Cmnd_Alias LIBVIRT_MANAGE = /usr/bin/virsh /bin/virsh
%sudo ALL=(root) NOPASSWD: VAGRANT_EXPORTS_UPDATE, VAGRANT_EXPORTS_ADD, VAGRANT_NFSD_CHECK, VAGRANT_NFSD_START, VAGRANT_NFSD_APPLY, VAGRANT_EXPORTS_REMOVE, LIBVIRT_MANAGE
```
4. Add the SSH key of your testmachine's user to the allowed hosts files on all machines you wish to benchmark so that you have passwordless access
5. Run `./testbed_controller.sh` from the tester machine.

### Troubleshooting

If you get the following error when deploying VMs using `qemu-kvm`: 

```
Error while creating domain: Error saving the server: Call to virDomainDefineXML failed: invalid argument: could not get preferred machine for /usr/bin/qemu-system-x86_64 type=kvm
```

Check the solution from [here](https://serverfault.com/questions/1002043/libvirt-has-no-kvm-capabilities-even-though-qemu-kvm-works/1002063#1002063).


If you get the following error when deploying VMs using `qemu-kvm` on Ubuntu:

```
Error while creating domain: Error saving the server: Call to virDomainDefineXML failed: Cannot check QEMU binary /usr/libexec/qemu-kvm: No such file or directory
```

Check the solution from [here](https://github.com/kubevirt/kubevirt/issues/4303)

If you forgot to modify your sudoers file, ran the script and your user's sudo password is not accepted anymore, the reason are likely too many failed password attempts. You can usually reset the counter like this:
```
faillock --user $USER --reset
```
