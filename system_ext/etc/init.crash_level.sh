#!/system/bin/sh
# Copyright (c) 2017 Sony Mobile Communications Inc.
# Set the crashlevel only if it was not set previously
crashlevel=`getprop persist.sys.semc.crashlevel`

if [ "$crashlevel" == "" ] ; then
   `setprop persist.sys.semc.crashlevel -1`
fi
