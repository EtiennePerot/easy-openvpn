# easy-openvpn

This is a Bash script which sets up a complete OpenVPN server meant to be used as a proxy.

It is very opinionated in order to keep things dead simple for the end-user, hence the "easy" part of the name. The decisions it makes are listed in the "Results" section.

## Usage

Clone the repository on the server:

	$ git clone git://perot.me/easy-openvpn

Run the script as root:

	$ sudo easy-openvpn/easy-openvpn.sh

And then follow the on-screen instructions. You can re-run the script anytime if you need to manage the list of allowed clients. Once you're done, use the `easy-openvpn.service` systemd service to start/stop the VPN server.

*Privacy notice*: The script will contact `icanhazip.com` on first use.

## Results

You will end up with:

* A VPN server accepting multiple clients
* A `tun` interface
* Uses the subnet `10.10.10.0/24`
* Clients are assigned fixed IPs in the `10.10.10.(3-254)` range
* Client-to-client communication enabled
* The server acts as the gateway at `10.10.10.1`
* 4096-bit keys everywhere
* AES-256-CBC cipher
* Shared 2048-bit secret key for TLS authentication
* LZO compression enabled
* A systemd service called `easy-openvpn.service` to start/stop/monitor it

Decisions that are left up to you:

* Port number on the server
* UDP or TCP
* DNS server to suggest to clients over DHCP
* The actual `10.10.10.x` IP assigned to each client

## Licensing

easy-openvpn is licensed under the WTFPL.
