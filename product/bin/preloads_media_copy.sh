#!/system/bin/sh
#
# Copyright 2021 Sony Corporation

umask 022
log -p i -t preloads_media_copy "Copying preloads from x_other"
if [ $# -eq 1 ]; then
  # Where the oem_b/system_b is mounted that contains the deletable_media dir
  mountpoint=$1
  # Handle media that shall be deletable.
  # The media files and subfolders are copied to:
  # /data/preloads/file_cache/deletable_media
  # XSS will then store the media files in Media Store database.
  # The system will automatically clean /data/preloads/file_cache
  # folder when low on storage.
  dest_dir=/data/preloads/file_cache/deletable_media
  log -p i -t preloads_media_copy "Copying from $mountpoint/deletable_media"
  for file in $(find ${mountpoint}/deletable_media -mindepth 1 -maxdepth 1); do
     log -p i -t preloads_media_copy "cp -r '$file' '$dest_dir'"
     cp -r $file $dest_dir
  done
  log -p i -t preloads_media_copy "Copying complete"
  exit 0
else
  log -p e -t preloads_media_copy "Usage: preloads_media_copy.sh <system_other-mount-point>"
  exit 1
fi
