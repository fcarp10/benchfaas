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

Tester machine: 
- Linux based OS
- Apache JMeter v5.4.3 ([download](https://jmeter.apache.org/download_jmeter.cgi))
- (optional) Local container registry ([instructions](https://docs.docker.com/registry/deploying/))

Cluster of virtual machines (VMs) or physical machines (PMs):
- VMs (Hypervisor):
  - Linux based OS
  - libvirt/KVM ([Ubuntu](https://ubuntu.com/server/docs/virtualization-libvirt) | [Arch Linux](https://wiki.archlinux.org/title/libvirt))
  - Vagrant ([installation](https://learn.hashicorp.com/tutorials/vagrant/getting-started-install?in=vagrant/getting-started))
  - Vagrant plugins ([installation](https://www.vagrantup.com/docs/plugins/usage)), in the following order: 
    - `vagrant-libvirt`
    - `vagrant-hostmanager`
  - netem (`tc`): already included in most Linux distros.
- PMs:
  - x86_64/ARM64 based devices
  - Linux based OS
  - GbE Switch/Router
  - [Nebula](https://github.com/slackhq/nebula)
  
All VMs/PMs need additional internet connection for the deployment of required
tools, but not for the execution of benchmarks.

### User guide

1. Make sure the prerequisites are met on all devices.
2. Create a LAN network by connecting all devices to a switch and configuring
   private static IP addresses. 
3. (optional) Start the local Docker container registry.
4. Clone this repository to the tester machine. 
5. Modify `config.yml` and `testbed_controller.sh` accordingly to your use case.
   - When using VMs, adjust:
      - `devices.hypervisor.address`: Hypervisor's IP
      - `devices.testmachine.vm_interface`: Tester machine interface connecting to the hypervisor.
      - `devices.vm.benchmark_bridge`: Hypervisor's interface to bridge the VMs.
      - `devices.vm.repoip`: IP of the machine with the local container registry. Leave blank when using a public registry.
      - `devices.vm.privaterepo`: Name of the local container registry.
   - When using PMs, adjust:
      - `devices.testmachine.pm_interface`: Name of the interface connected to the PMs.
      - ... TBD
6. VMs (Hypervisor): customize `environment.rb`.
7. PMs: 
   - Make sure DNS resolution is working properly in all PMs.
   - Install and configure Nebula in every PM [instuctions
     here](https://github.com/slackhq/nebula), or run the script
       `deployment_toolkit/nebula.sh` in any PM to install the nebula-cert
       binary. The create key and certificates with: `nebula-cert sign -name
       "worker1" -ip "192.168.50.101/24"`.
8. Run `./testbed_controller.sh` from the tester machine.
