#!/usr/bin/env bash

checkdist() {
    if [ -e /etc/os-release ]; then
        DIST=$(cat /etc/os-release | grep "^ID=" | sed -e 's/"//g' | cut -c 4-)
    else
        DIST="unknown"
    fi
    echo $DIST
}

case "$(checkdist)" in
    centos)
        export IPTABLES_PATH="/etc/sysconfig/iptables"
        export IPTABLES_SERVICE_NAME="iptables"
        ;;
    debian|ubuntu)
        export IPTABLES_PATH="/etc/iptables/rules.v4"
        export IPTABLES_SERVICE_NAME="netfilter-persistent"
        ;;
    *)
        echo "Unknown System"
        exit 1
        ;;
esac