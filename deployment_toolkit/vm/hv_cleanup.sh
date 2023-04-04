cd $(dirname $0)
vagrant destroy -f
NUMBER_TOTAL=$(expr $(vagrant status | sed -n '/^Current/,/^This/p' | wc -l) - 4)
NUMBER_STOPPED=0
while [[ $NUMBER_TOTAL -ne $NUMBER_STOPPED ]]
do
    echo "Destroying old machines..."
    for PROC in $(vagrant status | sed -n '/^Current/,/^This/p' | tail -n +3 | head -n -2 | grep -v "not created" | awk '{print $1}')
    do
        kill -9 $(ps aux | grep $PROC | awk '{print $2}')
    done
    killall -9 ruby
    machines=$(vagrant status | grep libvirt | awk '{print $1}')
    for machine in $machines
    do
        virsh undefine vm_$machine
        virsh destroy vm_$machine
    done
    vagrant destroy -f
    NUMBER_TOTAL=$(expr $(vagrant status | sed -n '/^Current/,/^This/p' | wc -l) - 4)
    NUMBER_STOPPED=$(vagrant status | grep "not created" | wc -l)
    sleep 5
done
echo "All machines destroyed, proceeding..."
