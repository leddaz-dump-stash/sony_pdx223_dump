#!/system/bin/sh

# Copyright (C) 2018 Sony Mobile Communications Inc.

# start packet logging
if [ $1 -eq 1 ]; then
    iwpriv wlan0 pktlog 0
    iwpriv wlan0 pktlog 1
fi

# stop packet logging and save file
if [ $1 -eq 0 ]; then
    iwpriv wlan0 pktlog 0

    target_file=`getprop sys.wlan.packet.file`
    if [ -z $target_file ]; then
        target_file='/sdcard/wlan_packet_log.dat'
    fi
    cat /proc/ath_pktlog/cld > $target_file
fi
