confVars="
selfHostname;IP or domain name of this box (clients will use this address to connect);>confGetHostname;.*
portNumber;Port number for the server to listen on;1194;[0-9]+
protocol;Protocol to use for the server ('tcp' or 'udp');udp;udp|tcp
dnsServer;DNS server to suggest to clients (Use 127.0.0.1 for local DNS server);87.118.100.175;[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+
outboundInterface;Network interface going out to the Internet;$(ip route | grep '^default' | sed -r 's/^.*\s+dev\s+(\S+).*$/\1/i');.*
shouldForward;Should this machine have IPv4 forwarding enabled all the time? (y/n);$(cat /proc/sys/net/ipv4/ip_forward | sed -e 's/0/n/' -e 's/1/y/');y|n
shouldPromisc;Should this machine's outbound network interface be in promiscuous mode all the time? (y/n);n;y|n
"

confGetHostname() {
	curl https://icanhazip.com/ 2>/dev/null || dnsdomainname || hostname
}

getConfField() {
	echo "$confVars" | grep "^$1;" | cut -d ';' -f "$2"
}

getConf() {
	local value defaultValue
	if [ -f "$easyConf/$1" ]; then
		cat "$easyConf/$1"
		return 0
	fi
	defaultValue="$(getConfField "$1" 3)"
	if [ "${defaultValue:0:1}" == '>' ]; then
		defaultValue="$(eval "${defaultValue:1}")"
	fi
	if [ ! -d "$easyConf" ]; then
		mkdir -p "$easyConf"
		chownmod "$easyUser:$easyGroup" 700 "$easyConf"
	fi
	echo -n ">> $(getConfField "$1" 2) [Default: $defaultValue]: " >&2
	read -r value
	if [ -z "$value" ]; then
		info "Using default value '$defaultValue'" >&2
		value="$defaultValue"
	fi
	while ! echo "$value" | grep -qiP "^($(getConfField "$1" 4))$"; do
		echo "Invalid value: $value" >&2
		echo -n ">> $(getConfField "$1" 2) [Default: $defaultValue]: " >&2
		read -r value
	done
	echo "$value" > "$easyConf/$1"
	chownmod "$easyUser:$easyGroup" 600 "$easyConf"
	echo "$value"
}
