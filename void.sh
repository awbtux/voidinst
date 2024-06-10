#!/bin/sh

# vi: ts=4 sw=4 sts=4 et

# todo: macchanger


# Step 0: user config
# ------------------------------------------------------------------------------

# used below
add_sv()   { SERVICES="${SERVICES:+$SERVICES }$*"; }
add_pkg()  { PACKAGES="${PACKAGES:+$PACKAGES }$*"; }
add_pkn()  { NONFREE_PACKAGES="${NONFREE_PACKAGES:+$NONFREE_PACKAGES }$*"; }
del_pkg()  { DEL_PACKAGES="${DEL_PACKAGES:+$DEL_PACKAGES }$*"; }
add_ugrp() { for ugrp in "$@"; do GROUPS="${GROUPS:+$GROUPS,}$ugrp"; done; }

# aarch64, aarch64-musl, armv6l, armv6l-musl, armv7l, armv7l-musl, i686, x86_64, x86_64-musl
arch="x86_64"

# whether to create both a BIOS and EFI boot partition, 'y' to enable
both_efi_bios="n"

# grub target, shouldn't require intervention
test "${arch%%-musl}" = "x86_64" -o "${arch%%-musl}" = "i686" && grub_target="$(test -d /sys/firmware/efi/efivars -o "$both_efi_bios" = "y" && printf "x86_64-efi" || printf "i386-pc")"

# name of the boot device entry on EFI
efi_entry_name="Void Linux"

# root filesystem type: can be ext4, ext3, ext2, f2fs, btrfs, xfs
filesystem="f2fs"

# mkfs.$filesystem options for root
mkfs_opts='-l "voidrootfs"'

# printf "$hostname\n" >"$vdir/etc/hostname"
hostname="Connors-Macbook-Air"

# language & glibc locale
language="en_US"

# name of tarball to bootstrap the base system with (under `https://repo-default.voidlinux.org/live/current/`)
tarball="void-$arch-ROOTFS-20240314.tar.xz"

# repository mirror
mirror="repo-fastly.voidlinux.org"

# set to 'n' to disable warnings and confirmations
warn=""

# generally useful system packages
add_pkg "acpid cryptsetup dracut dhcpcd efibootmgr ethtool eudev grub grub-x86_64-efi kmod lvm2 lz4 opendoas psmisc tree usbutils void-repo-nonfree wifi-firmware wpa_supplicant xz"; add_sv "wpa_supplicant dhcpcd"

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

# java runtimes, uncomment if you want them (you probably don't)
#add_pkg "openjdk8-jre openjdk11-jre openjdk17-jre openjdk21-jre"

# minecraft launcher, uncomment if you want it (java is required)
#add_pkg "PrismLauncher"

# dbus, uncomment if you want it; needed for bluetooth, pipewire/pulseaudio, and many graphical programs
#add_pkg "dbus"; add_sv "dbus"

# bluetooth, uncomment if you want it
#add_pkg "bluez bluetuith"; add_sv "bluetoothd"; add_ugrp "bluetooth"

# alsa audio, uncomment if you want it
# TODO: copy /usr/lib/ladspa/caps.so to /usr/lib/
add_pkg "alsa-utils alsa-plugins apulse libspa-alsa alsaequal"; add_sv "alsa"; test "$PACKAGES" != "${PACKAGES##*bluez*}" && add_pkg "bluez-alsa"

# pipewire audio, uncomment if you want it
#add_pkg "wireplumber pipewire alsa-pipewire"; test "$PACKAGES" != "${PACKAGES##*bluez*}" && add_pkg "libspa-bluetooth"

# pulseaudio, uncomment if you want it
#add_pkg "pulseaudio alsa-plugins-pulseaudio"

# sndio audio, uncomment if you want it
#add_pkg "sndio aucatctl"; add_sv "sndiod"

# printer support, uncomment if you want it
add_pkg "cups"; add_sv "cupsd"; add_ugrp "lpadmin"

# printer drivers, select the ones you want
# "hplip": hp printers
# "gutenprint": OSS canon, epson, lexmark, sony, olympus, and PCL printers
# "cnijfilter2": (nonfree) canon PIXMA/MAXIFY printers
# "foomatic-db": OpenPrinting printer database (brother printers, mainly)
# "cups-filters": IPP everywhere network printers
# "brother-brlaser": brother laser printers
# "foomatic-db-nonfree": nonfree OpenPrinting printer database (brother printers, mainly)
# "epson-inkjet-printer-escpr": epson inkjet printer drivers
add_pkg "cups-filters gutenprint brother-brlaser"

# network printer autoconfiguration, among other things
#add_pkg "avahi nss-mdns"; add_sv "avahi-daemon"

# wayland display server, uncomment if you want it
add_pkg "wayland seatd wlroots wlroots-devel way-displays wl-clipboard xdg-utils mesa-dri vulkan-loader"; add_ugrp "_seatd"; add_sv "seatd"

# x11 display server, uncomment if you want it
#add_pkg "xdg-utils mesa-dri vulkan-loader xbacklight xclip xdpyinfo xinit xinput xkbutils xprop xrandr xrdb xset xsetroot xf86-input-evdev xf86-input-libinput xf86-input-synaptics libX11 libXft libXcursor libXinerama libX11-devel libXft-devel libXinerama-devel libXcursor-devel xorg-server"

# wayland & x11 display servers, uncomment if you want them
#add_pkg "wayland seatd wlroots wlroots-devel way-displays wl-clipboard xdg-utils mesa-dri vulkan-loader xbacklight xclip xdpyinfo xinit xinput xkbutils xprop xrandr xrdb xset xsetroot xf86-input-evdev xf86-input-libinput xf86-input-synaptics libX11 libXft libXcursor libXinerama libX11-devel libXft-devel libXinerama-devel libXcursor-devel xorg-server xorg-server-xwayland"; add_ugrp "_seatd"; add_sv "seatd"

# my wayland graphical environment, uncomment if you want it
add_pkg "river alacritty yambar grim"

# intel graphics drivers, uncomment if you want them
add_pkg "mesa-dri mesa-vulkan-intel intel-video-accel"

# amd graphics drivers, uncomment if you want them
#add_pkg "mesa-dri mesa-vaapi mesa-vdpau mesa-vulkan-radeon"
#add_pkg "xf86-video-amdgpu xf86-video-ati"     # <-- install if using x11, otherwise no need

# open source nvidia graphics drivers, uncomment if you want them
#add_pkg "mesa-dri mesa-vaapi mesa-vdpau mesa-nouveau-dri"
#add_pkg "xf86-video-nouveau"     # <-- install if using x11, otherwise no need

# proprietary nvidia driver, uncomment if you want it
#add_pkn "nvidia"

# `tlp` battery utility, uncomment if you want it
#add_pkg "tlp"; add_sv "tlp"

# things I use, uncomment if you want them (you should)
add_pkg "7zip bat busybox curl docx2txt elinks exiftool fbgrab fmt fzf gnupg htop lf libsixel-util ncdu neofetch neovim odt2txt pfetch pv qsv ripgrep sc-im socat tmux unzip wget wget wimlib yash zip zsh zstd"

# same as above, separated due to multimedia/display library dependencies
add_pkg "mpv ffmpeg yt-dlp fbpdf mupdf playerctl"

# my mail setup, uncomment if you want it
#add_pkg "abook notmuch neomutt"

# torrent client, uncomment if you want it
#add_pkg "transmission"

# file syncing, uncomment if you want it
#add_pkg "syncthing stc"

# network time protocol, uncomment if you want it
#add_pkg "openntpd"; add_sv "ntpd"


# Step 1: other function declarations
# ------------------------------------------------------------------------------

# dont parse printf options
alias printf="printf --"

# print an error and exit
error() { printf "%s: error: %s\n" "$0" "$1" >&2; exit ${2:-1}; }

# check whether a directory is empty
is_empty() { for mty in "$1"/*; do test -e "$mty" && return 1; done; return 0; }

# get properties from block devices
blk_size()  { test -r "/sys/block/${1##*/}/size" && while IFS= read -r line; do printf "%s" "$line"; done <"/sys/block/${1##*/}/size"; }
blk_model() { test -r "/sys/block/${1##*/}/device/model" && while IFS= read -r line; do printf "%s " "$line"; done <"/sys/block/${1##*/}/device/model"; }
blk_uuid()  { for blk in /dev/disk/by-uuid/*; do case "$(readlink -f "$blk")" in /dev/"${1##*/}"|"$1") printf "${blk##*/}"; return 0; esac; done; return 1; }

# command handlers
req_cmds() { for rcmd in "$@"; do command -v "$rcmd" >/dev/null 2>&1 || error "$rcmd: command not found" 127; done; return 0; }
run() { req_cmds "$1" && cmd="$1" && shift; printf "\033[90m\$\033[39;3m %s %s\033[0m\n" "$cmd" "$*" >&2; "$cmd" "$@" || test "$nobreak" = "y" || error "command \`$cmd $*\` returned code $?"; }

# implement missing commands
command -v seq >/dev/null 2>&1 || seq() { from="$1"; while test "$from" -le "$2"; do printf "$from "; from="$((from+1))"; done; }
command -v yes >/dev/null 2>&1 || yes() { while :;do printf "%s\n" "${1:-y}";done; }
command -v unset >/dev/null 2>&1 || eval 'unset() { for _k in "$@"; do eval "$_k="; eval "$_k() { return 127; }"; done; _k=""; }'

# prompt the user for an option and optionally provide the default
chopt() { printf "\n\033[1m%s\033[22m%s " "$1" "${2:+ [ENTER=$2]}" >&2; read userch; test -n "$userch" && printf "$userch" && return; test -n "$2" && printf "$2"; }

# create a menu
chmenu() {
    printf "\n\033[1m$1\033[22m\n" >&2; shift
    itmc="$#"; for itm in "$@"; do itmc="$((itmc-1))"; printf "\033[1m[\033[36m%s\033[39m]\033[22m %s\n" "$(($#-itmc))" "$itm" >&2; done
    while true; do printf "\033[1mEnter your choice [\033[36m1\033[39m-\033[36m$#\033[39m]\033[22m " >&2; read inum; test "$inum" -gt "0" -a "$inum" -le "$#" >&- 2>&- && break; done
    eval "printf \"$(test "$nummode" = "y" || printf '$')$inum\""
}

# user creation
mkuser() {
    test "$(chmenu "Do you want to add a$(test "$userct" -gt 0 2>/dev/null && printf "nother") user?" "yes" "no")" = "no" && return 1
    test "$(test "$userct" -gt 0 2>/dev/null; printf "$?")" -gt 1 2>/dev/null && userct="0"; userct="$((userct+1))"
    eval 'user_'"$userct"'_name="$(chopt "What should the new user'"'"'s name be?" "user")"'
    eval 'user_'"$userct"'_comment="$(chopt "What should $user_'"$userct"'_name'"'"'s full name be?" "Default User")"'
    eval 'user_'"$userct"'_password="$(chopt "What should the password for $user_'"$userct"'_name be?" "1234")"'
    eval 'user_'"$userct"'_groups="$(chopt "What groups should $user_'"$userct"'_name be in?" "$GROUPS")"'
    eval 'user_'"$userct"'_shell="$(chopt "What shell should $user_'"$userct"'_name use?" "/bin/bash")"'
    return 0
}

# package manager wrapper
pkgm() {
    test -z "$pkgm" && eval 'i=install;u=update;y=";yes";p=pkg' && for cmd in \
        "upt $u$y|upt $i" "emerge -Sq$y|emerge -q" "nix-channel -yu;nix-env -yi" "guix pull$y|guix $i" "brew $u$y|brew $i" "$p $u;$p $i -y" \
        "prt-get sync;prt-get -y $i" "slack$p $u$y|slack$p $i" "o$p $u$y|o$p $i" "eo$p $u-repo;eo$p $i -y" "cards $u;cards $i -y" "urpmi.$u -a;urpmi -a" \
        "dnf $u --refresh;dnf $i -y" "yum check-$u;yum -y $i" "zypper refresh;zypper -n $i" "apt $u;apt $i -y" "pacman -Sy$y|pacman -S" "xbps-$i -Sy" "apk $u;apk add"
    do command -v "${cmd%% *}" >/dev/null 2>&1 && pkgm="$cmd";:
    done && test "$pkgm" != "${pkgm##${pkgm%%;*};}" && eval "${pkgm%%;*};:" && pkgm="${pkgm##${pkgm%%;*};}"; eval "$pkgm \"\$@\""
}

# partition the disk
provision_disk() {
    test ! -d "/sys/firmware/efi/efivars" && fdiskcmd="g\nn\n1\n\n+1M\nt\n4\nx\n\nvoidbios\nA\nr\n" && biospart="1" && efipart="" && mainpart="2"
    test -d "/sys/firmware/efi/efivars" && fdiskcmd="g\nn\n1\n\n+128M\nt\n1\nx\nn\nvoidefi\nr\n" && biospart="" && efipart="1" && mainpart="2"
    test "$both_efi_bios" = "y" && fdiskcmd="g\nn\n1\n\n+1M\nn\n2\n\n+128M\nt\n1\n4\nt\n2\n1\nx\nn\n1\nbios_boot\nn\n2\nefi_boot\nA\n1\nr\n" && biospart="1" && efipart="2" && mainpart="3"
    test "$is_swap" = "y" && swappart="2" && mainpart="3"
    test "$is_swap" = "y" -a "$efipart" = "2" && swappart="3" && mainpart="4"
    test "$is_swap" = "y" && fdiskcmd="${fdiskcmd}n\n${swappart}\n\n+${swap_mb}M\nt\n${swappart}\n19\nx\nn\n${swappart}\nvoidswap\nr\n"
    test "$is_crypt" = "y" && parttype="44" && partname="voidlvm" || ! parttype="20" || partname="voidrootfs"
    printf "${fdiskcmd}n\n${mainpart}\n\n\nt\n${mainpart}\n${parttype}\nx\nn\n${mainpart}\n${partname}\nr\nw\n" | run fdisk -w always -W always "$disk"
    while test ! -r "${partprefix:=$(printf "$disk"*1)}"; do partprefix="$(printf "$disk"*1)"; done; partprefix="${partprefix%1}"
}

# write an fstab
write_fstab() {
    printf "%s\n" "${efipart:+UUID=$(blk_uuid "${partprefix}${efipart}") /boot/efi vfat defaults,relatime,lazytime,quiet,discard 0 0}"
    printf "%s\n" "${swappart:+UUID=$(blk_uuid "${partprefix}${swappart}") swap swap defaults,relatime,lazytime,quiet,discard 0 0}"
}

# unmount/unswap a disk and things mounted under it
prep_disk() {
    for mnt in ${1}*; do for smnt in $(grep "$mnt\s" </proc/mounts | awk '{print $2}'); do main_mounts="$smnt${main_mounts:+ $main_mounts}"; done; done
    for mnt in ${1}*; do test -n "$(grep "$mnt\s" </proc/swaps | awk '{print $1; exit}')" && main_swaps="$mnt${main_swaps:+ $main_swaps}"; done
    for mnt in $main_mounts; do for smnt in $(grep "$mnt/.*" </proc/mounts | awk '{print $2}'); do main_mounts="$smnt${main_mounts:+ $main_mounts}"; done; done
    for mnt in $main_mounts; do for smnt in $(grep "$mnt/.*" </proc/swaps | awk '{print $1}'); do main_swaps="$smnt${main_swaps:+ $main_swaps}"; done; done
    main_mounts="$(for mnt in $main_mounts; do printf "$mnt\n" | awk '{print length, $0}'; done | sort -run | awk '{print $2}')"
    main_swaps="$(for mnt in $main_swaps; do printf "$mnt\n" | awk '{print length, $0}'; done | sort -run | awk '{print $2}')"
    test -n "$main_swaps" && for mnt in $main_swaps; do nobreak="y" run swapoff -v "$mnt" || return 1; done
    test -n "$main_mounts" && for mnt in $main_mounts; do nobreak="y" run umount -vR "$mnt" || return 1; done
    return 0
}


# Step 2: set up the environment
# ------------------------------------------------------------------------------

# we need these
req_cmds awk mkdir

# cd to the directory of the script
IFS="/"
test -z "${0%%/*}" && cd /
for argp in $0; do
    test -d "$argp" && cd "$argp"
done
scriptdir="$PWD"
IFS="$(printf " \n\t")"

# check if we have root permissions for the install
test "${EUID:-${UID:-$(id -u 2>/dev/null)}}" != "0" && (error "Operation not permitted" 0) && test "$warn" != "n" && exit 1

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
test ! -d "$vdir" && ! mkdir -p "$vdir" && exit 1
test ! -d "$scriptdir/cache" && ! mkdir -p "$scriptdir/cache" && exit 1

# trap these signals
for sig in HUP QUIT INT TERM ABRT KILL STOP SYS; do
    trap "{ printf \"\n%s: recieved signal $sig\n\" "$0"; exit 2; }" "$sig"
done


# Step 3: user-interactive script configuration
# ------------------------------------------------------------------------------

# menu title
printf "\n\033[1mWhich disk would you like to install to?\033[22m\n"

# list block devices: `awk` used instead of `bc` for portability, and `lsblk` isn't used at all
for dev in /sys/block/*; do
    test -d "$dev/loop" -o -L "$dev/device" || continue
    diskct="$((diskct+1))"
    eval "disk$diskct=\"/dev/${dev##*/}\""
    printf "\033[1m[\033[36m$diskct\033[39m]\033[22m /dev/${dev##*/}: %s%s\n" "$(awk -v size="$(($(blk_size "${dev##*/}")/2))" 'BEGIN { split("K M G T P E Z", units); for(i=1; size>=1024 && i<=6; i++) { size/=1024 }; printf "%1.1f%s ", size, units[i] }')" "$(blk_model "${dev%%*/}")"
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

# for my personal safety
test "$disk" = "/dev/nvme0n1" -o "$disk" = "/dev/sda" -o "$disk" = "/dev/sdb" && error "won't overwrite primary disk" 1

# decide how to partition $disk
partmethod="$(nummode="y" chmenu "Which provisioning scheme would you like to use on $disk?" "Full-disk encryption (automatic)" "No encryption (automatic)" "Swap space, full-disk encryption (automatic)" "Swap space, no encryption (automatic)" "Manual partitioning")"
test "$partmethod" = "2" && partmethod="auto"
test "$partmethod" = "1" && partmethod="crypt-auto" && is_crypt="y"
test "$partmethod" = "4" && partmethod="swap-auto" && is_swap="y"
test "$partmethod" = "3" && partmethod="crypt-swap-auto" && is_crypt="y" && is_swap="y"
test "$partmethod" = "5" && partmethod="manual"

# require swap commands and get size
test "$is_swap" = "y" && while true; do
    swap_mb="$(chopt "How much swap space should be reserved (MiB)?" "1024")"; test "$swap_mb" -gt 0 >&- 2>&- && break
done

# create as many users as desired
while mkuser; do
    continue
done

# get root password
root_password="$(chopt "What do you want to set as the root password?" "${user_1_password:-1234}")"

# get root shell
root_shell="$(chopt "What do you want to set as the root shell?" "${user_1_shell:-/bin/bash}")"

# ask the user whether to proceed
test "$partmethod" != "manual" -a "$warn" != "n" && (
test "$(chmenu "Disk $disk selected for automatic partitioning, which will overwrite the\ncurrent data and partition table. Do you want to continue?" "yes" "no")" != "yes" && return 0
test "$(chmenu "\033[33mFINAL WARNING\033[39m: All the contents of $disk will be \033[31mLOST\033[39m during\nautomatic partitioning. Are you SURE you want to continue?" "yes" "no")" != "yes") && printf "exited\n" >&2 && exit 0

# if partitioning is being done manually
test "$partmethod" = "manual" -a "$warn" != "n" && while true; do
    manualmethod="$(nummode="y" chmenu "Disk $disk selected for manual partitioning. What would you like to do?" "continue (if $disk's volumes are mounted at $vdir)" "set rootfs mount location [$vdir]" "spawn a new shell and prepare $disk as needed")"
    test "$manualmethod" = "1" && break
    test "$manualmethod" = "2" && while ! vdir="$(chopt "Where is $disk's root filesystem mounted?" "$vdir")" && test -d "$vdir"; do printf "$vdir: No such file or directory\n"; done
    test "$manualmethod" = "3" && (printf "\nYou have entered a subshell spawned by ${0##*/}.\nSet up $disk's partitions and their filesystems and exit with \`exit\` or ^D.\n" >&2; eval "${SHELL:-/bin/sh}")
done

# try pinging voidlinux.org
printf "Testing network...\n"
while ! ping -c 1 "${mirror:=repo-default.voidlinux.org}" >/dev/null 2>&1; do
    setup_net="$(nummode="y" chmenu "How would you like to set up an internet connection?" "Add a wireless network to wpa_supplicant" "Retry network config (restart runit services)" "Test connection" "Proceed without testing connection")"
    test "$setup_net" = "1" && netname="$(chopt 'What is the network name/SSID?')" && netpw="$(chopt 'What is the password? [ENTER=none]')" && (
    test -n "$netname" -a -z "$netpw" && printf "network={\n\tssid=\"$netname\"\n}\n" >>/etc/wpa_supplicant/wpa_supplicant.conf && return
    test -n "$netname" -a -n "$netpw" && wpa_passphrase "$netname" "$netpw" >>/etc/wpa_supplicant/wpa_supplicant.conf) && continue
    test "$setup_net" = "2" && (sv restart wpa_supplicant dhcpcd;:) && continue
    test "$setup_net" = "3" && continue
    test "$setup_net" = "4" && break
done

# install required utils
(req_cmds wget) || pkgm wget
(req_cmds mount umount mkswap swapon swapoff) || pkgm util-linux
(req_cmds tar) || pkgm tar
test "$is_crypt" = "y" && ! (req_cmds cryptsetup) && pkgm cryptsetup
test "$is_crypt" = "y" && ! (req_cmds lvcreate lvchange vgcreate) && pkgm lvm2
test "$efipart" != "" && ! (req_cmds mkfs.fat) && pkgm dosfstools


# Step 4: partition the disk
# ------------------------------------------------------------------------------

# if partitioning is done automatically
test "$partmethod" != "manual" && {
    # set up the disk
    while ! prep_disk "$disk"; do printf "accessing $disk failed. retrying in 3s...\n" >&2; sleep 3; done
    provision_disk "$disk"

    # create some filesystems
    test -n "$efipart" && run mkfs.fat -v -F32 -n "VOIDEFI" "${partprefix}${efipart}"
    test -n "$swappart" && run mkswap -L "voidswap" "${partprefix}${swappart}"

    # format the remaining space for full-disk encryption
    test "$is_crypt" = "y" &&
    run cryptsetup -q -v luksFormat --type luks1 "${partprefix}${mainpart}" &&
    run cryptsetup -q -v luksOpen "${partprefix}${mainpart}" voidlvm &&
    run vgcreate -v void /dev/mapper/voidlvm &&
    run lvcreate -v --name rootfs -l 100%FREE void &&
    run mkfs.$filesystem $mkfs_opts /dev/void/rootfs &&
    run mount -v /dev/void/rootfs "$vdir"

    # create a standard root filesystem
    test "$is_crypt" != "y" &&
    run mkfs.$filesystem $mkfs_opts "${partprefix}${mainpart}" &&
    run mount -v "${partprefix}${mainpart}" "$vdir"

    # mount other filesystems
    test -n "$efipart" && run mkdir -pv "$vdir/boot/efi"
    test -n "$efipart" && run mount -v "${partprefix}${efipart}" "$vdir/boot/efi"
    test -n "$swappart" && run swapon -v "${partprefix}${swappart}"
}

# mount devices
run mkdir -pv "$vdir/dev" "$vdir/sys" "$vdir/proc" "$vdir/run"
run mount -v --rbind /dev "$vdir/dev"
run mount -v --rbind /sys "$vdir/sys"
run mount -v --rbind /proc "$vdir/proc"
run mount -v --rbind /run "$vdir/run"
run mount -v --make-rslave "$vdir/dev"
run mount -v --make-rslave "$vdir/sys"
run mount -v --make-rslave "$vdir/proc"
run mount -v --make-rslave "$vdir/run"


# Step 5: configure/install the system
# ------------------------------------------------------------------------------

# download tarball
run cd "$scriptdir/cache"
test ! -r "$tarball" && run wget -v "https://${mirror:=repo-default.voidlinux.org}/live/current/$tarball"

# extract at the new root
run cd "$vdir"
run tar -xpf "$scriptdir/cache/$tarball"

# xbps env vars
export XBPS_REPO="https://${mirror:=repo-default.voidlinux.org}/current""$(test -z "${arch%%*musl*}" && printf "/musl")"
export XBPS_ARCH="$arch"

# copy xbps keys
run mkdir -pv $VDIR/var/db/xbps/keys
run cp -v /var/db/xbps/keys/* "$vdir/var/db/xbps/keys/"

# use network in the chroot
run cp -v /etc/resolv.conf "$vdir/etc/"

# install packages
run chroot "$vdir" xbps-install -Sy $PACKAGES

# install nonfree packages
run chroot "$vdir" xbps-install -Sy $NONFREE_PACKAGES

# remove packages
run chroot "$vdir" xbps-remove -y $DEL_PACKAGES

# configure libc locales
run sed "s/#$language/$language/g" -i "$vdir/etc/default/libc-locales"
run printf "LANG=$language.UTF-8\nLC_ALL=$language.UTF-8\nLC_COLLATE=C" >"$vdir/etc/locale.conf"

# set hostname
run printf "%s\n" "$hostname" >"$vdir/etc/hostname"

# link doas to sudo
run chroot "$vdir" sh -c 'ln -sfv $(which doas) $(dirname $(which doas))/sudo'

# copy wpa supplicant config
test -f "/etc/wpa_supplicant/wpa_supplicant.conf" && run cp -v /etc/wpa_supplicant/wpa_supplicant.conf "$vdir/etc/wpa_supplicant/wpa_supplicant.conf"

# root shell
run chroot "$vdir" usermod -s "$root_shell" root

# root password
printf "$root_password\n$root_password\n" | run chroot "$vdir" passwd root

# copy user's /etc
test -d "$scriptdir/etc/skel" && run rm -rf "$vdir/etc/skel"
run cp -rfv "$scriptdir/etc" "$vdir"

# enable services
for srv in $SERVICES; do
    run chroot "$vdir" ln -sfv "/etc/sv/$srv" "/etc/runit/runsvdir/default/$srv"
done
read test

# create users
for i in $(seq 1 ${userct:-0}); do
    eval 'run chroot "$vdir" useradd -mG "$user_'"$i"'_groups" -s "$user_'"$i"'_shell" -c "$user_'"$i"'_comment" "$user_'"$i"'_name"'
    eval 'printf "$user_'"$i"'_password\n$user_'"$i"'_password\n" | run chroot "$vdir" passwd $user_'"$i"'_name'
done

# install grub
test -d "/sys/firmware/efi/efivars" && {
    eval 'run chroot "'"$vdir"'" grub-install "'"$disk"'" --target="'"$grub_target"'" --bootloader-id="'"$efi_entry_name"'" --efi-directory=/boot/efi --removable'
    eval 'run chroot "'"$vdir"'" grub-install "'"$disk"'" --target="'"$grub_target"'" --bootloader-id="'"$efi_entry_name"'" --efi-directory=/boot/efi'
} || {
    eval 'run chroot "$vdir" grub-install "$disk"'
}
run chroot "$vdir" grub-mkconfig -o /boot/grub/grub.cfg

# reconfigure packages
run chroot "$vdir" xbps-reconfigure -fa


# Step 20: clean up and exit
# ------------------------------------------------------------------------------

# cd to the script dir
run cd "$scriptdir"

# unmount pseudo-filesystems
run umount -Rv "$vdir/dev"
run umount -Rv "$vdir/sys"
run umount -Rv "$vdir/proc"
run umount -Rv "$vdir/run"

# disable swaps/mounts for $disk
prep_disk "$disk"

# cryptsetup volumes
test "$is_crypt" = "y" &&
run umount -Rv "$vdir" &&
run lvchange -van /dev/void/rootfs &&
run cryptsetup -qv luksClose /dev/mapper/voidlvm

# if everything succeeds, we probably don't need the tarball anymore
run rm -rf "$scriptdir/cache"
