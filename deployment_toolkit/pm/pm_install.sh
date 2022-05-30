cd $(dirname $0)/..
TOOLKITPATH="$(dirname $0)/.."
source ${TOOLKITPATH}/prerequisites.sh
bootstrap
DEVTYPE=pm
source ${TOOLKITPATH}/pm/pm_config.sh

install_repo_resolution
