#!/usr/bin/env bash

## BEGIN CONFIGURATION
# prefix
PREFIX="\e[1;32m==>\e[00m"
RPREFIX="\e[1;35m==>\e[00m"
EPREFIX="\e[1;31m!!!\e[00m"

# service
SSH=22
HTTP=80,443
## END CONFIGURATION

if [ ! $UID = "0" ]; then
    echo -e "$EPREFIX Must be Root." && exit 1
fi


## accept packet from established session
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

cd $(dirname $0)/
bash ./entry/def-general.sh
bash ./entry/def-ssh.sh $SSH
bash ./entry/def-http.sh $HTTP

echo -e "$PREFIX All DEFENSE Activated."
exit 0
