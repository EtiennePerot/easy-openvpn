#!/usr/bin/env bash

set -e

scriptDir="$(dirname "$(readlink -e "$BASH_SOURCE")")"
resourceDir="$scriptDir/resources"
source "$resourceDir/globals.sh"
source "$resourceDir/functions.sh"
source "$resourceDir/ccd.sh"
source "$resourceDir/conf.sh"

if [ "$UID" -ne 0 ]; then
	if which sudo &> /dev/null; then
		info 'Re-running script with sudo...'
		exec sudo "$0" "$@"
	fi
	error 'This script is meant to be run as root.'
fi

if ! grep -q "^$easyGroup:" /etc/group; then
	info "Creating '$easyGroup' group..."
	groupadd "$easyGroup"
fi

if ! grep -q "^$easyUser:" /etc/passwd; then
	info "Creating '$easyUser' user..."
	useradd -m -d "$easyRoot" -s /bin/false -g "$easyGroup" "$easyUser"
fi

if [ ! -d "$easyRoot" ]; then
	info "Creating main directory '$easyRoot'..."
	mkdir -p "$easyRoot"
fi
chown -R "$easyUser:$easyGroup" "$easyRoot"
chmod 711 "$easyRoot"
cd "$easyRoot"
mkdir -p "$easyRSADir"
if [ ! -d "$easyRSABase" ]; then
	error "Cannot find Easy-RSA scripts at '$easyRSABase'. Make sure OpenVPN is installed."
fi
if [ ! -f "$easyRSADoneFile" ]; then
	info 'Setting up PKI infrastructure.'
	warnEnter
	# Begin CA setup
	rm -rf "$easyRSADir"
	cp -r "$easyRSABase" "$easyRSADir"
	chownmod "$easyUser:$easyGroup" 700 "$easyRSADir" -R
	cat "$easyRSAVarsTemplate" | sed "s|%EASYRSADIR%|$easyRSADir|g" > "$easyRSAVars"
	cd "$easyRSADir"
	source "$easyRSAVars"
	./clean-all
	./build-ca
	./build-key-server "$serverName"
	./build-dh
	openvpn --genkey --secret "$sharedTLSSecret"
	# End CA setup
	touch "$easyRSADoneFile"
	chownmod "$easyUser:$easyGroup" 400 "$easyRSADoneFile"
	blankline
	info 'easy-openvpn setup complete!'
	warnEnterEnd
fi
selfHostname="$(getConf selfHostname)"
outboundInterface="$(getConf outboundInterface)"
portNumber="$(getConf portNumber)"
protocol="$(getConf protocol)"
dnsServer="$(getConf dnsServer)"
shouldForward="$(getConf shouldForward | tr '[:upper:]' '[:lower:]')"
shouldPromisc="$(getConf shouldPromisc | tr '[:upper:]' '[:lower:]')"

# Make files
# ---- Main config file
eval "$(echo "echo \"$(cat "$ovpnServerConfigTemplate")\"")" > "$ovpnConfigFile"
chownmod "$easyUser:$easyGroup" 400 "$ovpnConfigFile"

# ---- systemd service
eval "$(echo "echo \"$(cat "$fallbackScriptTemplate")\"")" > "$fallbackScript"
chownmod "$easyUser:$easyGroup" 755 "$fallbackScript"
eval "$(echo "echo \"$(cat "$systemdServicePreScriptTemplate")\"")" > "$systemdServicePreScript"
chownmod "$easyUser:$easyGroup" 755 "$systemdServicePreScript"
eval "$(echo "echo \"$(cat "$systemdServicePostScriptTemplate")\"")" > "$systemdServicePostScript"
chownmod "$easyUser:$easyGroup" 755 "$systemdServicePostScript"
eval "$(echo "echo \"$(cat "$systemdServiceTemplate")\"")" > "$systemdService"
chownmod --reference="$systemdServiceRoot" 644 "$systemdService"

# ---- Client config files
mkdir -p "$clientConfigDirectory" "$userConfigDirectory" "$clientIPsDirectory"
chownmod "$easyUser:$easyGroup" 711 "$clientConfigDirectory" # Must be 711 so that user 'nobody' can access it
chownmod "$easyUser:$easyGroup" 700 "$clientIPsDirectory"
chownmod "$easyUser:$easyGroup" 700 "$userConfigDirectory"

# Main menu
while true; do
	choice="$(menu)"
	if [ "$choice" == 1 ]; then
		ccdAdd
	elif [ "$choice" == 2 ]; then
		ccdList
	elif [ "$choice" == 3 ]; then
		ccdPrintConfig
	elif [ "$choice" == 4 ]; then
		ccdRemove
	elif [ "$choice" == 5 ]; then
		systemctl stop "$daemonName" &>/dev/null || true
		rm -rf "$easyRoot" "$systemdService"
		info 'easy-openvpn uninstalled.'
		exit 0
	elif [ "$choice" == 6 ]; then
		break
	fi
done
blankline
info 'easy-openvpn is ready to go.'
if which systemctl &> /dev/null; then
	info "You can control it using the 'easy-openvpn' systemd service."
else
	info "Since you don't seem to have systemd, you will need to run '$fallbackScript' manually."
	info 'You can add that to your startup script if you want.'
	info 'To properly shut down OpenVPN after that, simply send a signal to the OpenVPN process.'
fi
