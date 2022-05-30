copy_hv() {
	echo "Using scp to copy to $ADDRESS"
	ssh -n $LOGIN@$ADDRESS "rm -Rf ${WORKPATH}benchfaas/deployment_toolkit/"
	ssh -n $LOGIN@$ADDRESS "mkdir -p ${WORKPATH}benchfaas/"
	ssh -n $LOGIN@$ADDRESS "mkdir -p ${WORKPATH}benchfaas/deployment_toolkit/"
	ssh -n $LOGIN@$ADDRESS "mkdir -p ${WORKPATH}benchfaas/deployment_toolkit/vm/"
	scp deployment_toolkit/vm/vm_repocfg.sh $LOGIN@$ADDRESS:${WORKPATH}benchfaas/deployment_toolkit/vm/ > /dev/null
	scp -r deployment_toolkit/nebula $LOGIN@$ADDRESS:${WORKPATH}benchfaas/deployment_toolkit/ > /dev/null
	scp -r deployment_toolkit/k3s $LOGIN@$ADDRESS:${WORKPATH}benchfaas/deployment_toolkit/ > /dev/null
	scp -r deployment_toolkit/functions $LOGIN@$ADDRESS:${WORKPATH}benchfaas/deployment_toolkit/ > /dev/null
	scp -r deployment_toolkit/openfaas $LOGIN@$ADDRESS:${WORKPATH}benchfaas/deployment_toolkit/ > /dev/null
	scp -r aux $LOGIN@$ADDRESS:${WORKPATH}benchfaas/ > /dev/null
	scp deployment_toolkit/vm/Vagrantfile $LOGIN@$ADDRESS:${WORKPATH}benchfaas/deployment_toolkit/vm/ > /dev/null
	scp deployment_toolkit/vm/environment.rb $LOGIN@$ADDRESS:${WORKPATH}benchfaas/deployment_toolkit/vm/ > /dev/null
	scp deployment_toolkit/vm/deploy_vms.sh $LOGIN@$ADDRESS:${WORKPATH}benchfaas/deployment_toolkit/vm/ > /dev/null
	ssh -n $LOGIN@$ADDRESS "chmod +x ${WORKPATH}benchfaas/deployment_toolkit/vm/deploy_vms.sh > /dev/null"
	scp config.yml $LOGIN@$ADDRESS:${WORKPATH}benchfaas/ > /dev/null


	scp deployment_toolkit/prerequisites.sh $LOGIN@$ADDRESS:${WORKPATH}benchfaas/deployment_toolkit/ > /dev/null
	echo "Copying utilities from `pwd`..."
        scp -r deployment_toolkit/utilities $LOGIN@$ADDRESS:${WORKPATH}benchfaas/deployment_toolkit/ > /dev/null
}
