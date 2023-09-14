#!/system/bin/sh

# Copyright (C) 2018 Sony Mobile Communications Inc.

src_dir='/data/vendor/wifi/wlan_logs'
target_default_dir='/storage/emulated/0/logalong'
target=`getprop ro.board.platform`

command=$1

delete_files_in_directory()
{
    echo "Removing $src_dir"
    rm -rf $src_dir
}

copy_wlan_driver_logs_to_logalong_directory()
{
    target_dir=`getprop sys.wlan.driver.log.directory`
    if [ -z $target_dir ]; then
        target_dir=$target_default_dir
    fi
    echo "Copying from $src_dir to $target_dir"
    cp -a $src_dir/* $target_dir/
}

#if the start logging then delete the files in src_dir and set the property for start logging.
if [ $command -eq 1 ]; then
    delete_files_in_directory

    case "$target" in
        "kona" | "lahaina")
            setprop ctl.start vendor.cnss_diag
            mhi_log_cont='/sys/kernel/debug/ipc_logging/cnss-mhi/log_cont'
            pcie_log_cont='/sys/kernel/debug/ipc_logging/pcie0-short/log_cont'
            for i in $(seq 1 10)
            do
                if [ -d "$src_dir" ]; then
                    cat $mhi_log_cont > $src_dir/mhi_host_logs.txt &
                    cat $pcie_log_cont > $src_dir/pcie_logs.txt &
                    break
                else
                    echo "$src_dir can not be found!"
                    sleep 1
                fi
            done
            wait
            ;;
        "trinket" | "lito" | "holi" | "taro")
            setprop ctl.start vendor.cnss_diag
            ;;
        *)
            setprop ctl.start cnss_diag
            ;;
    esac
fi

#if stop then set the property to stop logging and copy the files from src_dir to target_dir
if [ $command -eq 0 ]; then
    case "$target" in
        "kona" | "lahaina")
            setprop ctl.stop vendor.cnss_diag
            pid=`ps -ef | grep -E "cat.*cnss-mhi.*log_cont|cat.*pcie0-short.*log_cont" | grep -v "grep" | awk '{print $2}'`
            for id in $pid
            do
                kill -9 $id
            done
            ;;
        "trinket" | "lito" | "holi" | "taro")
            setprop ctl.stop vendor.cnss_diag
            ;;
        *)
            setprop ctl.stop cnss_diag
            ;;
    esac

    copy_wlan_driver_logs_to_logalong_directory
fi
