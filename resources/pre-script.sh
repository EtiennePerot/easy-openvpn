#!$(which bash)

set -e

sysctl -q -w net.ipv4.ip_forward=1
ip link set dev \"${outboundInterface}\" promisc on
iptables -t nat -N $iptablesChain || true
iptables -t nat -F $iptablesChain
iptables -t nat -D POSTROUTING -j $iptablesChain || true
iptables -t nat -A POSTROUTING -j $iptablesChain
iptables -t nat -A $iptablesChain -s \"${vpnSubnet}\" -o \"${outboundInterface}\" -j MASQUERADE
