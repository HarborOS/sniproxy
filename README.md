Harbor SNI Proxy 
=========

This version is modified from the upstream to enable a specific use case:
Proxying tcp connections to guests in the Harbor OpenStack/Kubernetes Platform.

It proxies incoming HTTP and TLS connections based on the hostname contained in
the initial request of the TCP session to a specific ip:port.
This enables HTTPS name-based virtual hosting to separate backend servers without
installing the private key on the proxy machine, to be served from a single public ip.


Features
--------
+ Name-based proxying of HTTPS without decrypting traffic. No keys or
  certificates required.
+ Supports both TLS and HTTP protocols.
+ Supports IPv4, IPv6 and Unix domain sockets for both back end servers and
  listeners.
+ Supports multiple listening sockets per instance.

Usage
-----

This application can be deployed as part of the Harbor OpenStack Platform.
The release container is hosted @ https://hub.docker.com/r/port/sniproxy-base/
No validation is performed on the ip-port ranges that this proxy attempts to connect to;
it is therefore essential to place this behind a mechanism to limit the range of potential sni
hostnames that reach the proxy. HAProxy is recommended for this, which can also serve to load
ballance accross multiple instances; providing HA for the edge of your network.

Configuration Syntax
--------------------

    user daemon

    pidfile /tmp/sniproxy.pid

    error_log {
        syslog daemon
        priority notice
    }

    listener 127.0.0.1:443 {
        protocol tls
        table TableName
        # Specify a server to use if the initial client request doesn't contain
        # a hostname
        fallback 192.0.2.5:443
    }

    table TableName {
        # Match exact request hostnames
        example.com 192.0.2.10:4343
        example.net [2001:DB8::1:10]:443
        # Define a single entry like below, this is required for this fork.
        # The starndard wildcard schema has been modified to forward to
        # internal servers (eg 10.0.0.1:9090) when clients hit an external 
        # hostname in the format 10.0.0.1-9090.example.com 
        (.*)-(.*)\\.example\\.com
    }

DNS Resolution
--------------

Using hostnames or wildcard entries in the configuration requires sniproxy to
be built with [UDNS](http://www.corpit.ru/mjt/udns.html). SNIProxy will still
build without UDNS, but these features will be unavailable.

UDNS uses a single UDP socket for all queries, so it is recommended you use a
local caching DNS resolver (with a single socket each DNS query is protected by
spoofing by a single 16 bit query ID, which makes it relatively easy to spoof).

UDNS is currently not available in Debian stable, but a package can be easily
built from the Debian testing or Ubuntu source packages:

    mkdir udns_packaging
    cd udns_packaging
    wget http://archive.ubuntu.com/ubuntu/pool/universe/u/udns/udns_0.4-1.dsc
    wget http://archive.ubuntu.com/ubuntu/pool/universe/u/udns/udns_0.4.orig.tar.gz
    wget http://archive.ubuntu.com/ubuntu/pool/universe/u/udns/udns_0.4-1.debian.tar.gz
    tar xfz udns_0.4.orig.tar.gz
    cd udns-0.4/
    tar xfz ../udns_0.4-1.debian.tar.gz
    dpkg-buildpackage
    cd ..
    sudo dpkg -i libudns-dev_0.4-1_amd64.deb libudns0_0.4-1_amd64.deb
