#!/usr/bin/env bash

source $(dirname $0)/check-os.sh

## BEGIN CONFIGURATION
PREFIX="\e[1;32m==>\e[00m"
RPREFIX="\e[1;35m==>\e[00m"
EPREFIX="\e[1;31m!!!\e[00m"
## END CONFIGURATION

add() {
    PORT=$1
    PROTOCOL=$2
    ENTRY="INPUT -p ${PROTOCOL} -m multiport --dports ${PORT} -j ACCEPT"

    sudo cat "${IPTABLES_PATH}" | grep -e "${ENTRY}"
    if [ $? = 0 ]; then
        echo -e "$EPREFIX Already Exists: ${PORT}"
        exit 1
    fi

    echo -e "$RPREFIX Activating PORT... : ${PORT}"
    sudo iptables -A ${ENTRY}
}

remove() {
    PORT=$1
    PROTOCOL=$2
    ENTRY="INPUT -p ${PROTOCOL} -m multiport --dports ${PORT} -j ACCEPT"

    sudo cat "${IPTABLES_PATH}" | grep -e "${ENTRY}"
    if [ $? = 1 ]; then
        echo -e "$EPREFIX Not Exists: ${PORT}"
        exit 1
    fi

    echo -e "$RPREFIX Removing PORT... : ${PORT}"
    sudo iptables -D ${ENTRY}
}

iptables_reload() {
    echo -e "$RPREFIX Reloading Firewall..."
    sudo iptables-save > "${IPTABLES_PATH}" &&
    sudo systemctl restart "${IPTABLES_SERVICE_NAME}" &&
    exit 0
    exit 1
}

if [ ! $UID = "0" ]; then
    echo -e "$EPREFIX Must be Root." && exit 1
fi

if [ "$1" = "-p" ] && [ "$1" = "-r" ] || [ ! "$2" = "" ]; then
  PORT=`echo $2 | cut -d / -f1`
  PROTOCOL=`echo $2 | cut -d / -f2`

  if [ ! "$PROTOCOL" = "tcp" ] && [ ! "$PROTOCOL" = "udp" ] || [ "$PROTOCOL" = "" ]; then
    echo -e "$EPREFIX Unknown Protocol: $PROTOCOL"
    exit 1
  fi

  if [ "$1" = "-p" ]; then
      add $PORT $PROTOCOL
      iptables_reload
  elif [ "$1" = "-r" ]; then
      remove $PORT $PROTOCOL
      iptables_reload
  fi
fi

if [ "$1" = "-l" ]; then
    echo -e "$PREFIX Getting Entry..."
    sudo cat "${IPTABLES_PATH}" | grep -e "-A INPUT -p" | grep -e "-m multiport --dports" | grep -e "-j ACCEPT"
    exit 0
fi
echo "Usage: fw.sh [-p port/protocol] [-r port/protocol] [-l]"
exit 1

