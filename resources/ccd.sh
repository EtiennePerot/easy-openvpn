ccdExists() {
	if [ -e "$userConfigDirectory/$1.ovpn" -o -e "$clientIPsDirectory/$1.ip" -o -e "$clientConfigDirectory/$1" -o -e "$easyRSAKeys/$1.csr" -o -e "$easyRSAKeys/$1.crt" -o -e "$easyRSAKeys/$1.key" ]; then
		echo 'true'
	fi
}

ccdDoAdd() {
	warnEnter
	cd "$easyRSADir"
	source "$easyRSAVars"
	./build-key "$1"
	eval "$(echo "echo \"$(cat "$ovpnClientConfigTemplate")\"")" > "$userConfigDirectory/$1.ovpn"
	chownmod "$easyUser:$easyGroup" 400 "$userConfigDirectory/$1.ovpn"
	echo "ifconfig-push $vpnSubnetCutoff.$2 $vpnServerInternalIp" > "$clientConfigDirectory/$1"
	chownmod "$easyUser:$easyGroup" 444 "$clientConfigDirectory/$1" # Must be readable by user 'nobody'
	echo "$2" > "$clientIPsDirectory/$1.ip"
	chownmod "$easyUser:$easyGroup" 400 "$clientIPsDirectory/$1.ip"
	info "Setup complete for client '$1'."
	warnEnterEnd
}

ccdDoRemove() {
	rm -f "$userConfigDirectory/$1.ovpn" "$clientIPsDirectory/$1.ip" "$clientConfigDirectory/$1" "$easyRSAKeys/$1.csr" "$easyRSAKeys/$1.crt" "$easyRSAKeys/$1.key"
	indexContent="$(cat "$easyRSAIndex" | grep -viP "/CN=$1/")"
	echo "$indexContent" > "$easyRSAIndex"
	indexOldContent="$(cat "$easyRSAIndexOld" | grep -viP "/CN=$1/")"
	echo "$indexOldContent" > "$easyRSAIndexOld"
}

ccdDoPrintConfig() {
	blankline
	echo '------------------------------------------------------------------------------' >&2
	echo '------------------------------- CONFIG FOLLOWS -------------------------------' >&2
	blankline
	cat "$userConfigDirectory/$1.ovpn" >&2
	blankline
	echo '--------------------------------- CONFIG END ---------------------------------' >&2
	echo '------------------------------------------------------------------------------' >&2
	blankline
}

ccdAdd() {
	echo -n '>> Client name to add (leave empty to quit): ' >&2
	read -r client
	while [ -n "$client" -a -n "$(ccdExists "$client")" ]; do
		info "Client '$client' already exists."
		echo -n '>> Client name to add (leave empty to quit): ' >&2
		read -r client
	done
	if [ -n "$client" ]; then
		ipEnding=''
		while true; do
			echo -n ">> IP of the client (Enter the \"x\" part of \"${vpnSubnetFriendly}\", 3-254 allowed, leave empty to quit): " >&2
			read -r ipEnding
			if [ -z "$ipEnding" ]; then
				break
			elif ! echo "$ipEnding" | grep -qP '^[0-9]+$'; then
				info "Invalid number: '$ipEnding'"
				continue
			elif [ "$(expr "$ipEnding" '<' 3 || true)" -eq 1 ]; then
				info "Invalid number: '$ipEnding' (must be larger than 3)"
				continue
			elif [ "$(expr "$ipEnding" '>' 254 || true)" -eq 1 ]; then
				info "Invalid number: '$ipEnding' (must be smaller than 254)"
				continue
			elif grep -qrP "^${ipEnding}$" "$clientIPsDirectory"; then
				info "IP '$vpnSubnetCutoff.$ipEnding' is already in use by client '$(grep -rPl "^${ipEnding}$" "$clientIPsDirectory" | sort | head -1)'."
				continue
			fi
			break
		done
		if [ -n "$ipEnding" ]; then
			ccdDoAdd "$client" "$ipEnding"
		fi
	fi
}

ccdRemove() {
	ccdList
	echo -n '>> Client name to remove (leave empty to quit): ' >&2
	read -r client
	while [ -n "$client" -a -z "$(ccdExists "$client")" ]; do
		info "Client '$client' does not exist."
		echo -n '>> Client name to remove (leave empty to quit): ' >&2
		read -r client
	done
	if [ -n "$client" ]; then
		ccdDoRemove "$client"
	fi
}

ccdList() {
	info "Client list ($(ccdNumClients)):" >&2
	for client in $(ls -1 "$userConfigDirectory"); do
		clientName="$(echo "$client" | sed 's/\.ovpn$//')"
		echo "   > "$clientName" ($vpnSubnetCutoff.$(cat "$clientIPsDirectory/$clientName.ip"))" >&2
	done
}

ccdPrintConfig() {
	ccdList
	echo -n '>> Client name (leave empty to quit): ' >&2
	read -r client
	while [ -n "$client" -a -z "$(ccdExists "$client")" ]; do
		info "Client '$client' does not exist."
		echo -n '>> Client name (leave empty to quit): ' >&2
		read -r client
	done
	if [ -n "$client" ]; then
		ccdDoPrintConfig "$client"
	fi
}

ccdNumClients() {
	ls -1 "$userConfigDirectory" | wc -l
}