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

#### You will end up with:

* A VPN server accepting multiple clients
* A `tun` interface
* Uses the subnet `10.10.10.0/24`
* Clients are assigned fixed IPs in the `10.10.10.(3-254)` range
* Client-to-client communication enabled
* The server acts as the gateway at `10.10.10.1`
* 4096-bit keys everywhere
* The server keeps a copy of all the clients' private keys (for convenience, and possibility to re-print config files)
* AES-256-CBC cipher
* Shared 2048-bit secret key for TLS authentication
* LZO compression enabled
* A systemd service called `easy-openvpn.service` to start/stop/monitor it

#### Decisions that are left up to you:

This is the only stuff you have to figure out on your own, although there are sensible and/or autodetected default values for everything:

* The network interface that clients will access the Internet through
* The port number that the OpenVPN server should use
* Whether to use UDP or TCP
* The IP of the DNS server to suggest to clients
* The name and the `10.10.10.x` IP that you want to assign to each client

## Client management

When run, the script will set up whatever happens not to be set up (you can interrupt it anytime). When everything is setup, you will be presented with the following menu:

	:: easy-openvpn menu
	   1. Add client
	   2. List clients (n)
	   3. Show client config
	   4. Remove client
	   5. Uninstall easy-openvpn
	   6. Exit menu
	>> Choice (1-6):

A client entry represents a human-readable name, an IP, a key, and a certificate. The menu allows you to add new clients, delete existing ones, or re-print the `.ovpn` configuration files of existing clients.

All cryptographic information (CA certificate, client certificate, client private key, shared TLS authentication key, cipher settings, etc) is stored inside the `.ovpn` config file itself, such that the client needs nothing other than the one configuration file in order to connect to the VPN server.

## Licensing

easy-openvpn is licensed under the WTFPL.
