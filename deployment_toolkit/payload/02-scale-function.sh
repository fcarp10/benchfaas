DEPLOYMENT=$(sudo -E kubectl -n openfaas-fn get deployments -o name --no-headers=true | grep fakenews)
REPSET=$(sudo -E kubectl -n openfaas-fn get replicasets -o name --no-headers=true | grep fakenews)
echo "Patching deployment $DEPLOYMENT to uniquely scale over [$DEVNO] devices..."
sudo -E kubectl -n openfaas-fn patch $DEPLOYMENT -p "$(cat "$TOOLKITPATH/functions/fakenews-patch-deployment.yaml" | sed "s@3@$DEVNO@g")"
sleep 2
echo "Deleting $REPSET ..."
sudo -E kubectl -n openfaas-fn delete $REPSET
sleep 30
check_function_readiness
sudo -E kubectl get pods -n openfaas-fn
