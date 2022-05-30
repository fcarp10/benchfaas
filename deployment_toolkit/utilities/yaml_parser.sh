parsecfg() {
    YAML="$TOOLKITPATH/../config.yml"
    BINARYPATH=$TOOLKITPATH/../aux/external_binaries/yq
    echo "$($BINARYPATH $2 .$1 $YAML)"
}
