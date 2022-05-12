# BenchFaaS

Serverless functions used for the benchmarks can be found
[here](https://github.com/fcarp10/openfaas-functions).


## Structure

- root: main testbed controller script and config file.
- test_scheduler/: script to run the performance tests and the JMeter files. 
- deployment_toolkit/: deployment scripts and config files.


## Prerequisites

Tester machine: 
- Linux based OS
- [Apache JMeter v5.4.3](https://jmeter.apache.org/)
- (optional) Local container registry (instructions
  [here](https://docs.docker.com/registry/deploying/))

Cluster of virtual machines (VMs) or physical machines (PMs):
- VMs (Hypervisor):
  - Linux based OS
  - [libvirt/KVM]()
  - [Vagrant]()
  - Vagrant plugins: `vagrant-hostmanager`, `vagrant-libvirt`
  - netem (`tc`): already included in most Linux distros.
- PMs:
  - x86_64/ARM64 based devices
  - Linux based OS
  - GbE Switch/Router
  - [Nebula](https://github.com/slackhq/nebula)
  
All VMs/PMs need additional internet connection for the deployment of required
tools, but not for the execution of benchmarks.

## User guide

1. Make sure the prerequisites are met on all devices.
2. Create a LAN network by connecting all devices to a switch and configuring
   private static IP addresses. 
3. Clone this repository to the tester machine. 
4. Modify `testbed_controller.sh` accordingly to your use case.
5. (optional) Start the local Docker container registry.
6. VMs (Hypervisor): customize `environment.rb`.
7. PMs: 
   - Make sure DNS resolution is working properly in all PMs.
   - Install and configure Nebula in every PM [instuctions
     here](https://github.com/slackhq/nebula), or run the script
       `deployment_toolkit/nebula.sh` in any PM to install the nebula-cert
       binary. The create key and certificates with: `nebula-cert sign -name
       "worker1" -ip "192.168.50.101/24"`.
8. Run `./testbed_controller.sh` from the tester machine.
