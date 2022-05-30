TOOLKITPATH=$PWD/deployment_toolkit
source deployment_toolkit/utilities/yaml_parser.sh
source deployment_toolkit/main_vm.sh
source deployment_toolkit/main_pm.sh
source deployment_toolkit/wan_emulation/apply_qos_tm.sh
source deployment_toolkit/pm/tm_copy_and_install_hn.sh

#$1= device type
deploy_and_test() {
	DEVTYPE=$1
	while IFS= read -r item
	do
		SEGS=$(echo $item | grep -o "\." | grep -c "\.")
		if [ $SEGS == 2 ]
		then
			DEVNO=$(echo $item | awk 'BEGIN{FS=".";}{print $1}')
			SIZE=$(echo $item | awk '{print $1}' | awk 'BEGIN{FS=".";}{print $2}')
			QOS=$(echo $item | awk '{print $1}' | awk 'BEGIN{FS=".";}{print $3}')
			trigger_vm_deployment $DEVNO $SIZE
			QOSSIZE=$SIZE.$QOS
		elif [ $SEGS == 1 ]
		then
			DEVNO=$(echo $item | awk 'BEGIN{FS=".";}{print $1}')
			SIZE="metal"
			QOS=$(echo $item | awk '{print $1}' | awk 'BEGIN{FS=".";}{print $2}')
			trigger_pm_deployment $DEVNO $DEVTYPE
			copy_and_install_hn
			QOSSIZE=$QOS
		fi
		apply_latency

		echo "Reading tests in config file at benchmark.tests_to_execute.$DEVTYPE.$DEVNO.$QOSSIZE"
		for test in $(parsecfg benchmark.tests_to_execute.$DEVTYPE.$DEVNO.$QOSSIZE)
		do
			tm_execute_tests $test
		done
	done <<< $(parsecfg benchmark.tests_to_execute.$DEVTYPE "-o props")
}

tm_execute_tests() {
    TESTNUMBER=$1
    RESULTS=$(parsecfg devices.testmachine.resultspath)
    TESTPORT=$(parsecfg devices.$DEVTYPE.openfaas.port)
    #for CURRENTTEST in $(find test_scheduler/performance-tests/ -name "*.jmx" | grep -G $TESTNUMBER)
    TEST_TO_EX=$(find test_scheduler/performance-tests/ -name "*.jmx" | cut -d'/' -f3- | grep -e "^$TESTNUMBER-")
    echo "Found matches for $TESTNUMBER: $TEST_TO_EX"
    for CURRENTTEST in $TEST_TO_EX
    do
        echo "Executing test: $CURRENTTEST using parameters $(parsecfg benchmark.parameters.${TESTNUMBER})"
        for TESTPARAMETER in $(parsecfg benchmark.parameters.${TESTNUMBER})
        do
            echo "executing $CURRENTTEST against $FAAS_IP:$TESTPORT with parameter $TESTPARAMETER while saving to ${RESULTS}${TIMESTAMP}/$(echo $CURRENTTEST | xargs basename | sed 's/\.jmx *$//')_"$TESTPARAMETER"_"$DEVNO""$DEVTYPE"."$SIZE"."$QOS"_"$TIMESTAMP".csv"
            jmeter -n -t test_scheduler/performance-tests/$CURRENTTEST -Jrequest.ip=$FAAS_IP -Jrequest.port=$TESTPORT -Jtest.iterations=100 -Jtest.opt=$TESTPARAMETER -Jrequest.fsurl="http://$FAAS_IP_INT:$TESTPORT/function/payload-echo-workflow" -l ${RESULTS}${TIMESTAMP}/$(echo $CURRENTTEST | xargs basename | sed 's/\.jmx *$//')_"$TESTPARAMETER"_"$DEVNO""$DEVTYPE"."$SIZE"."$QOS"_"$TIMESTAMP".csv
        done
    done
}
