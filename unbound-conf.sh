#!/bin/bash

set -euxo pipefail

# eth0を指定してinterfaceのIPv4アドレスを検索する
INTERFACE_IPv4_ADDR_ETH0=$(ip addr | sed -ne '/eth0/p' | awk '{print $2}' | sed -ne '/\//p' | sed 's/\/.*//')
# デバッグ用
#echo $INTERFACE_IPv4_ADDR_ETH0

# タブを2個分エスケープしてinterfaceを追加する
sed -i -e "16i\        interface: $INTERFACE_IPv4_ADDR_ETH0" /etc/unbound/unbound.conf