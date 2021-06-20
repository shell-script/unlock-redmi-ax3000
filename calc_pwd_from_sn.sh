#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2016 xiaooloong
# Copyright (C) 2021 ImmortalWrt.org
#
# Original idea from https://www.right.com.cn/forum/thread-189017-1-1.html

r1d_salt="A2E371B0-B34B-48A5-8C40-A7133F3B5D88"
# Salt must be reversed for non-R1D devices
others_salt="d44fb0960aa0-a5e6-4a30-250f-6d2df50a"
others_salt="$(sed "s,-, ,g" <<< "${others_salt}" | awk '{ for (i=NF; i>1; i--) printf("%s-",$i); print $1; }')"

if [ -z "${1}" ]; then
	read -r -e -p "SN: " sn
	[ -z "${sn}" ] && { echo "Please input SN!"; exit 1; }
else
	sn="${1}"
fi

# The alculation method of password:
# Do md5sum for SN and take the first 8 characters.
# If '/' is not included in SN it's R1D.
if grep -q "/" <<< "${sn}"; then
	echo -n "${sn}${others_salt}" | md5sum | awk '{print $1}' | head -c8; echo
else
	echo -n "${sn}${r1d_salt}" | md5sum | awk '{print $1}' | head -c8; echo
fi
