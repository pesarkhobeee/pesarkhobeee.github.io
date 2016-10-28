#!/bin/bash
#Refrence : https://wiki.archlinux.org/index.php/simple_stateful_firewall#Example_iptables.rules_file

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[1-9]{2}$ ]]; then
        OIFS=$IFS
        IFS='/'
        subnet=($ip)
        IFS='.'
        ip=(${subnet[0]})
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 && ${subnet[1]} -le 32 ]]
        stat=$?
    fi

    return $stat
}

start() {
	echo "Before firewall ran, the state of firewall was : "
	iptables -nvL --line-numbers

	iptables -P FORWARD DROP
	iptables -P OUTPUT ACCEPT
	iptables -P INPUT DROP

	iptables -N TCP
	iptables -N UDP

	iptables -A INPUT -i lo -j ACCEPT
        iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT

	#allow to connect from ssh to this compueter from every where 
	iptables -A INPUT -p tcp --dport 22 -j ACCEPT

	file="ips.txt"
	while IFS= read ip
	do
		if valid_ip $ip;then
			stat='opend in firewall'; 
			iptables -A INPUT -p tcp -s $ip --dport 80 -j ACCEPT
		else 
			stat='bad ip format'; 
		fi
			printf "%-20s: %s\n" "$ip" "$stat"
			#iptables -A INPUT -p tcp -s 192.168.112.11 --dport 80 -j ACCEPT
	done <"$file"

	

	#Allow to view all website from this computer
	iptables -A INPUT -p tcp --sport 80 -j ACCEPT
	iptables -A INPUT -p tcp --sport 443 -j ACCEPT
	iptables -A INPUT -p udp --sport 53 -j ACCEPT


	echo "==============================================="
	echo "after firewall ran, the state of firewall is : "
	iptables -nvL --line-numbers
}


stop() {
	iptables -t filter -F
	iptables -t filter -X
	iptables -t filter -Z
	iptables -t filter -P INPUT ACCEPT
	iptables -t filter -P OUTPUT ACCEPT
	iptables -t filter -P FORWARD ACCEPT
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  *)
    echo $"Usage: sinic_firewall {start|stop}"
    exit 1
esac


