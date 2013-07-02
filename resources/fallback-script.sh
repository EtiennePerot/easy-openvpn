#!$(which bash)

set -e

"$systemdServicePreScript"
"$(which openvpn)" --cd "$easyRoot" --config "$ovpnConfigFile" --daemon "$daemonName"
"$systemdServicePostScript"
