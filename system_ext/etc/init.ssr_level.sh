#!/system/bin/sh
# Copyright (c) 2016 Sony Mobile Communications Inc.
# Copyright 2022 Sony Corporation

function nagara_init
{
    local ssr_str="$1"
    typeset -a ssr_array
    ssr_array=($ssr_str)
    typeset -i i=0
    local subsys=`cat /sys/class/remoteproc/remoteproc$i/name`
    local subsys_name=$(echo $subsys | cut -d "-" -f2)

    while [ "$subsys_name" != "" ]
    do
       for num in "${!ssr_array[@]}"
       do
          if [ "$subsys_name" == ${ssr_array[$num]} ]; then
            echo "enabled" > /sys/class/remoteproc/remoteproc$i/recovery
            if [ "$build_variant" != "user" ]; then
              echo "enabled" > /sys/class/remoteproc/remoteproc$i/coredump
            else
              echo "disabled" > /sys/class/remoteproc/remoteproc$i/coredump
            fi
            break 1
          else
            echo "disabled" > /sys/class/remoteproc/remoteproc$i/recovery
            echo "disabled" > /sys/class/remoteproc/remoteproc$i/coredump
          fi
       done

       i=$i+1
       subsys=`cat /sys/class/remoteproc/remoteproc$i/name`
       subsys_name=$(echo $subsys | cut -d "-" -f2)
    done

    for num in "${!ssr_array[@]}"
    do
      if [ "wlan" == ${ssr_array[$num]} ]; then
        echo "1" > /sys/kernel/cnss/recovery
        if [ "$build_variant" != "user" ]; then
          echo "1" > /sys/module/qcom_ramdump/parameters/enable_dump_collection
        else
          echo "0" > /sys/module/qcom_ramdump/parameters/enable_dump_collection
        fi
      fi
    done
}

function sagami_murray_lena_init
{
    local ssr_str="$1"
    typeset -a ssr_array
    ssr_array=($ssr_str)
    typeset -i i=0
    local subsys=`cat /sys/bus/msm_subsys/devices/subsys$i/name`
    while [ "$subsys" != "" ]
    do
       for num in "${!ssr_array[@]}"
       do
          if [ "$subsys" == ${ssr_array[$num]} ]; then
            echo "RELATED" > /sys/bus/msm_subsys/devices/subsys$i/restart_level
            break 1
          else
            echo "SYSTEM" > /sys/bus/msm_subsys/devices/subsys$i/restart_level
          fi
       done

       # SONY: ONLY_IN_DEBUG change modem wdog bite behavior to system crash
       if [ "$build_variant" != "user" ] && [ "$subsys" == "modem" ]; then
         echo "set" > /sys/bus/msm_subsys/devices/subsys$i/system_debug
       fi
       i=$i+1
       subsys=`cat /sys/bus/msm_subsys/devices/subsys$i/name`
    done
}
build_variant=`getprop ro.build.type`
prod_id=$(getprop ro.vendor.build.fingerprint)

case $prod_id in
    Sony/pdx214*|Sony/pdx215*|Sony/pdx217*|Sony/pdx225*|Sony/pdx213*)
        ssr_list="venus adsp slpi cdsp modem evass wlan"
        if [ "$build_variant" != "user" ]; then
            ssr_list="venus adsp slpi modem wlan"
        fi
        sagami_murray_lena_init "$ssr_list"
    ;;
    Sony/pdx223*|Sony/pdx224*)
        ssr_list="adsp cdsp slpi mss wlan"
        if [ "$build_variant" != "user" ]; then
            ssr_list="adsp slpi mss wlan"
        fi
        nagara_init "$ssr_list"
    ;;
    *)
        log -p e -t SSR_DUMPER "invalid product $prod_id"
    ;;
esac
