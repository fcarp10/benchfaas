source deployment_toolkit/utilities/yaml_parser.sh

configure_vms() {
	SCRIPTPATH=$(dirname $0)/deployment_toolkit/vm
	echo "Configuring virtual machines at $SCRIPTPATH..."
	cp $SCRIPTPATH/environment.rb $SCRIPTPATH/environment.transfer
	MEMORY=$(parsecfg devices.$DEVTYPE.machines.$SIZE.memory)
	CPU=$(parsecfg devices.$DEVTYPE.machines.$SIZE.cpus)
	BRIDGEIF=$(parsecfg devices.$DEVTYPE.benchmark_bridge)
	BRIDGEIP=$(parsecfg devices.$DEVTYPE.benchmark_ip)
	VMIMAGE=$(parsecfg devices.$DEVTYPE.image)
	NEBULAVER=$(parsecfg software.nebula.version)
	K3SVER=$(parsecfg software.k3s.version)
	echo "Writing settings: mem: $MEMORY, cpu: $CPU, bridge: $BRIDGEIF, vm image: $VMIMAGE"

	sed -i "s/NEBULAVERSION =.*/NEBULAVERSION = \"$NEBULAVER\"/g" $SCRIPTPATH/environment.transfer
	sed -i "s/K3SVERSION =.*/K3SVERSION = \"$K3SVER\"/g" $SCRIPTPATH/environment.transfer
	sed -i "s@VMIMAGE =.*@VMIMAGE = \"${VMIMAGE}\"@g" $SCRIPTPATH/environment.transfer
	sed -i "s/BRIDGE_BENCH =.*/BRIDGE_BENCH = \"$BRIDGEIF\"/g" $SCRIPTPATH/environment.transfer
	sed -i "s/BRIDGE_IP =.*/BRIDGE_IP = \"$BRIDGEIP\"/g" $SCRIPTPATH/environment.transfer
	sed -i "s/VMMEM =.*/VMMEM = \"$MEMORY\"/g" $SCRIPTPATH/environment.transfer
        sed -i "s/VMCPU =.*/VMCPU = \"$CPU\"/g" $SCRIPTPATH/environment.transfer
        sed -i "s/NODE_COUNT =.*/NODE_COUNT = $NUMBER/g" $SCRIPTPATH/environment.transfer
        sed -i "s/TOTAL_DELAY =.*/TOTAL_DELAY = $DELAY/g" $SCRIPTPATH/environment.transfer
        sed -i "s/DELAY_VAR =.*/DELAY_VAR = $VARIANCE/g" $SCRIPTPATH/environment.transfer
        sed -i "s/PACKET_LOSS =.*/PACKET_LOSS = $LOSS/g" $SCRIPTPATH/environment.transfer
	scp $SCRIPTPATH/environment.transfer $LOGIN@$ADDRESS:${WORKPATH}benchfaas/deployment_toolkit/vm/environment.rb > /dev/null
	rm $SCRIPTPATH/environment.transfer
}
