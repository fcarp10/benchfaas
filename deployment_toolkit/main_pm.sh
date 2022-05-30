#$1= number, $2= QOS, $3= device key
source deployment_toolkit/utilities/yaml_parser.sh
source deployment_toolkit/wan_emulation/apply_qos_pm.sh
source deployment_toolkit/wan_emulation/read_qos.sh
source deployment_toolkit/pm/tm_copy_and_install_pm.sh

#echo $(bc -l <<< "scale=2;25/5")
trigger_pm_deployment() {
	NUMBER=$1
	DEVICEKEY=$2
	for (( i=0; i<$NUMBER; i++ ))
	do
		ADDRESS=$(parsecfg devices.$DEVICEKEY.devices.$i.ssh_address)
		K3S_ADDRESS=$(parsecfg devices.$DEVICEKEY.devices.$i.headnode_advert)
		LOGIN=$(parsecfg devices.$DEVICEKEY.devices.$i.login)
		QOSIF=$(parsecfg devices.$DEVICEKEY.devices.$i.qos_interface)
		K3S_VERSION=$(parsecfg software.k3s.version)
		K3S_PORT=$(parsecfg software.k3s.port)
		WORKPATH=$(parsecfg devices.$DEVICEKEY.path)
		trigger_pm_cleanup
		read_qos
		provision_pm_qos
		copy_and_install_pm
		if [ $(parsecfg devices.$DEVICEKEY.devices.$i.lighthouse) == true ]
		then
			echo "detected lighthouse, logging in to $LOGIN@$ADDRESS"
		fi
		if [ $(parsecfg devices.$DEVICEKEY.devices.$i.headnode_advert) != "null" ]
		then
			echo "detected headnode, logging in to $LOGIN@$ADDRESS"
			HEADNODE=$K3S_ADDRESS
			FAAS_IP=$ADDRESS
			FAAS_LOGIN=$LOGIN
			FAAS_IP_INT=$K3S_ADDRESS
			ssh -n $LOGIN@$ADDRESS "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${K3S_VERSION} INSTALL_K3S_EXEC=\"--advertise-address ${K3S_ADDRESS} --flannel-iface nebula --kube-apiserver-arg \"enable-admission-plugins=PodNodeSelector\"\" sh -"
			TOKEN=$(ssh -n $LOGIN@$ADDRESS "sudo cat /var/lib/rancher/k3s/server/node-token")
			((NUMBER++))
		else
			echo "installing worker, logging in to $LOGIN@$ADDRESS with token: $TOKEN"
			ssh -n $LOGIN@$ADDRESS "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${K3S_VERSION} K3S_URL=https://${HEADNODE}:${K3S_PORT} K3S_TOKEN=${TOKEN} INSTALL_K3S_EXEC=\"--flannel-iface nebula --kubelet-arg=system-reserved=memory=800Mi\" sh -"
		fi
	done
	echo -n "Waiting for all nodes to join the cluster"
	ACTIVENODES=1
	until [[ $(($ACTIVENODES-1)) -eq $NUMBER ]]
	do
		ACTIVENODES=$(ssh -n $FAAS_LOGIN@$FAAS_IP "sudo kubectl get nodes | wc -l")
        	echo -n "."
		sleep 1
	done
	echo ""
}

trigger_pm_cleanup() {
	if [[ $(parsecfg devices.$DEVICEKEY.devices.$i.headnode_advert) != "null" ]]
	then
		echo "Cleaning up k3s server from $ADDRESS..."
		ssh -n $LOGIN@$ADDRESS "/usr/local/bin/k3s-uninstall.sh > /dev/null"
	else
		echo "Cleaning up k3s agent from $ADDRESS..."
                ssh -n $LOGIN@$ADDRESS "/usr/local/bin/k3s-agent-uninstall.sh > /dev/null"
	fi
	ssh -n $LOGIN@$ADDRESS "sudo tc qdisc delete dev $(parsecfg devices.$DEVICEKEY.devices.$i.qos_interface) root"
	ssh -n $LOGIN@$ADDRESS "sudo reboot"
	sleep 5
	while ! ssh -n $LOGIN@$ADDRESS "ls > /dev/null"; do sleep 0.5; done
}
