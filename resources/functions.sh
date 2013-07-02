info() {
	echo '::' "$@" >&2
}

error() {
	echo '!!' "$@" >&2
	exit 1
}

blankline() {
	echo '' >&2
}

warnEnter() {
	info 'You will be asked a lot of questions by the easy-rsa scripts (not by easy-openvpn).'
	info 'From this point forward, you should ALWAYS PRESS ENTER, WITHOUT ENTERING ANYTHING.'
	info 'Even when you are asked for a password, do not enter one!'
	info 'The exception is when you are asked [y/n] questions. You should type "y" and then press Enter.'
	info 'Press Enter when you are ready to begin.'
	read foovar
	blankline
}

warnEnterEnd() {
	info 'You can stop blindly pressing Enter now. Just press it one last time to acknowledge that you have read this.'
	read foovar
	blankline
}

menu() {
	local choice
	echo ':: easy-openvpn menu' >&2
	echo '   1. Add client' >&2
	echo "   2. List clients ($(ccdNumClients))" >&2
	echo '   3. Show client config' >&2
	echo '   4. Remove client' >&2
	echo '   5. Uninstall easy-openvpn' >&2
	echo '   6. Exit menu' >&2
	echo -n '>> Choice (1-6): ' >&2
	read -r choice
	while ! echo "$choice" | grep -q '^[1-6]$'; do
		info 'Invalid choice.'
		echo -n '>> Choice (1-6): ' >&2
		read -r choice
	done
	echo "$choice"
}

chownmod() {
	own="$1"
	mod="$2"
	target="$3"
	shift; shift; shift
	chown "$@" "$own" "$target"
	chmod "$@" "$mod" "$target"
}
