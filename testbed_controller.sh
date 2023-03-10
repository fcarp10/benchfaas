TIMESTAMP=$(date +%m%d-%H%M)
TOOLKITPATH="$PWD/deployment_toolkit"

source test_scheduler/test_scheduler.sh
source deployment_toolkit/prerequisites.sh

bootstrap
deploy_and_test vm
trigger_vm_cleanup
deploy_and_test pm
