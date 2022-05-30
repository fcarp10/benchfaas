source deployment_toolkit/utilities/yaml_parser.sh

apply_latency() {
	TM_DELAY=$(parsecfg qos.$QOS.testmachine.delay)
	TM_VARIANCE=$(parsecfg qos.$QOS.testmachine.variance)
	TM_LOSS=$(parsecfg qos.$QOS.testmachine.packet_loss)
	TM_DEVICE=$(parsecfg devices.testmachine.${DEVTYPE}_interface)
	sudo tc qdisc delete dev $TM_DEVICE root

	if [[ "$TM_DELAY" != "null" && "$TM_DELAY" != 0 && "$TM_VARIANCE" != "null" && "$TM_VARIANCE" != 0 && "$TM_LOSS" != "null" && "$TM_LOSS" != 0 && "$TM_DEVICE" != "null" ]]
	then
		echo "Applying $QOS latency..."
		sudo tc qdisc add dev $TM_DEVICE root netem delay ${TM_DELAY}ms ${TM_VARIANCE}ms distribution normal loss ${TM_LOSS}%
	else
		echo "No latency to apply to testmachine for profile $QOS"
		echo "del: $TM_DELAY | var: $TM_VARIANCE | loss: $TM_LOSS | dev: $TM_DEVICE"
	fi
}
