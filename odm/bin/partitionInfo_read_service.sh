#!/vendor/bin/sh
#
# Copyright 2021 Sony Corporation
#

modem_build_id=$(cat /vendor/firmware_mnt/verinfo/build_id.txt)
modem_mcfg_pkg=$(cat /vendor/firmware_mnt/verinfo/mcfg_pkg.txt)
modem_info="${modem_build_id};${modem_mcfg_pkg}"
setprop ro.odm.sony.partition_info.modem "$modem_info"
info_modem=$(getprop ro.odm.sony.partition_info.modem)
/vendor/bin/log -p i -t partitionInfo_read_service "modem: $info_modem"

bt_filename=$(find /vendor/bt_firmware/image -type f | sort | head -1)
bt_timestamp=$(date +'%FT%T' -r $bt_filename)
bt_info="${bt_filename##*/};${bt_timestamp}"
setprop ro.odm.sony.partition_info.bt "$bt_info"
info_bt=$(getprop ro.odm.sony.partition_info.bt)
/vendor/bin/log -p i -t partitionInfo_read_service "bt: $info_bt"

dsp_info=$(date +'%FT%T%z' -u -r /vendor/dsp/adsp)
setprop ro.odm.sony.partition_info.dsp "$dsp_info"
info_dsp=$(getprop ro.odm.sony.partition_info.dsp)
/vendor/bin/log -p i -t partitionInfo_read_service "dsp: $info_dsp"
