#!/system/bin/sh

# Copyright (C) 2016 Sony Mobile Communications Inc.

src_dir=/mnt/rdlog/crashdump
sdcard=/sdcard
target_dir=${sdcard}/CrashDump
partial_tlcore_dir=/data/crashdata
postdumper=/system_ext/bin/post_dumper

variant=`getprop ro.build.type`

get_latest_index()
{
    idx=0
    while [ -e $partial_tlcore_dir/$@$idx ]
    do
        idx=$((idx + 1))
    done

    if [ $idx -ge 10 ]; then
        latest_file=$(ls -t $partial_tlcore_dir | grep -E $@ | head -1)
        idx=${latest_file##*\_}
        idx=$(((idx + 1) % 10))
    fi

    return $idx
}

function check_avail_space()
{
    local src="$1"
    local dst="$2"
    # extra space required in 1024 byte unit
    integer reserve_size=512000
    # size of source in 1024 byte unit
    integer src_size=$(du -sk "${src}"|cut -f1)
    # block size of target filesystem in 1024 byte unit
    integer target_bsize=$(($(stat -f --format="%S/1024" "${dst}")))
    # available size of target filesystem in 1024 byte unit
    integer target_asize=$(($(stat -f --format="%a*${target_bsize}" "${dst}")))
    if [ $((${target_asize}-${reserve_size})) -gt $src_size ]; then
        return 0
    else
        log -p w -t postdump "Avail space failed, need ${src_size}+${reserve_size}KB but only ${target_asize}KB available"
        return 1
    fi
}

move_tlcore_system_to_crashdata()
{
    typeset -i num=0
    for s_file in $(ls $@) ; do
        idx=0
        #check any partial tlcore of system dump is present
        if [ "$(ls ${partial_tlcore_dir} | grep -E "tlcore_system_0")" ]; then
            get_latest_index "tlcore_system_0"
            idx=$?
        fi
        echo "Moving $@/$s_file to $partial_tlcore_dir/tlcore_system_0$idx\n"
        cp -a $@/$s_file $partial_tlcore_dir/tlcore_system_0$idx
        chown system:vendor_crashdump $partial_tlcore_dir/tlcore_system_0$idx

        if [ $? -eq 0 ] ; then
            rm -r $@/$s_file
        fi
    done
}

move_to_crashdump()
{
    arg=$@
    is_exists=0
    idx=0
    # Rename/move system crash <dumpdir> as <dumpdir_x> incase
    # if already exists in <target_dir> path
    # i.e. <dumpdir_x> can be <dumpdir_1>, <dumpdir_2>..and goes on.
    arg_dir=${arg%_*}
    dir=$arg_dir
    if [ "$(echo $dir | grep -E "crash-")" ]; then
        while [ -e $target_dir/$dir ] && [ ! -e $src_dir/$@/copy.fail ]
        do
            idx=$((idx + 1))
            dir=${arg_dir}_$idx
            is_exists=1
        done
        touch $src_dir/$@/copy.fail
        #Update the dumpstate file if dump is interrupted
        if [ -e $src_dir/$@/dumpstate ]; then
            mv $src_dir/$@/dumpstate $src_dir/$@/dumpstate.fail
        fi
    fi
    if [ -e $src_dir/$@/copy.fail ]; then
        rm -r $target_dir/$dir
    fi
    #Moving from /data/crashdump to /data/media/0/CrashDump
    cp -a $src_dir/$@ $target_dir/$dir
    if [ $? -eq 0 ] ; then
        sync
        rm -r $src_dir/$@
        rm -r $target_dir/$dir/copy.fail
    fi
    if [ $is_exists = 1 ]; then
        echo $target_dir/$dir > $src_dir/lastdump
    fi
    echo "$dir"
}

if [ "$variant" = "userdebug" ] ; then
    # At this point encrypted filesystem is accessible. But /sdcard/
    # isn't immediately available. So wait for it.
    for i in $(seq 120); do
        if [ ! -e "${sdcard}/" ] ; then
            log -p i -t postdump "waiting for ${sdcard}/, $i"
            sleep 5
        else
            break
        fi
    done
    if [ ! -e "${target_dir}" ]; then
        mkdir "${target_dir}"
    fi
    if [ -e "${target_dir}" ] && [ -e "${partial_tlcore_dir}" ]; then
        # /sdcard/CrashDump && /data/crashdata
        if [  -e "${src_dir}" ]; then
              for i in $(ls ${src_dir} | grep -E 'crash|lastdump'); do
                   if [ "$i" = "crashdata" ]; then
                       move_tlcore_system_to_crashdata "$src_dir/$i"
                   else
                       if check_avail_space "$src_dir/$i" "$target_dir"; then
                           path=$(move_to_crashdump $i)
                           if [ "$(echo $path | grep -E "crash-")" ]; then
                               dir=$path
                           fi
                       fi
                   fi
              done
        fi
        $postdumper
        for i in $(ls ${src_dir} | grep -E 'anr|dropbox|log|tombstones'); do
            echo "Deleting dump files in $src_dir/$i/\n"
            rm -r $src_dir/$i/*
        done
    fi
fi
