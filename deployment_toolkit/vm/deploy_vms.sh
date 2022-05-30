#!/bin/bash

cd $(dirname $0)
sleep 10
killall -9 ruby-2.7
killall -9 vagrant
vagrant destroy -f
sleep 10
echo "Trying to create the headnode and lighthouse..."
[ 1 -eq 2 ]
while [ $? -ne 0 ]; do sleep 10 && vagrant destroy -f lighthouse headnode && sleep 10 && vagrant up lighthouse headnode; done
sleep 10
vagrant ssh -c "sudo -E kubectl get nodes"
echo "currently configured default routes:"
vagrant ssh -c "ip route sh | grep default"
echo "Trying to create the workers..."
[ 1 -eq 2 ]
while [ $? -ne 0 ]; do sleep 10 && vagrant destroy -f /worker[0-9]/ && sleep 10 && vagrant up /worker[0-9]/; done
sleep 15
echo -n "Waiting for all nodes to join the cluster"
ACTIVENODES=1
until [[ $(($ACTIVENODES-1)) -eq $DEVNO ]]
do
	ACTIVENODES=$(vagrant ssh -c "sudo kubectl get nodes | wc -l")
	echo -n "."
	sleep 1
done
echo "Found $ACTIVENODES of $(($DEVNO+1)) expected"
vagrant ssh -c "sudo kubectl get nodes"
echo "All nodes joined, installing providers..."
vagrant ssh -c "/vagrant/deployment_toolkit/k3s/k3s_openfaas.sh vm"
if [ $? -ne 0 ]; then echo "There was an error while installing a node. Aborting..." \
	&& exit 1; fi
