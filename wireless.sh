#!/bin/ash
# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2020 yyjdelete
# Copyright (C) 2021 Robert Marko <robimarko@gmail.com>
# Copyright (C) 2021 Tianling Shen <cnsztl@immortalwrt.org>
#
# Original threads:
# Redmi AX6 AX3000: https://www.right.com.cn/forum/thread-4060726-1-1.html
# Xiaomi AX6000/AX9000: https://forum.openwrt.org/t/openwrt-support-for-xiaomi-ax9000/98908/34

info_font="\033[36m[Info]\033[0m"
success_font="\033[32m[Success]\033[0m"
warning_font="\033[33m[Warning]\033[0m"

echo -e "${warning_font} Please make sure your router has wireless support!"
echo -e "${warning_font} Please make sure your router is restored to factory settings (not configured)!"
echo -e "${warning_font} Please make sure you've backed up the network and wireless settings!"
echo -e "${warning_font} Please make sure you've connected the router via *wired ethernet*!"
echo -e "${warning_font} Running this script will change your *network* settings!"
read -p "Use Ctrl+C to exit or press enter key to continue..."

echo -e ""
mkdir -p /usr/lib/lua/luci/controller/admin/
if [ -f "/usr/lib/lua/luci/controller/admin/xqsystem.lua" ]; then
    echo -e "${info_font} Adding xqsystem controller..."
    cat > "/usr/lib/lua/luci/controller/admin/xqsystem.lua" <<EOF
module("luci.controller.admin.xqsystem", package.seeall)

function index()
    local page   = node("api")
    page.target  = firstchild()
    page.title   = ("")
    page.order   = 100
    page.index = true
    page   = node("api","xqsystem")
    page.target  = firstchild()
    page.title   = ("")
    page.order   = 100
    page.index = true
    entry({"api", "xqsystem", "token"}, call("getToken"), (""), 103, 0x08)
end

local LuciHttp = require("luci.http")

function getToken()
    local result = {}
    result["code"] = 0
    result["token"] = "; nvram set ssh_en=1; nvram set uart_en=1; nvram set boot_wait=on; nvram commit; uci set wireless.@wifi-iface[0].key=\`mkxqimage -I\`; uci commit; sed -i 's/channel=.*/channel=\"debug\"/g' /etc/init.d/dropbear; /etc/init.d/dropbear start;"
    LuciHttp.write_json(result)
end
EOF
    
else
    echo -e "${info_font} Creating xqsystem controller..."
    touch /usr/lib/lua/luci/controller/admin/xqsystem.lua
    cat > "/usr/lib/lua/luci/controller/admin/xqsystem.lua" <<EOF
module("luci.controller.admin.xqsystem", package.seeall)

function index()
    local page   = node("api")
    page.target  = firstchild()
    page.title   = ("")
    page.order   = 100
    page.index = true
    page   = node("api","xqsystem")
    page.target  = firstchild()
    page.title   = ("")
    page.order   = 100
    page.index = true
    entry({"api", "xqsystem", "token"}, call("getToken"), (""), 103, 0x08)
end

local LuciHttp = require("luci.http")

function getToken()
    local result = {}
    result["code"] = 0
    result["token"] = "; nvram set ssh_en=1; nvram set uart_en=1; nvram set boot_wait=on; nvram commit; uci set wireless.@wifi-iface[0].key=\`mkxqimage -I\`; uci commit; sed -i 's/channel=.*/channel=\"debug\"/g' /etc/init.d/dropbear; /etc/init.d/dropbear start;"
    LuciHttp.write_json(result)
end
EOF
fi

echo -e "${info_font} Changing network settings..."
set -x
uci set dhcp.lan.ignore='1'
uci set network.lan.ipaddr='169.254.31.1'
uci set wireless.@wifi-iface[0].ssid='MEDIATEK-ARM-IS-GREAT'
uci set wireless.@wifi-iface[0].encryption='psk2'
uci set wireless.@wifi-iface[0].key='ARE-YOU-OK'
uci set wireless.@wifi-iface[0].mode='ap'
uci set wireless.@wifi-iface[0].network='LAN lan'
uci -q commit
set +x

echo -e "${success_font} All settings are applied.\n"
echo -e "${info_font} Please now disconnect from this router, and connect to your Xiaomi/Redmi router."
echo -e ""
echo -e "${info_font} For Xiaomi AX6000/AX9000:"
echo -e "       Open your browser, access the following URL:"
echo -e "         http://192.168.31.1/cgi-bin/luci/;stok=<STOK>/api/xqsystem/extendwifi_connect_inited_router?ssid=MEDIATEK-ARM-IS-GREAT&password=ARE-YOU-OK&admin_username=root&admin_password=admin&admin_nonce=xxx"
echo -e ""
echo -e "${info_font} For Redmi AX6 AX3000:"
echo -e "       Open your browser, access the following URL:"
echo -e "         http://192.168.31.1/cgi-bin/luci/;stok=<STOK>/api/misystem/extendwifi_connect?ssid=MEDIATEK-ARM-IS-GREAT&password=ARE-YOU-OK"
echo -e "       If the return code is 0, then access this URL:"
echo -e "         http://192.168.31.1/cgi-bin/luci/;stok=<STOK>/api/xqsystem/oneclick_get_remote_token?username=xxx&password=xxx&nonce=xxx"
echo -e ""
echo -e "${info_font} If the return code is 0, now you can connect to your router via SSH."
echo -e "${info_font} SSH login password is 5GHz wireless connection password."
echo -e ""
echo -e "${success_font} Thanks for usage."
echo -e "          Staff: yyjdelete, Robert Marko, Tianling Shen"

echo -e ""
echo -e "${warning_font} Restarting network..."
wifi reload >"/dev/null" 2>&1
/etc/init.d/network restart >"/dev/null" 2>&1
