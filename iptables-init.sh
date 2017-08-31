#!/usr/bin/env bash

source $(dirname $0)/check-os.sh

## BEGIN CONFIGURATION
# prefix
PREFIX="\e[1;32m==>\e[00m"
RPREFIX="\e[1;35m==>\e[00m"
EPREFIX="\e[1;31m!!!\e[00m"

allow_hosts=("`cat $(dirname $0)/zone/allow_hosts`")
## END CONFIGURATION

init() {
        iptables -F
        iptables -X
        iptables -Z
        iptables -P INPUT   ACCEPT
        iptables -P OUTPUT  ACCEPT
        iptables -P FORWARD ACCEPT
}

finish() {
        sudo iptables-save > "${IPTABLES_PATH}" && # 設定の保存
        sudo systemctl restart "${IPTABLES_SERVICE_NAME}" && # 保存したもので再起動してみる
        exit 0
        exit 1
}

if [ ! $UID = "0" ]; then
    echo -e "$EPREFIX Must be Root." && exit 1
fi

# init
entry=`sudo cat "${IPTABLES_PATH}" | grep -e "-A INPUT -p" | grep -e "-m multiport --dports" | grep -e "-j ACCEPT"`
if [ ! "$entry" = "" ]; then
    backup=true
    echo -e "$RPREFIX Backup iptables..."
    sudo cat "${IPTABLES_PATH}" | grep -e "-A INPUT -p" | grep -e "-m multiport --dports" | grep -e "-j ACCEPT" >> $(dirname $0)/backup_iptables
fi

echo -e "$RPREFIX Init iptables..."
init

iptables -P INPUT   DROP
iptables -P OUTPUT  ACCEPT
iptables -P FORWARD DROP

# Allow Local Loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow Established Session
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Add whitelist
if [ "${allow_hosts}" ]; then
    for allow_host in ${allow_hosts[@]}; do
        echo -e "$RPREFIX Adding allow_host: $allow_host"
        # Allow Only TCP: iptables -A INPUT -p tcp -s $allow_host -j ACCEPT
        iptables -A INPUT -s $allow_host -j ACCEPT
    done
fi

# Extract Defense Shield
$(dirname $0)/iptables-defense.sh

if [ "$backup" = true ]; then
    echo -e "$PREFIX Extract backup..."
    cat $(dirname $0)/backup_iptables | while read entry; do
        echo "Entry: $entry"
        iptables $entry
    done
    rm $(dirname $0)/backup_iptables
fi

echo -e "$PREFIX Finish iptables setup..."
finish
