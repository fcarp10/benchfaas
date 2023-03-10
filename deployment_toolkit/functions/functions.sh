deploy_functions() {
for funct in $(parsecfg software.openfaas.functions)
do
	echo "Deploying $funct from ${REPOSITORY}$(cat $TOOLKITPATH/functions/${funct}.yml | grep image | awk '{print $2}')"
	sudo -E faas-cli deploy --image=${REPOSITORY}/$(cat $TOOLKITPATH/functions/${funct}.yml | grep image | awk '{print $2}') -f $TOOLKITPATH/functions/${funct}.yml
        sleep 2
        if [ -f $TOOLKITPATH/functions/${funct}-hpa.yml ]
        then
                sudo -E kubectl apply -f $TOOLKITPATH/functions/${funct}-hpa.yml
		if [ $? -ne 0 ]; then echo "There was an error while deploying $funct. Aborting..." \
		&& exit 2; fi
                sleep 2
        fi
done
}
check_function_readiness() {
for funct in $(parsecfg software.openfaas.functions)
do
	echo "Waiting for function $funct to deploy successfully..."
	sudo -E kubectl -n openfaas-fn rollout status deploy/$funct --timeout=600s
	if [ $? -ne 0 ]; then echo "The function $funct timed out, continuing anyway but this might cause problems with the tests..."; fi
done
}
