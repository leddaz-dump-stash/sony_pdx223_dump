#!/system/bin/sh
# Copyright (c) 2013-2016 Sony Mobile Communications Inc.

# idd data is less than 10k.
max=8000
src_dir=$1
dst_dir=$2
dd=/system/bin/dd
ls=/system/bin/ls
rm=/system/bin/rm
mkdir=/system/bin/mkdir
tune2fs=/system/bin/tune2fs
chmod=/system/bin/chmod
wc=/system/bin/wc

bootdevice=`getprop ro.boot.bootdevice`

$mkdir -p $dst_dir
for i in `$ls $src_dir`; do
    len=`$wc -c < $src_dir/$i`

    if [ $len -ge 1 ]; then
        echo "SONY-idd-new-record\n" >> $dst_dir/$i
        $tune2fs -l /dev/block/platform/soc/$bootdevice/by-name/$i >> $dst_dir/$i 2> /dev/null
        echo "SONY-idd: Len:$len" >> $dst_dir/$i

        if [ $len -ge $max ]; then
            $dd if=$src_dir/$i bs=1 skip=$(($len - $max)) >> $dst_dir/$i 2> /dev/null
        else
            $dd if=$src_dir/$i bs=$max >> $dst_dir/$i 2> /dev/null
        fi
    fi
    $chmod -R 666 $dst_dir/$i
    $rm $src_dir/$i
done
