#!/bin/ash
# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2020 paldier (https://www.right.com.cn/forum/thread-4046020-1-1.html)
# Copyright (C) 2020 yyjdelete (https://www.right.com.cn/forum/thread-4060726-1-1.html)
# Copyright (C) 2021 Tianling Shen <cnsztl@immortalwrt.org>

info_font="\033[36m[Info]\033[0m"
success_font="\033[32m[Success]\033[0m"
warning_font="\033[33m[Warning]\033[0m"

dump_mtd(){
	echo -e "${info_font} Dumping MTD9..."
	mkdir -p /tmp/syslogbackup/
	nanddump -f /tmp/syslogbackup/bdata_mtd9.img /dev/mtd9
	echo -e "${success_font} Done."
	echo -e "${info_font} Now you can download it at:"
	echo -e "       http://192.168.31.1/backup/log/bdata_mtd9.img"
}

keep_script(){
	echo -e "${info_font} Creating keep.d for mounting script..."
	cat > "/lib/upgrade/keep.d/miwifi_overlay" <<-EOF
		/etc/init.d/miwifi_overlay
		/etc/rc.d/S00miwifi_overlay
	EOF
	sync
	echo -e "${success_font} Done."
}

mount_overlay(){
	echo -e "${info_font} Creating mounting overlay script..."
	cat > "/etc/init.d/miwifi_overlay" <<-EOF
	#!/bin/sh /etc/rc.common

	START=00

	. /lib/functions/preinit.sh

	start() {
	        [ -e /data/overlay ] || mkdir /data/overlay
	        [ -e /data/overlay/upper ] || mkdir /data/overlay/upper
	        [ -e /data/overlay/work ] || mkdir /data/overlay/work

	        mount --bind /data/overlay /overlay
	        fopivot /overlay/upper /overlay/work /rom 1

	        #Fixup miwifi misc, and DO NOT use /overlay/upper/etc instead, /etc/uci-defaults/* may be already removed
	        /bin/mount -o noatime,move /rom/data /data 2>&-
	        /bin/mount -o noatime,move /rom/etc /etc 2>&-
	        /bin/mount -o noatime,move /rom/ini /ini 2>&-
	        /bin/mount -o noatime,move /rom/userdisk /userdisk 2>&-

	        #Enable SSH
	        grep -q 'channel="debug"' /etc/init.d/dropbear || {
	            sed -i 's/channel=.*/channel="debug"/g' /etc/init.d/dropbear
	            /etc/init.d/dropbear start
	        }

	        return 0
	}
	EOF
	chmod 755 /etc/init.d/miwifi_overlay
	/etc/init.d/miwifi_overlay enable
	sync
	echo -e "${success_font} Done."
	echo -e "${info_font} After reboot, please run 'sh $0 keep' to keep these settings when upgrade."
}

case "$1" in
	"hack")
		chmod 0755 /etc/fuckax3000
		/etc/fuckax3000 hack
		/etc/fuckax3000 lock
		echo -e "${success_font} Now you've got permanent Telnet/SSH access."
		;;
	"unlock")
		chmod 0755 /etc/fuckax3000
		/etc/fuckax3000 unlock
		echo -e "${info_font} After reboot, please run 'sh $0 hack' to get permanent Telnet/SSH access."
		echo -e ""
		echo -e "${warning_font} Your device should be rebooted automatically, if not, please do it manually."
		;;
	"dump")
		dump_mtd
		;;
	"keep")
		keep_script
		;;
	"mount")
		mount_overlay
		;;
	*)
		echo -e "${info_font} Usage: sh $0 [hack|unlock|dump|keep|mount]"
		exit 2
		;;
esac
