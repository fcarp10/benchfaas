
copy_and_install_hn() {
	echo "Using scp to copy to $FAAS_LOGIN@$FAAS_IP"
	scp -r deployment_toolkit/k3s ${FAAS_LOGIN}@${FAAS_IP}:${WORKPATH}benchfaas/deployment_toolkit/ > /dev/null
	scp -r deployment_toolkit/openfaas ${FAAS_LOGIN}@${FAAS_IP}:${WORKPATH}benchfaas/deployment_toolkit/
	scp -r deployment_toolkit/functions ${FAAS_LOGIN}@${FAAS_IP}:${WORKPATH}benchfaas/deployment_toolkit/ > /dev/null
	echo "Installing payload to K3s cluster..."
	ssh -n ${FAAS_LOGIN}@${FAAS_IP} "${WORKPATH}benchfaas/deployment_toolkit/k3s/k3s_openfaas.sh $DEVTYPE"
}
