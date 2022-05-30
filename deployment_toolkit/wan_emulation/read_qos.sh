read_qos() {
	TM_DELAY=$(parsecfg qos.$QOS.testmachine.delay)
	TM_VARIANCE=$(parsecfg qos.$QOS.testmachine.variance)
	TM_LOSS=$(parsecfg qos.$QOS.testmachine.packet_loss)
	TM_DEVICE=$(parsecfg devices.testmachine.pm_interface)
	DELAY=$(parsecfg qos.$QOS.intra.delay)
	VARIANCE=$(parsecfg qos.$QOS.intra.variance)
	LOSS=$(parsecfg qos.$QOS.intra.packet_loss)
}
