#!/usr/bin/env bash

HTTP=$1

###########################################################
# DEFENSE: HTTP DoS/DDoS Attack
###########################################################
echo -e "\e[1;32m*\e[00m DEFENSE: HTTP Dos/DDoS Attack"
iptables -N HTTP_DOS # "HTTP_DOS" という名前でチェーンを作る
iptables -A HTTP_DOS -p tcp -m multiport --dports $HTTP \
         -m hashlimit \
         --hashlimit 1/s \
         --hashlimit-burst 100 \
         --hashlimit-htable-expire 300000 \
         --hashlimit-mode srcip \
         --hashlimit-name t_HTTP_DOS \
         -j RETURN
# 制限を超えた接続を破棄
iptables -A HTTP_DOS -j LOG --log-prefix "http_dos_attack: "
iptables -A HTTP_DOS -j DROP
# HTTPへのパケットは "HTTP_DOS" チェーンへジャンプ
iptables -A INPUT -p tcp -m multiport --dports $HTTP -j HTTP_DOS

# Allow only CloudFlare
#for cf in $(curl https://www.cloudflare.com/ips-v4); do
#    echo -e "\e[1;32m*\e[00m -> Adding CloudFlare IPs: $cf"
#    iptables -A INPUT -p tcp -m multiport --dports $HTTP -s "$cf" -j ACCEPT
#done
