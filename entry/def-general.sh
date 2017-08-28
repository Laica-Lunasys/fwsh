#!/usr/bin/env bash

# Refered : https://github.com/suin/iptables/blob/master/iptables.sh

###################
## DEFENSE: Stealth Scan
###################
echo -e "\e[1;32m*\e[00m DEFENSE: Stealth Scan"
iptables -N STEALTH_SCAN
iptables -A STEALTH_SCAN -j LOG --log-prefix "stealth_scan_attack: "
iptables -A STEALTH_SCAN -j DROP
# ステルススキャンらしきパケットは "STEALTH_SCAN" チェーンへジャンプする
iptables -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m state --state NEW -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN         -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST         -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ACK,FIN FIN     -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ACK,PSH PSH     -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ACK,URG URG     -j STEALTH_SCAN

###########################################################
# DEFENSE: フラグメントパケットによるポートスキャン,DOS攻撃
# nmap -v -sF などの対策
###########################################################
echo -e "\e[1;32m*\e[00m DEFENSE: Port Scan / DoS Attack from Flaggment Packet"
iptables -A INPUT -f -j LOG --log-prefix 'fragment_packet:'
iptables -A INPUT -f -j DROP

###########################################################
# DEFENSE: Ping of Death
###########################################################
echo -e "\e[1;32m*\e[00m DEFENSE: Ping of Death"
# 毎秒1回を超えるpingが10回続いたら破棄
iptables -N PING_OF_DEATH # "PING_OF_DEATH" という名前でチェーンを作る.
iptables -A PING_OF_DEATH -p icmp --icmp-type echo-request \
         -m hashlimit \
         --hashlimit 1/s \
         --hashlimit-burst 10 \
         --hashlimit-htable-expire 300000 \
         --hashlimit-mode srcip \
         --hashlimit-name t_PING_OF_DEATH \
         -j RETURN

###########################################################
# DEFENSE: SYN Flood Attack
# この対策に加えて Syn Cookie を有効にすべし。
###########################################################
echo -e "\e[1;32m*\e[00m DEFENSE: SYN Flood Attack"
iptables -N SYN_FLOOD # "SYN_FLOOD" という名前でチェーンを作る
iptables -A SYN_FLOOD -p tcp --syn \
         -m hashlimit \
         --hashlimit 200/s \
         --hashlimit-burst 3 \
         --hashlimit-htable-expire 300000 \
         --hashlimit-mode srcip \
         --hashlimit-name t_SYN_FLOOD \
         -j RETURN
# 制限を超えたSYNパケットを破棄
iptables -A SYN_FLOOD -j LOG --log-prefix "syn_flood_attack: "
iptables -A SYN_FLOOD -j DROP
# SYNパケットは "SYN_FLOOD" チェーンへジャンプ
iptables -A INPUT -p tcp --syn -j SYN_FLOOD