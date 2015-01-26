#!/bin/bash
#
# Simple Firewall configuration.
#
# Author: eXorus
#
# chkconfig: 2345 9 91
# description: Activates/Deactivates the firewall at boot time
#
### BEGIN INIT INFO
# Provides:          firewall.sh
# Required-Start:    $syslog $network
# Required-Stop:     $syslog $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start firewall daemon at boot time
# Description:       Custom Firewall script
### END INIT INFO
 
##########################
# Configuration
##########################
 
SSH_PORT="22"
FTP_PORT="21"
DNS_PORT="53"
MAIL_PORT="25"
NTP_PORT="123"
HTTP_PORT="80"
HTTPS_PORT="443"
 
HN_IP="1.2.3.4"
 
 
##########################
# Start the Firewall rules
##########################
 
fw_start(){
        # Ne pas casser les connexions etablies
        iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
        iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
 
        # Autoriser loopback
        iptables -t filter      -A INPUT        -i lo -s 127.0.0.0/8 -d 127.0.0.0/8 -j ACCEPT
        iptables -t filter      -A OUTPUT       -o lo -s 127.0.0.0/8 -d 127.0.0.0/8 -j ACCEPT
 
        # Autoriser le ping
        iptables -t filter      -A INPUT        -p icmp -j ACCEPT
        iptables -t filter      -A OUTPUT       -p icmp -j ACCEPT
 
        # Autoriser SSH
        iptables -t filter      -A INPUT        -p tcp --dport $SSH_PORT -j ACCEPT
        iptables -t filter      -A OUTPUT       -p tcp --dport $SSH_PORT -j ACCEPT
 
        # Autoriser NTP
        iptables -t filter      -A OUTPUT       -p udp --dport $NTP_PORT -j ACCEPT
 
        # Autoriser DNS
        iptables -t filter -A OUTPUT -p tcp --dport $DNS_PORT -j ACCEPT
        iptables -t filter -A OUTPUT -p udp --dport $DNS_PORT -j ACCEPT
        iptables -t filter -A INPUT -p tcp --dport $DNS_PORT -j ACCEPT
        iptables -t filter -A INPUT -p udp --dport $DNS_PORT -j ACCEPT
 
        # Autoriser HTTP et HTTPS
        iptables -t filter -A OUTPUT -p tcp --dport $HTTP_PORT -j ACCEPT
        iptables -t filter -A INPUT -p tcp --dport $HTTP_PORT -j ACCEPT
        iptables -t filter -A OUTPUT -p tcp --dport $HTTPS_PORT -j ACCEPT
        iptables -t filter -A INPUT -p tcp --dport $HTTPS_PORT -j ACCEPT
 
}
 
fw_stop(){
        # Vidage des tables et des regles personnelles
        iptables -t filter      -F
        iptables -t nat         -F
        iptables -t mangle      -F
        iptables -t filter      -X
 
        # Interdire toutes connexions entrantes et sortantes
        iptables -t filter      -P INPUT DROP
        iptables -t filter      -P FORWARD DROP
        iptables -t filter      -P OUTPUT DROP
}
fw_clear(){
        # Vidage des tables et des regles personnelles
        iptables -t filter      -F
        iptables -t nat         -F
        iptables -t mangle      -F
        iptables -t filter      -X
 
        # Accepter toutes connexions entrantes et sortantes
        iptables -t filter      -P INPUT ACCEPT
        iptables -t filter      -P FORWARD ACCEPT
        iptables -t filter      -P OUTPUT ACCEPT
}
 
fw_stop_ip6(){
        # Vidage des tables et des regles personnelles
        ip6tables -t filter     -F
        ip6tables -t mangle     -F
        ip6tables -t filter     -X
 
                # Interdire toutes connexions entrantes et sortantes
        ip6tables -t filter     -P INPUT DROP
        ip6tables -t filter     -P FORWARD DROP
        ip6tables -t filter     -P OUTPUT DROP
}
 
fw_clear_ip6(){
        # Vidage des tables et des regles personnelles
        ip6tables -t filter      -F
        ip6tables -t mangle      -F
        ip6tables -t filter      -X
 
        # Accepter toutes connexions entrantes et sortantes
        ip6tables -t filter      -P INPUT ACCEPT
        ip6tables -t filter      -P FORWARD ACCEPT
        ip6tables -t filter      -P OUTPUT ACCEPT
}
 
case "$1" in
        start|restart)
                echo -n "Starting firewall.."
                # fw_stop_ip6
                # fw_stop
                fw_start
                echo "done."
                ;;
        stop)
                echo -n "Stopping firewall.."
                fw_stop_ip6
                fw_stop
                echo "done."
                ;;
        clear)
                echo -n "Clearing firewall rules.."
                fw_clear_ip6
                fw_clear
                echo "done."
                ;;
        *)
                echo "Usage: $0 {start|stop|restart|clear}"
                exit 1
                ;;
esac
 
exit 0
