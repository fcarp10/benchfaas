bootstrap() {
#if yq doesn't exist, download it:
    BINARYDIR="$TOOLKITPATH/../aux/external_binaries"
    if [[ $(uname -m) == aarch64 ]]
    then
        TESTER_ARCH=arm64
    elif [[ $(uname -m) == x86_64 ]]
    then
        TESTER_ARCH=amd64
    else
    echo "Could not determine CPU architecture, aborting..."
    exit 5
    fi
    echo ${BINARYDIR}
    if [ -f ${BINARYDIR}/yq ]
    then
        echo "Binaries are already present, skipping..."
    else
        mkdir -p ${BINARYDIR}

    SUCCESS=1
        until [ $SUCCESS = 0 ]
    do
        echo "Downloading yq for archtecture $TESTER_ARCH to ${BINARYDIR}"
        curl -Lo ${BINARYDIR}/yq https://github.com/mikefarah/yq/releases/download/v4.25.1/yq_linux_$TESTER_ARCH
        SUCCESS=$?
    done
        chmod +x ${BINARYDIR}/yq
    fi
}
