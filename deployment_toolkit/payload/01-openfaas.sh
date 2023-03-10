source $TOOLKITPATH/functions/functions.sh

FAASPORT=$(parsecfg devices.$DEVTYPE.openfaas.port)
OF_VERSION=$(parsecfg software.openfaas.version)
FUNCTION_NAMESPACE=$(parsecfg software.openfaas.function-namespace)

echo "Installing faas-cli"
curl -sL https://cli.openfaas.com | sudo -E sh
while [ $? -ne 0 ]; do curl -sL https://cli.openfaas.com | sudo -E sh; done
echo "Deploying openfaas"
sudo -E kubectl apply -f $TOOLKITPATH/openfaas/namespaces.yml
sudo -E kubectl apply -f $TOOLKITPATH/openfaas/memory-defaults.yaml --namespace=openfaas
sudo -E kubectl apply -f $TOOLKITPATH/openfaas/memory-defaults.yaml --namespace=$FUNCTION_NAMESPACE

echo "Adding OpenFaaS..."
sudo -E helm repo add openfaas https://openfaas.github.io/faas-netes/
sudo -E helm repo update
sleep 2
sudo -E kubectl -n openfaas create secret generic basic-auth \
    --from-literal=basic-auth-user=admin \
    --from-literal=basic-auth-password=password
sleep 5
TIMEOUT=5m
sudo -E helm upgrade openfaas --install openfaas/openfaas --namespace openfaas \
    --set functionNamespace=$FUNCTION_NAMESPACE --set basic_auth=true \
    --set gateway.directFunctions=false \
    --set gateway.upstreamTimeout=$TIMEOUT \
    --set gateway.writeTimeout=$TIMEOUT \
    --set gateway.readTimeout=$TIMEOUT \
    --set gateway.nodePort=$FAASPORT \
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
sudo -E kubectl -n openfaas rollout status -w deployment/gateway
sudo -E kubectl autoscale deployment -n openfaas gateway --min=1 --max=1

echo "Testing OpenFaaS..."
sudo -E kubectl -n openfaas get deployments -l "release=openfaas, app=openfaas"
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
