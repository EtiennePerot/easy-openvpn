#!$(which bash)

set -e

if [ \"${shouldForward}\" == \"n\" ]; then
	sysctl -q -w net.ipv4.ip_forward=0
fi
if [ \"${shouldPromisc}\" == \"n\" ]; then
	ip link set dev \"${outboundInterface}\" promisc off
fi
iptables -t nat -D POSTROUTING -j $iptablesChain
iptables -t nat -F $iptablesChain
iptables -t nat -X $iptablesChain
