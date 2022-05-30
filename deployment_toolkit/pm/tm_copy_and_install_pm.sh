
copy_and_install_pm() {
	echo "Using scp to copy to $ADDRESS"
	ssh -n $LOGIN@$ADDRESS "mkdir -p ${WORKPATH}benchfaas"
	ssh -n $LOGIN@$ADDRESS "mkdir -p ${WORKPATH}benchfaas/deployment_toolkit/"
	ssh -n $LOGIN@$ADDRESS "mkdir -p ${WORKPATH}benchfaas/deployment_toolkit/pm/"
	for file in $(ls deployment_toolkit/pm/ | grep -E '^pm_')
        do
		scp deployment_toolkit/pm/$file $LOGIN@$ADDRESS:${WORKPATH}benchfaas/deployment_toolkit/pm/ > /dev/null
	done
	scp config.yml $LOGIN@$ADDRESS:${WORKPATH}benchfaas/ > /dev/null
	scp deployment_toolkit/prerequisites.sh $LOGIN@$ADDRESS:${WORKPATH}benchfaas/deployment_toolkit/ > /dev/null
	echo "Copying utilities from `pwd`..."
        scp -r deployment_toolkit/utilities $LOGIN@$ADDRESS:${WORKPATH}benchfaas/deployment_toolkit/ > /dev/null
	ssh -n $LOGIN@$ADDRESS "${WORKPATH}benchfaas/deployment_toolkit/pm/pm_install.sh"
}
