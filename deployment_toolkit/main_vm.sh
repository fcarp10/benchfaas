#$1= number, $2= size
source deployment_toolkit/vm/tm_copy_and_install_hv.sh
source deployment_toolkit/vm/tm_vm_config.sh
source deployment_toolkit/wan_emulation/read_qos.sh

trigger_vm_deployment() {
	echo "Triggering deployment of $1 VM(s) of config $2"
	NUMBER=$1
        SIZE=$2
	ADDRESS=$(parsecfg devices.hypervisor.address)
	LOGIN=$(parsecfg devices.hypervisor.login)
	WORKPATH=$(parsecfg devices.hypervisor.path)
	echo "Installing to hypervisor $ADDRESS"
	FAAS_IP=$(parsecfg devices.vm.benchmark_ip)
	read_qos
        trigger_vm_cleanup
	copy_hv
	configure_vms
	ssh -n ${LOGIN}@${ADDRESS} "${WORKPATH}benchfaas/deployment_toolkit/vm/deploy_vms.sh"
	FAAS_IP_INT=$(ssh -n $LOGIN@$ADDRESS "cd ${WORKPATH}benchfaas/deployment_toolkit/vm/ && vagrant ssh -c \"ip addr sh nebula\"" | grep 'inet ' | awk '{print substr($2, 1, length($2)-3)}')
	echo "trigger_vm_deployment $NUMBER $SIZE $QOS"
}

trigger_vm_cleanup() {
	echo "Cleaning up old instances..."
	scp deployment_toolkit/vm/hv_cleanup.sh ${LOGIN}@${ADDRESS}:${WORKPATH}benchfaas/deployment_toolkit/vm/
	ssh -n ${LOGIN}@${ADDRESS} "chmod +x ${WORKPATH}benchfaas/deployment_toolkit/vm/hv_cleanup.sh"
	ssh -n ${LOGIN}@${ADDRESS} "${WORKPATH}benchfaas/deployment_toolkit/vm/hv_cleanup.sh"
	ssh -n ${LOGIN}@${ADDRESS} "rm -Rf ${HYPERVISOR_PATH}"
}

