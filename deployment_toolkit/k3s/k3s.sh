#Note: if you specify a private registry, you also have to modify the ../yaml/registries.yaml file for k3s to add it as insecure registry

#--------------------------------------------------------------------------#
DEVTYPE=$1
DEVNO=$2
echo "Starting k3s configuration..."
if [ "$DEVTYPE" == "vm" ]
then
    cd "/vagrant/deployment_toolkit"
else
    cd "$(dirname "$0")/../"
fi
TOOLKITPATH=$PWD
source $TOOLKITPATH/utilities/yaml_parser.sh
REPOPORT=$(parsecfg devices.$DEVTYPE.repoport)
REPONAME=$(parsecfg devices.$DEVTYPE.reponame)
DEBUG=$(parsecfg software.debug)
if [[ $REPONAME != "null" && $REPOPORT != "null" ]]
then
    REPOSITORY="${REPONAME}:${REPOPORT}/"
else
    REPOSITORY=""
fi

echo "export TERM=xterm" >> ~/.bashrc

echo "Wrapping up the installation..."
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
    for payload in $(ls $TOOLKITPATH/payload/*.sh)
    do
        source $payload
    done

echo "Summarizing setup:"
sudo -E kubectl -n default get pods --all-namespaces
sudo -E k3s kubectl get nodes
