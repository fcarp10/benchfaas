#Note: if you specify a private registry, you also have to modify the ../yaml/registries.yaml file for k3s to add it as insecure registry

#--------------------------------------------------------------------------#
DEVTYPE=$1

if [ $DEVTYPE = "vm" ]
then
    cd "/vagrant/deployment_toolkit"
else
    cd "$(dirname "$0")/../"
fi
TOOLKITPATH=$PWD
source $TOOLKITPATH/utilities/yaml_parser.sh
source $TOOLKITPATH/functions/functions.sh
REPONAME=$(parsecfg devices.$DEVTYPE.reponame)
REPOPORT=$(parsecfg devices.$DEVTYPE.repoport)
DEBUG=$(parsecfg software.debug)
if [[ $REPONAME != "null" && $REPOPORT != "null" ]]
then
    REPOSITORY="${REPONAME}:${REPOPORT}/"
else
    REPOSITORY=""
fi
FAASPORT=$(parsecfg devices.$DEVTYPE.openfaas.port)
OF_VERSION=$(parsecfg software.openfaas.version)
FUNCTION_NAMESPACE=$(parsecfg software.openfaas.function-namespace)

echo "export TERM=xterm" >> ~/.bashrc

    echo "Wrapping up the installation..."
    echo "Installing faas-cli"
    curl -sL https://cli.openfaas.com | sudo -E sh
    while [ $? -ne 0 ]; do curl -sL https://cli.openfaas.com | sudo -E sh; done
    echo "Deploying openfaas"
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/`whoami`/.bashrc
    WORKERNUMBER=0
    for worker in $(sudo -E kubectl get nodes | grep -v $HOSTNAME | grep -v NAME \
        | sed 's/\s.*$//')
    do
        sudo -E kubectl label node $worker node-role.kubernetes.io/worker=worker
        WORKERNUMBER=$((WORKERNUMBER+1))
    done
    sudo -E kubectl label node $HOSTNAME env=ingress
    curl -sSLf https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
        | bash
    sudo -E kubectl apply -f $PWD/openfaas/namespaces.yml
    #Apply the changed defaults to openfaas namespace (and thus to all core components)
    sudo -E kubectl apply -f $PWD/k3s/memory-defaults.yaml --namespace=openfaas
    #Apply the changed defaults to function namespace (and thus to all deployed containers)
    sudo -E kubectl apply -f $PWD/k3s/memory-defaults.yaml --namespace=$FUNCTION_NAMESPACE

    if [ "$DEBUG" = 'true' ]; then
	    echo "Adding Grafana..."
	    sudo -E helm repo add grafana https://grafana.github.io/helm-charts
	    sudo -E helm repo update
	    sudo -E helm upgrade grafana -n openfaas --install grafana/grafana --version 6.18.0 -f $PWD/utilities/debug/grafana.yml
	    sudo -E kubectl -n openfaas apply -f $PWD/utilities/debug/grafana-db-map.yml
    fi

    echo "Adding OpenFaaS..."
    sudo -E helm repo add openfaas https://openfaas.github.io/faas-netes/
    sudo -E helm repo update
    sleep 2
    sudo -E kubectl -n openfaas create secret generic basic-auth \
        --from-literal=basic-auth-user=admin \
        --from-literal=basic-auth-password=password
    sleep 5
    TIMEOUT=2m
    sudo -E helm upgrade openfaas --install openfaas/openfaas --namespace openfaas \
        --set functionNamespace=$FUNCTION_NAMESPACE --set basic_auth=true \
        --set gateway.directFunctions=false \
        --set gateway.upstreamTimeout=$TIMEOUT \
        --set gateway.writeTimeout=$TIMEOUT \
        --set gateway.readTimeout=$TIMEOUT \
        --set faasnetes.writeTimeout=$TIMEOUT \
        --set faasnetes.readTimeout=$TIMEOUT \
        --set queueWorker.ackWait=$TIMEOUT \
        --set faasnetes.image=${REPOSITORY}michalkeit/faas-netes:0.13.2 \
	--set nats.image=${REPOSITORY}nats-streaming:0.22.0 \
	--set queueWorker.image=${REPOSITORY}ghcr.io/openfaas/queue-worker:0.12.2 \
        --set prometheus.image=${REPOSITORY}prom/prometheus:v2.11.0 \
        --set basicAuthPlugin.image=${REPOSITORY}ghcr.io/openfaas/basic-auth:0.21.1 \
	--version $OF_VERSION
    if [ $? -ne 0 ]; then echo "There was an error while deploying OpenFaaS. Aborting..." \
        && exit 1; fi
    sleep 120
    if [ "$DEBUG" = 'true' ]; then
    	sudo -E kubectl -n openfaas rollout status -w deployment/grafana
    	sudo -E kubectl -n openfaas exec -ti deployment/grafana -c grafana -- grafana-cli admin reset-admin-password password
    fi
    sudo -E kubectl -n openfaas rollout status -w deployment/gateway
    sudo -E kubectl autoscale deployment -n openfaas gateway --min=1 --max=1

    echo "Testing OpenFaaS..."
    sudo -E kubectl -n openfaas get deployments -l "release=openfaas, app=openfaas"
    FAASPORT=$(sudo -E kubectl get service gateway-external -n openfaas \
        | grep -oP '(?<=8080:).*(?=/TCP)')
    export OPENFAAS_URL=http://127.0.0.1:$FAASPORT
    echo "export OPENFAAS_URL=http://127.0.0.1:$FAASPORT" >> /home/`whoami`/.bashrc
    sudo -E faas-cli login --username admin --password password

    # Configuring metrics
    sudo -E helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    sudo -E helm repo update
    sudo -E helm install metrics-prometheus prometheus-community/prometheus-adapter --namespace openfaas --set image.repository=${REPOSITORY}directxman12/k8s-prometheus-adapter -f $PWD/utilities/debug/prometheus.yaml

    echo "Deploying benchmarking functions..."
    sudo -E kubectl scale -n openfaas deploy/alertmanager --replicas=0
    sleep 2
    deploy_functions
    sleep 5
    check_function_readiness

    echo "Summarizing setup:"
    sudo -E kubectl -n default get pods --all-namespaces
    sudo -E k3s kubectl get nodes
