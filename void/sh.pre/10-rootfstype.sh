#!/bin/sh

# choose the filesystem for /
case "${root_fs:-$(chmenu 'Which filesystem would you like to use for the system root (/)?' 'ext4' 'ext3' 'ext2' 'f2fs' 'btrfs' 'xfs')}" in
    ext[234]|f2fs|btrfs|xfs) ;;
                          *) printf "${0##*/}: error: invalid operand $root_fs for option root_fs\n"; exit 1 ;;
esac
