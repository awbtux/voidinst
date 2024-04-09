#!/bin/sh

# vi: ts=4 sw=4 sts=4 et

# todo: macchanger

# Step 0: config
# ------------------------------------------------------------------------------

# used below
add_sv()   { SERVICES="${SERVICES:+$SERVICES }$*"; }
add_pkg()  { PACKAGES="${PACKAGES:+$PACKAGES }$*"; }
del_pkg()  { DEL_PACKAGES="${DEL_PACKAGES:+$DEL_PACKAGES }$*"; }
add_ugrp() { for _i in "$@"; do GROUPS="${GROUPS:+$GROUPS,}$_i"; done; }

# aarch64, aarch64-musl, armv6l, armv6l-musl,
# armv7l, armv7l-musl, i686, x86_64, x86_64-musl
arch="x86_64"

# whether to create both a BIOS and EFI boot partition, 'y' to enable
both_efi_bios="y"

# root filesystem type: can be ext4, ext3, ext2, f2fs, btrfs, xfs
filesystem="f2fs"

# mkfs options for root
fsopts='-L "voidrootfs"'

# printf "$hostname\n" >"$vdir/etc/hostname"
hostname="Connors-Macbook-Air"

# language & glibc locale
language="en_US"

# name of tarball to bootstrap the base system with (under `https://repo-default.voidlinux.org/live/current/`)
tarball="void-$arch-ROOTFS-20240314.tar.xz"

# set to 'n' to disable warnings and confirmations
warn=""

# generally useful system packages
add_pkg "cryptsetup xz lz4 usbutils wpa_supplicant void-repo-nonfree opendoas wifi-firmware ethtool kmod acpid eudev dracut grub grub-x86_64-efi efibootmgr tree"

# we don't need these
del_pkg "base-container-full sudo"

# base user groups
add_ugrp wheel tty disk lp audio video cdrom optical storage network input users

# choose your kernel version
add_pkg "linux5.4"

# firmware packages, uncomment the ones you want
add_pkg "linux-firmware-intel"
#add_pkg "linux-firmware-amd"
#add_pkg "linux-firmware-nvidia"
add_pkg "linux-firmware-network"

# dev packages, uncomment if you want them
add_pkg "base-devel ncurses-devel openssl-devel zlib-devel bc patch git github-cli"

# alsa audio, uncomment if you want it
add_pkg "alsa-utils"; add_sv "alsa"

# pipewire audio, uncomment if you want it
#add_pkg "wireplumber pipewire alsa-pipewire"

# pulseaudio, uncomment if you want it
#add_pkg "pulseaudio alsa-plugins-pulseaudio"

# sndio audio, uncomment if you want it
#add_pkg "sndio aucatctl"; add_sv "sndiod"

# dbus, uncomment if you want it
#add_pkg "dbus"; add_sv "dbus"

# wayland display server, uncomment if you want it
#add_pkg "wayland seatd wlroots wlroots-devel way-displays wl-clipboard xdg-utils mesa-dri vulkan-loader"; add_ugrp "_seatd"; add_sv "seatd"

# x11 display server, uncomment if you want it
#add_pkg "xdg-utils mesa-dri vulkan-loader xbacklight xclip xdpyinfo xinit xinput xkbutils xprop xrandr xrdb xset xsetroot xf86-input-evdev xf86-input-libinput xf86-input-synaptics libX11 libXft libXcursor libXinerama libX11-devel libXft-devel libXinerama-devel libXcursor-devel xorg-server"

# wayland & x11 display servers, uncomment if you want them
#add_pkg "wayland seatd wlroots wlroots-devel way-displays wl-clipboard xdg-utils mesa-dri vulkan-loader xbacklight xclip xdpyinfo xinit xinput xkbutils xprop xrandr xrdb xset xsetroot xf86-input-evdev xf86-input-libinput xf86-input-synaptics libX11 libXft libXcursor libXinerama libX11-devel libXft-devel libXinerama-devel libXcursor-devel xorg-server xorg-server-xwayland"; add_ugrp "_seatd"; add_sv "seatd"

# intel graphics drivers, uncomment if you want them
add_pkg "mesa-dri mesa-vulkan-intel intel-video-accel"

# amd graphics drivers, uncomment if you want them
#add_pkg "mesa-dri mesa-vaapi mesa-vdpau mesa-vulkan-radeon"
#add_pkg "xf86-video-amdgpu xf86-video-ati"     # <-- install if using x11, otherwise no need

# open source nvidia graphics drivers, uncomment if you want them
#add_pkg "mesa-dri mesa-vaapi mesa-vdpau mesa-nouveau-dri"
#add_pkg "xf86-video-nouveau"     # <-- install if using x11, otherwise no need

# `tlp` battery utility, uncomment if you want it
#add_pkg "tlp"; add_sv "tlp"

# things I use, uncomment if you want them (you should)
add_pkg "7zip bat bc busybox curl docx2txt elinks exiftool fbgrab fmt fzf gnupg htop lf libsixel-util ncdu neofetch neovim odt2txt patch pfetch pv qsv ripgrep sc-im socat tmux unzip wget wget wimlib zip zsh zstd"

# my mail setup, uncomment if you want it
#add_pkg "abook notmuch neomutt"

# same as above, separated due to multimedia/display library dependencies
add_pkg "mpv ffmpeg yt-dlp fbpdf mupdf playerctl"

# Step 1: function declarations
# ------------------------------------------------------------------------------

# print an error and exit
error() { printf "$0: error: $1\n" >&2; exit ${2:-1}; }

# check whether a directory is empty
is_empty() { for _i in "$1"/*; do test -e "$_i" && return 1; done; return 0; }

# get properties from block devices
blk_size()  { [ -r "/sys/block/${1##*/}/size" ] && while IFS= read -r line; do printf "$line"; done <"/sys/block/${1##*/}/size"; }
blk_model() { [ -r "/sys/block/${1##*/}/device/model" ] && while IFS= read -r line; do printf "$line "; done <"/sys/block/${1##*/}/device/model"; }
blk_uuid()  { for _i in /dev/disk/by-uuid/*; do case "$(readlink -f "$_i")" in /dev/"${1##*/}"|"$1") printf "${_i##*/}"; return 0; esac; done; return 1; }

# require a command
req_cmds() { for _i in "$@"; do command -v "$_i" >/dev/null 2>&1 || { printf "$0: error: $_i: command not found\n" >&2; exit 127; }; done; return 0; }

# implement `seq` if it doesn't exist
command -v seq >/dev/null 2>&1 || seq() { from="$1"; while [ "$from" -le "$2" ]; do printf "$from "; from="$((from+1))"; done; }

# prompt the user for an option and optionally provide the default
chopt() { printf "\n\033[1m$1\033[22m${2:+ [$2]} " >&2; read userch; test -n "$userch" && printf "$userch" && return; test -n "$2" && printf "$2"; }

# create a menu
chmenu() {
    test "$1" = "-n" && nummode="n" && shift; printf "\n\033[1m$1\033[22m\n" >&2; shift
    for i in "$@"; do itm="$((itm+1))"; eval "itm$itm=\"$i\""; done
    for i in $(seq 1 $itm); do eval "printf \"\033[1m[\033[36m$i\033[39m]\033[22m \$itm$i\n\"" >&2; done
    while true; do printf "\033[1mEnter your choice [\033[36m1\033[39m-\033[36m$i\033[39m]\033[22m " >&2; read inum; test "$inum" -gt "0" -a "$inum" -le "$itm" >&- 2>&- && break; done
    eval "printf \"${nummode:-\$itm}$inum\""; unset nummode itm
}

# unmount/unswap a disk and things mounted under it
prep_disk() {
    # find mountpoints/swaps to clean for each partition
    for i in ${1}*; do
        for j in $(grep "$i\s" </proc/mounts | awk '{print $2}'); do main_mounts="$j${main_mounts:+ $main_mounts}"; done
        test -n "$(grep "$i\s" </proc/swaps | awk '{print $1; exit}')" && main_swaps="$i${main_swaps:+ $main_swaps}"
    done

    # handle peripheral swaps/mounts
    for i in $main_mounts; do
        for j in $(grep "$i/.*" </proc/mounts | awk '{print $2}'); do main_mounts="$j${main_mounts:+ $main_mounts}"; done
        for j in $(grep "$i/.*" </proc/swaps | awk '{print $1}'); do main_swaps="$j${main_swaps:+ $main_swaps}"; done
    done

    # sort by length, remove duplicate entries (this search method inevitably adds them)
    main_mounts="$(for i in $main_mounts; do printf "$i\n" | awk '{print length, $0}'; done | sort -run | awk '{print $2}')"
    main_swaps="$(for i in $main_swaps; do printf "$i\n" | awk '{print length, $0}'; done | sort -run | awk '{print $2}')"

    # disable swaps/mounts
    test -n "$main_swaps" && for i in $main_swaps; do printf "unswap $i\n"; swapoff $i || return 1; done
    test -n "$main_mounts" && for i in $main_mounts; do printf "unmount $i\n"; umount -R $i || return 1; done
    return 0
}

# partition the disk
provision_disk() {
    # if using both efi and bios
    test "$both_efi_bios" = "y" && {
        fdiskcmd="g\nn\n1\n\n+1M\nn\n2\n\n+128M\nt\n1\n4\nt\n2\n1\nx\nn\n1\nbios_boot\nn\n2\nefi_boot\nA\n1\nr\n"; biospart="1"; efipart="2"; mainpart="3"

    # if not
    } || {
        # decide between efi and bios based on the availability of efivarfs
        [ -d "/sys/firmware/efi/efivars" ] && {
            fdiskcmd="g\nn\n1\n\n+128M\nt\n1\nx\nn\nvoidefi\nr\n"; efipart="1"
        } || {
            fdiskcmd="g\nn\n1\n\n+1M\nt\n4\nx\n\nvoidbios\nA\nr\n"; biospart="1"
        }
        mainpart="2"
    }

    # swap partition
    [ "$partmethod" = "n3" -o "$partmethod" = "n4" ] && {
        [ "$efipart" = "2" ] && {
            swappart="3"; mainpart="4"
        } || {
            swappart="2"; mainpart="3"
        }
        fdiskcmd="${fdiskcmd}n\n${swappart}\n\n+${swap_mb}M\nt\n${swappart}\n19\nx\nn\n${swappart}\nvoidswap\nr\n"
    }

    # main partition (lvm container, or normal rootfs)
    [ "$partmethod" = "n1" -o "$partmethod" = "n3" ] && {
        fdiskcmd="${fdiskcmd}n\n${mainpart}\n\n\nt\n${mainpart}\n44\nx\nn\n${mainpart}\nvoidlvm\nr\nw\n"; cryptfs="y"
    } || {
        fdiskcmd="${fdiskcmd}n\n${mainpart}\n\n\nt\n${mainpart}\n20\nx\nn\n${mainpart}\nvoidrootfs\nr\nw\n"
    }

    # run fdisk
    printf "$fdiskcmd" | fdisk -w always -W always "$disk" || error "fdisk command failed"

    # prefix for partitions
    while test ! -r "${partprefix:=$(printf "$disk"*1)}"; do
        printf "."
        partprefix="$(printf "$disk"*1)"
    done
    partprefix="${partprefix%1}"
}

# write an fstab
write_fstab() {
    printf "${efipart:+UUID=$(blk_uuid "${partprefix}${efipart}") /boot/efi vfat defaults,relatime,lazytime,quiet,discard 0 0\n}"
    printf "${swappart:+UUID=$(blk_uuid "${partprefix}${swappart}") swap swap defaults,relatime,lazytime,quiet,discard 0 0\n}"
}


# Step 2: set up the environment
# ------------------------------------------------------------------------------

# we need these
req_cmds awk mkdir

# cd to the directory of the script
_IFS="$IFS"
IFS="/"
[ -z "${0%%/*}" ] && cd /
for i in $0; do
    [ -d "$i" ] && cd "$i"
done
scriptdir="$PWD"
IFS="$_IFS"

# check if we have root permissions for the install
case "${EUID:-${UID:-$(id -u 2>/dev/null)}}" in
    0) ;;
    *) printf "$0: error: Operation not permitted\n"; test "$warn" != "n" && exit 1 ;;
esac

# new system mount dir
! is_empty "/tmp/voidinst/mnt" && {
    i="2"
    while ! is_empty "/tmp/voidinst.$i/mnt"; do
        i="$((i+1))"
    done
    vdir="/tmp/voidinst.$i/mnt"
} || {
    vdir="/tmp/voidinst/mnt"
}

# create dirs
test -d "$vdir" || mkdir -p "$vdir" || error "failed to create directory $vdir"
test -d "$scriptdir/cache" || mkdir -p "$scriptdir/cache" || error "failed to create directory $scriptdir/cache"

# trap these signals
for i in HUP QUIT INT TERM ABRT KILL STOP SYS; do
    trap "{ printf \"\n$0: recieved signal $i\n\"; exit 2; }" $i
done


# Step 3: choose the disk to be used for installation
# ------------------------------------------------------------------------------

# menu title
printf "\n\033[1mWhich disk would you like to install to?\033[22m\n"

# list block devices: `awk` used instead of `bc` for portability, and `lsblk` isn't used at all
for i in /sys/block/*; do
    test -d "$i/loop" -o -L "$i/device" || continue
    diskct="$((diskct+1))"
    eval "disk$diskct=\"/dev/${i##*/}\""
    printf "\033[1m[\033[36m$diskct\033[39m]\033[22m /dev/${i##*/}: $(awk -v size="$(($(blk_size "${i##*/}")/2))" 'BEGIN { split("K M G T P E Z", units); for(i=1; size>=1024 && i<=6; i++) { size/=1024 }; printf "%.1f%s ", size, units[i] }')$(blk_model ${i%%*/})\n"
done

# if no disks are available, exit
test -z "$disk1" && error "no devices available for installation"

# read the user's choice
while true; do
    printf "\033[1mEnter your choice [\033[36m1\033[39m-\033[36m$diskct\033[39m]\033[22m "
    read inum
    test "$inum" -gt 0 -a "$inum" -le "$diskct" >&- 2>&- && break
done
eval "disk=\"\$disk$inum\""
unset inum

echo disk = /dev/nvme1n1
disk="/dev/nvme1n1"

# decide how to partition $disk
partmethod="$(chmenu -n "Which provisioning scheme would you like to use on $disk?" "Full-disk encryption (automatic)" "No encryption (automatic)" "Swap space, full-disk encryption (automatic)" "Swap space, no encryption (automatic)" "Manual partitioning")"

# require swap commands and get size
test "$partmethod" = "n3" -o "$partmethod" = "n4" && while true; do
    swap_mb=$(chopt "How much swap space should be reserved (MiB)?" "1024"); test "$swap_mb" -gt 0 >&- 2>&- && break
done


# Step 4: establish connectivity & download tarball
# ------------------------------------------------------------------------------

# try pinging voidlinux.org
printf "Testing network...\n"
while ! ping -c 1 repo-default.voidlinux.org >/dev/null 2>&1; do
    case "$(chmenu -n "How would you like to set up an internet connection?" "Add a wireless network to wpa_supplicant" "Retry network config (restart runit services)" "Test connection" "Proceed without testing connection")" in
        n1) netname="$(chopt 'What is the network name/SSID?')"
            netpw="$(chopt 'What is the password? [ENTER=none]')"
            test -n "$netname" -a -n "$netpw" && { wpa_passphrase "$netname" "$netpw" >>/etc/wpa_supplicant/wpa_supplicant.conf; continue; }
            test -n "$netname" && printf "network={\n\tssid=\"$netname\"\n}\n" >>/etc/wpa_supplicant/wpa_supplicant.conf ;;
        n2) sv restart wpa_supplicant dhcpcd; continue ;;
        n3) continue ;;
        n4) break ;;
    esac
done


# Step 5: partition the disk
# ------------------------------------------------------------------------------

# if partitioning is being done manually
[ "$partmethod" = "n5" ] && {
    [ "$warn" != "n" ] && while true; do
        case "$(chmenu -n "Disk $disk selected for manual partitioning. What would you like to do?" "continue (if $disk has been prepared, and its volumes mounted at $vdir)" "spawn a new shell and prepare $disk as needed")" in "n1") break ;; esac
        printf "\nYou have entered a subshell spawned by ${0##*/}.\nSet up $disk's partitions and their filesystems and exit with \`exit\` or ^D.\n" >&2
        eval "$SHELL"
    done
}

# if partitioning is done automatically
[ "$partmethod" != "n5" ] && {
    # we need these
    req_cmds umount swapoff fdisk "mkfs.$filesystem"

    # warn if not disabled
    [ "$warn" != "n" ] && \
        case "$(chmenu -n "Disk $disk selected for automatic partitioning, which will overwrite the\ncurrent data and partition table. Do you want to continue?" "yes" "no")" in "n2") printf "exited\n" >&2; exit 0 ;; esac && \
        case "$(chmenu -n "\033[33mFINAL WARNING\033[39m: All the contents of $disk will be \033[31mLOST\033[39m during\nautomatic partitioning. Are you SURE you want to continue?" "yes" "no")" in "n2") printf "exited\n" >&2; exit 0 ;; esac

    # set up the disk
    while ! prep_disk "$disk"; do printf "accessing $disk failed. retrying in 3s...\n" >&2; done
    provision_disk "$disk"

    # create some filesystems
    test -n "$efipart" && ! mkfs.vfat -F32 -n "VOIDEFI" "${partprefix}${efipart}" && error "${partprefix}${efipart}: mkfs.vfat command failed"
    test -n "$swappart" && ! mkswap -L "voidswap" "${partprefix}${swappart}" && error "${partprefix}${swappart}: mkswap command failed"

    # format the remaining space for full-disk encryption
    [ "$cryptfs" = "y" ] && {
        ! cryptsetup luksFormat --type luks1 "${partprefix}${mainpart}" && error "${partprefix}${mainpart}: cryptsetup luksFormat command failed"
        ! cryptsetup luksOpen "${partprefix}${mainpart}" voidlvm && error "${partprefix}${mainpart}: cryptsetup luksOpen command failed"
        ! vgcreate void /dev/mapper/voidlvm && error "/dev/mapper/voidlvm: vgcreate command failed"
        ! lvcreate --name rootfs -l 100%FREE void && error "/dev/mapper/voidlvm: lvcreate command failed"
        ! mkfs.$filesystem $fsopts /dev/void/rootfs && error "/dev/void/rootfs: mkfs.$filesystem command failed"
        ! mount /dev/void/rootfs "$vdir" && error "/dev/void/rootfs: mount command failed"
    }

    # create a standard root filesystem
    [ "$cryptfs" != "y" ] && {
        ! mkfs.$filesystem $fsopts "${partprefix}${mainpart}" && error "${partprefix}${mainpart}: mkfs.$filesystem command failed"
        ! mount "${partprefix}${mainpart}" "$vdir" && error "${partprefix}${mainpart}: mount command failed"
    }

    # create efi dir
    test -n "$efipart" && ! mkdir -p "$vdir/boot/efi" && error "$vdir/boot/efi: error: mkdir command failed"

    # mount other filesystems
    test -n "$efipart" && ! mount "${partprefix}${efipart}" && error "${partprefix}${efipart}: mount command failed"
    test -n "$swappart" && ! swapon "${partprefix}${swappart}" && error "${partprefix}${swappart}: swapon command failed"
}
