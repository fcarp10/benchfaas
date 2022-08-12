cd $(dirname $0)
NUMBER_TOTAL=$(expr $(vagrant status | sed -n '/^Current/,/^This/p' | wc -l) - 4)
NUMBER_STOPPED=$(vagrant status | grep "not created" | wc -l)
TRIES=0
while [[ $NUMBER_TOTAL -ne $NUMBER_STOPPED ]]
do
    echo "VMs not destroyed ($NUMBER_TOTAL != $NUMBER_STOPPED), trying another time ($TRIES)"
    if [ $TRIES -gt 4 ]
    then
	    echo "seems like the VM(s) $(vagrant status | grep -v "not created") is frozen, trying to kill it/them..."
        for PROC in $(vagrant status | sed -n '/^Current/,/^This/p' | tail -n +3 | head -n -2 | grep -v "not created" | awk '{print $1}')
        do
            sudo kill -9 $(ps aux | grep $PROC | awk '{print $2}')
        done
        TRIES=0
    else
        ((TRIES++))
    fi
    echo "Destroying old machines..."
    machines=$(vagrant status | grep libvirt | awk '{print $1}')
    for machine in $machines
    do
        sudo virsh undefine vm_$machine
    done
    vagrant destroy -f
    NUMBER_TOTAL=$(expr $(vagrant status | sed -n '/^Current/,/^This/p' | wc -l) - 4)
    NUMBER_STOPPED=$(vagrant status | grep "not created" | wc -l)
    sleep 5
done
echo "All machines destroyed, proceeding..."
