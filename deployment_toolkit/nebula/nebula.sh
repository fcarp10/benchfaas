#script considers parameter 1 to be the nebula version that shall be installed and parameter 2 (optional) to be the architecture. The latter will default to AMD64.

#nebula-cert sign -name "lighthouse" -ip "192.168.50.100/24"
#nebula-cert sign -name "worker1" -ip "192.168.50.101/24"
#nebula-cert sign -name "worker2" -ip "192.168.50.102/24"
#nebula-cert sign -name "worker3" -ip "192.168.50.103/24"
#nebula-cert sign -name "headnode" -ip "192.168.50.99/24"

NEBULAFILES="/vagrant/deployment_toolkit/nebula/config"	#directory that contains the nebula config files
TMP="/tmp"			#any writable directory to temporarily store the downloaded executables

#--------------------------------------------------------------------------#

#display help
if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$#" -eq 0 ]
then
	echo "Use like this: $0 NEBULAVERSION ARCHITECTURE"
	echo "Example: $0 1.5.2 amd64"
	exit
fi

#Installing nebula
if [ "$#" -eq 2 ]
then
	ARCH=$2
else
	ARCH=amd64
fi
[ 1 = 2 ]
until [ $? -eq 0 ]
do
    wget https://github.com/slackhq/nebula/releases/download/v$1/nebula-linux-$ARCH.tar.gz -P $TMP
done
cd $TMP
tar xvfz nebula-linux-$ARCH.tar.gz
rm $TMP/nebula-linux-$ARCH.tar.gz
mv $TMP/nebula /usr/local/bin/
mv $TMP/nebula-cert /usr/local/bin/

#Copying the configuration files and certificates
mkdir -p /etc/nebula
HSTNM=$(hostname)
if [ "$HSTNM" = "lighthouse" ] || [ "$HSTNM" = "rpi20" ]
then
    echo "Installing device $HSTNM as nebula lighthouse..."
    cp $NEBULAFILES/$HSTNM.yml /etc/nebula/nebula.yml
    cp $NEBULAFILES/lighthouse.crt /etc/nebula/nebula.crt
    cp $NEBULAFILES/lighthouse.key /etc/nebula/nebula.key
else
    echo "Installing device $HSTNM as nebula client..."
    cp $NEBULAFILES/client.yml /etc/nebula/nebula.yml
    cp $NEBULAFILES/$HSTNM.crt /etc/nebula/nebula.crt
    cp $NEBULAFILES/$HSTNM.key /etc/nebula/nebula.key
fi
cp $NEBULAFILES/ca.crt /etc/nebula/

#Creating and starting the service
cat << EOF > /etc/systemd/system/nebula.service
[Unit]
Description=nebula
Wants=basic.target
After=basic.target network.target
Before=sshd.service

[Service]
SyslogIdentifier=nebula
StandardOutput=syslog
StandardError=syslog
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/nebula -config /etc/nebula/nebula.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl start nebula
systemctl enable nebula
