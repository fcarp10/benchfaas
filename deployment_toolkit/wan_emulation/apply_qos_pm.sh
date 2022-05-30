provision_pm_qos() {
	if [[ "$DELAY" != "null" && "$DELAY" != 0 && "$VARIANCE" != "null" && "$VARIANCE" != 0 && "$LOSS" != "null" && "$LOSS" != 0 && "$QOSIF" != "null" ]]
        then
		echo "Applying $QOS latency (${DELAY}ms ${VARIANCE}ms ${LOSS}%) to $ADDRESS"
		ssh -n $LOGIN@$ADDRESS "sudo tc qdisc add dev $QOSIF root netem delay ${DELAY}ms ${VARIANCE}ms distribution normal loss ${LOSS}%"
	else
		echo "no need for modification: $QOS"
	fi
}
