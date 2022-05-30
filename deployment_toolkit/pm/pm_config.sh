source $TOOLKITPATH/utilities/yaml_parser.sh
REPONAME=$(parsecfg devices.$DEVTYPE.reponame)
REPOPORT=$(parsecfg devices.$DEVTYPE.repoport)
REPOIP=$(parsecfg devices.$DEVTYPE.repoip)      #IP of the registry in case it is local and thus 'insecure'

install_repo_resolution() {
	echo "export TERM=xterm" >> ~/.bashrc
	sudo mkdir -p /etc/rancher/k3s
	if [[ -n $REPOIP ]]; then
		if [[ -n $(cat /etc/hosts | grep ${REPONAME}) ]]
		then
			sudo sed -i "/${REPONAME}$/d" /etc/hosts
		fi
		echo "Private container registry defined, applying settings..."
		cat << EOF | sudo tee /etc/rancher/k3s/registries.yaml > /dev/null
mirrors:
  "${REPONAME}:${REPOPORT}":
    endpoint:
      - "http://${REPONAME}:${REPOPORT}"
EOF
	        echo "${REPOIP} ${REPONAME}" | sudo tee -a /etc/hosts > /dev/null
		sudo systemctl restart k3s*
fi
}
