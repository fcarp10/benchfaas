# Variables that are host-specific or will be changed for tests
module Variables
    $BRIDGE_BENCH = "eth0"
    $BRIDGE_IP = "192.168.41.220"
    $VMIMAGE = "generic/ubuntu2004"
    $PROVIDER = "libvirt"
    $NEBULAVERSION = "1.5.2"
    $K3SVERSION = "v1.20.5+k3s1"
    $TOTAL_DELAY = 6.25
    $DELAY_VAR = 1.25
    $PACKET_LOSS = 0.01
    $NODE_COUNT = 3
    $VMMEM = "2048"
    $VMCPU = "1"
end
