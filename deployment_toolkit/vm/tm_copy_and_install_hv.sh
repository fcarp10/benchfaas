copy_hv() {
	echo "Using scp to copy to $ADDRESS"
	ssh -n $LOGIN@$ADDRESS "rm -Rf ${WORKPATH}benchfaas/deployment_toolkit/"
	ssh -n $LOGIN@$ADDRESS "mkdir -p ${WORKPATH}benchfaas/"
	ssh -n $LOGIN@$ADDRESS "mkdir -p ${WORKPATH}benchfaas/deployment_toolkit/"
	ssh -n $LOGIN@$ADDRESS "mkdir -p ${WORKPATH}benchfaas/deployment_toolkit/vm/"
	scp -r deployment_toolkit $LOGIN@$ADDRESS:${WORKPATH}benchfaas/ > /dev/null
	scp -r aux $LOGIN@$ADDRESS:${WORKPATH}benchfaas/ > /dev/null
	ssh -n $LOGIN@$ADDRESS "chmod +x ${WORKPATH}benchfaas/deployment_toolkit/vm/deploy_vms.sh > /dev/null"
	scp config.yml $LOGIN@$ADDRESS:${WORKPATH}benchfaas/ > /dev/null
}
