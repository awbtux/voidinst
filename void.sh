#!/bin/sh

# vi: ts=4 sw=4 sts=4 et


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
test "${arch%%-musl}" = "x86_64" && grub_target="$(test -d /sys/firmware/efi/efivars && printf "x86_64-efi" || printf "i386-pc")"
test "${arch%%-musl}" = "i686" && grub_target="$(test -d /sys/firmware/efi/efivars && printf "i386-efi" || printf "i386-pc")"

# name of the boot device entry on EFI; leave blank or set it to "Void Linux" and the script will manage it automatically
efi_entry_name="Void Linux"

# names of partitions/filesystems
bios_partition_name="voidmbr"
efi_partition_name="voidefi"
swap_partition_name="voidswap"
root_partition_name="voidrootfs" # name for unencrypted main partition
efi_fat32_label="VOIDEFI"
lvm_main_vol_name="rootfs"

# basenames of luks/lvm stuff; these get salted to prevent name collisions
luks_vgroup_basename="void"
luks_container_basename="voidlvm"

# root filesystem type: can be ext4, ext3, ext2, f2fs, btrfs, xfs
filesystem="f2fs"

# mkfs.$filesystem options for root
mkfs_opts="-l '$root_partition_name'"

# root user's shell
root_shell="/bin/bash"

# language & glibc locale
language="en_US"

# time zone, see /usr/share/zoneinfo
timezone="America/Los_Angeles"

# printf "$hostname\n" >"$vdir/etc/hostname"
hostname="Connors-Macbook-Air"

# name of tarball to bootstrap the base system with (under `https://repo-default.voidlinux.org/live/current/`)
tarball="void-$arch-ROOTFS-20240314.tar.xz"

# repository mirror
mirror="repo-fastly.voidlinux.org"

# set to 'y' to keep the downloaded tarball after the install finishes
keep_cache="y"

# set to 'n' to disable warnings and confirmations
warn=""

# generally useful system packages
add_pkg "acpid cryptsetup dracut dhcpcd efibootmgr ethtool eudev grub grub-x86_64-efi kmod lvm2 lz4 opendoas openssl psmisc tree usbutils void-repo-nonfree wifi-firmware wpa_supplicant xz"

# we don't need these
del_pkg "base-container-full sudo"

# base user groups
add_ugrp wheel tty disk lp audio video cdrom optical storage network input users

# choose your kernel version
add_pkg "linux5.4"

# needed for proprietary nvidia and likely a few other things
#add_pkg "linux5.4-headers"

# firmware packages, uncomment the ones you want
add_pkg "linux-firmware-intel"
#add_pkg "linux-firmware-amd"
#add_pkg "linux-firmware-nvidia"
add_pkg "linux-firmware-network"

# dev packages, uncomment if you want them
add_pkg "base-devel ncurses-devel openssl-devel zlib-devel bc patch git github-cli"

# leave uncommented if not using something else
add_sv "wpa_supplicant dhcpcd"

# network manager, uncomment if you want it
#add_pkg "NetworkManager"; add_sv "NetworkManager"

# java runtimes, uncomment if you want them (you probably don't)
#add_pkg "openjdk8-jre openjdk11-jre openjdk17-jre openjdk21-jre"

# minecraft launcher, uncomment if you want it (java is required)
#add_pkg "PrismLauncher"

# dbus, uncomment if you want it; needed for bluetooth, pipewire/pulseaudio, and many graphical programs
#add_pkg "dbus"; add_sv "dbus"

# bluetooth, uncomment if you want it
#add_pkg "bluez bluetuith"; add_sv "bluetoothd"; add_ugrp "bluetooth"

# alsa audio, uncomment if you want it
add_pkg "alsa-utils alsa-plugins apulse libspa-alsa alsaequal"; add_sv "alsa"; test "$PACKAGES" != "${PACKAGES##*bluez*}" && add_pkg "bluez-alsa"

# pipewire audio, uncomment if you want it
#add_pkg "wireplumber pipewire alsa-pipewire"; test "$PACKAGES" != "${PACKAGES##*bluez*}" && add_pkg "libspa-bluetooth"

# pulseaudio, uncomment if you want it
#add_pkg "pulseaudio alsa-plugins-pulseaudio"

# sndio audio, uncomment if you want it
#add_pkg "sndio aucatctl"; add_sv "sndiod"

# printer support, uncomment if you want it
#add_pkg "cups"; add_sv "cupsd"; add_ugrp "lpadmin"

# printer drivers, select the ones you want
# "hplip": hp printers
# "gutenprint": OSS canon, epson, lexmark, sony, olympus, and PCL printers
# "cnijfilter2": (nonfree) canon PIXMA/MAXIFY printers
# "foomatic-db": OpenPrinting printer database (brother printers, mainly)
# "cups-filters": IPP everywhere network printers
# "brother-brlaser": brother laser printers
# "foomatic-db-nonfree": nonfree OpenPrinting printer database (brother printers, mainly)
# "epson-inkjet-printer-escpr": epson inkjet printer drivers
#add_pkg "cups-filters gutenprint brother-brlaser"

# network printer autoconfiguration, among other things
#add_pkg "avahi nss-mdns"; add_sv "avahi-daemon"

# wayland display server, uncomment if you want it
add_pkg "wayland seatd wlroots wlroots-devel way-displays wlr-randr wl-clipboard xdg-utils mesa-dri vulkan-loader"; add_ugrp "_seatd"; add_sv "seatd"

# x11 display server, uncomment if you want it
#add_pkg "xdg-utils mesa-dri vulkan-loader xbacklight xclip xdpyinfo xinit xinput xkbutils xprop xrandr xrdb xset xsetroot xf86-input-evdev xf86-input-libinput xf86-input-synaptics libX11 libXft libXcursor libXinerama libX11-devel libXft-devel libXinerama-devel libXcursor-devel xorg-server"

# wayland & x11 display servers, uncomment if you want them
#add_pkg "wayland seatd wlroots wlroots-devel way-displays wl-clipboard wlr-randr xdg-utils mesa-dri vulkan-loader xbacklight xclip xdpyinfo xinit xinput xkbutils xprop xrandr xrdb xset xsetroot xf86-input-evdev xf86-input-libinput xf86-input-synaptics libX11 libXft libXcursor libXinerama libX11-devel libXft-devel libXinerama-devel libXcursor-devel xorg-server xorg-server-xwayland"; add_ugrp "_seatd"; add_sv "seatd"

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

# firefox web browser, uncomment if you want it; this gets its own line because of how bloated it is
add_pkg "firefox"

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
error() { exit_signal; printf "%s: error: %s\n" "$0" "$1" >&2; exit ${2:-1}; }

# check whether a directory is empty
is_empty() { for mty in "$1"/*; do test -e "$mty" && return 1; done; return 0; }

# get properties from block devices
blk_size() { test -r "/sys/block/${1##*/}/size" && while IFS= read -r line; do printf "%s" "$line"; done <"/sys/block/${1##*/}/size"; }
blk_model() { test -r "/sys/block/${1##*/}/device/model" && while IFS= read -r line; do printf "%s" "$line"; done <"/sys/block/${1##*/}/device/model"; }
blk_vendor() { test -r "/sys/block/${1##*/}/device/vendor" && while IFS= read -r line; do printf "%s" "$line"; done <"/sys/block/${1##*/}/device/vendor"; }
blk_uuid() { for blk in /dev/disk/by-uuid/*; do case "$(readlink -f "$blk")" in /dev/"${1##*/}"|"$1") printf "${blk##*/}"; return 0; esac; done; return 1; }

# command handlers
require() { for rcmd in "$@"; do command -v "$rcmd" >/dev/null 2>&1 && continue; error "$rcmd: command not found" 127; done; return 0; }
run() { require "$1" && cmd="$1" && shift; printf "\033[90m\$\033[39;3m %s %s\033[0m\n" "$cmd" "$*" >&2; "$cmd" "$@" || test "$nobreak" = "y" || error "command \`$cmd $*\` returned code $?"; case "$cmd" in mount|swapon) in_progress="y" ;; esac; }

# implement missing commands
command -v seq >/dev/null 2>&1 || seq() { from="$1"; while test "$from" -le "$2"; do printf "$from "; from="$((from+1))"; done; }
command -v yes >/dev/null 2>&1 || yes() { while :;do printf "%s\n" "${1:-y}";done; }
command -v unset >/dev/null 2>&1 || eval 'unset() { for _k in "$@"; do eval "$_k="; eval "$_k() { return 127; }"; done; _k=""; }'

# prompt the user for an option and optionally provide the default
chopt() { test ! -t 0 && printf "%s: error: stdin must be a terminal\n" "${0##*/}" >&2 && exit 4printf "\033[1m%s\033[22m%s " "$1" "${2:+ [ENTER=$2]}" >&2; read userch; test -n "$userch" && printf "$userch" && printf "\033[1F\033[0J" >&2 && return; test -n "$2" && printf "\033[1F\033[0J" >&2 && printf "$2"; }

# create a menu
chmenu() {
    test ! -t 0 && printf "%s: error: chmenu: stdin must be a terminal\n" "${0##*/}" >&2 && exit 4
    printf "\033[1m$1\033[22m\n" >&2; linec="$(printf "$1\n" | wc -l 2>/dev/null || printf "1")"; shift
    itmc="$#"; linec="$(($#+linec))"; for itm in "$@"; do itmc="$((itmc-1))"; printf "\033[1m[\033[36m%s\033[39m]\033[22m %s\n" "$(($#-itmc))" "$itm" >&2; done
    while true; do printf "\033[1mEnter your choice [\033[36m1\033[39m-\033[36m$#\033[39m]\033[22m " >&2; linec="$((linec+1))"; read inum; test "$inum" -gt "0" -a "$inum" -le "$#" >&- 2>&- && break; done
    printf "\033[${linec}F\033[0J" >&2; eval "printf \"$(test "$nummode" = "y" || printf '$')$inum\""
}

# only used for 1 thing...
trim_ws() { command -v sed >/dev/null 2>&1 && (sed -e 's/^\s*//g' -e 's/\s*$//g';:) && return 0; while IFS= read -r line; do printf "%s\n" "$line"; done; }

# user creation
mkuser() {
    test "$(chmenu "Do you want to add a$(test "$userct" -gt 0 2>/dev/null && printf "nother") user?" "yes" "no")" = "no" && return 1
    test "$(test "$userct" -gt 0 2>/dev/null; printf "$?")" -gt 1 2>/dev/null && userct="0"; userct="$((userct+1))"
    eval 'user_'"$userct"'_name="$(chopt "What should the new user'"'"'s name be?" "user")"'
    eval 'user_'"$userct"'_comment="$(chopt "What should $user_'"$userct"'_name'"'"'s full name be?" "Default User")"'
    while true; do
        stty -echo 2>/dev/null
        eval 'user_'"$userct"'_password="$(chopt "What should the password for $user_'"$userct"'_name be?" "1234")"'
        printf "\n\033[1mConfirm password:\033[0m "
        eval 'read user_'"$userct"'_pwconfirm'
        stty echo 2>/dev/null
        eval 'test "$user_'"$userct"'_password" != "$user_'"$userct"'_pwconfirm"' && printf "\033[1F\033[0Jerror: Passwords do not match\n" && ((sleep 1.5 || return 0; printf "\0337\033[s\033[1F\033[2K\0338\033[u") &) && continue
        eval 'test -z "$user_'"$userct"'_password" -o -z "$user_'"$userct"'_pwconfirm"' && printf "\033[1F\033[0Jerror: Password cannot be blank\n" && ((sleep 1.5 || return 0; printf "\0337\033[s\033[1F\033[2K\0338\033[u") &) && continue
        printf "\n"
        break
    done
    printf "\033[1F\033[0J" >&2
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
    done && test "$pkgm" != "${pkgm##${pkgm%%;*};}" && eval "${pkgm%%;*};:" && pkgm="${pkgm##${pkgm%%;*};}"; eval "$pkgm"' "$@"'
}

# partition the disk
provision_fdisk() {
    test ! -d "/sys/firmware/efi/efivars" && fdiskcmd="g\nn\n1\n\n+1M\nt\n4\nx\n\n$bios_partition_name\nA\nr\n" && biospart="1" && efipart="" && mainpart="2"
    test -d "/sys/firmware/efi/efivars" && fdiskcmd="g\nn\n1\n\n+128M\nt\n1\nx\nn\n$efi_partition_name\nr\n" && biospart="" && efipart="1" && mainpart="2"
    test "$both_efi_bios" = "y" && fdiskcmd="g\nn\n1\n\n+1M\nn\n2\n\n+128M\nt\n1\n4\nt\n2\n1\nx\nn\n1\n$bios_partition_name\nn\n2\n$efi_partition_name\nA\n1\nr\n" && biospart="1" && efipart="2" && mainpart="3"
    test "$is_swap" = "y" && swappart="2" && mainpart="3"
    test "$is_swap" = "y" -a "$efipart" = "2" && swappart="3" && mainpart="4"
    test "$is_swap" = "y" && fdiskcmd="${fdiskcmd}n\n${swappart}\n\n+${swap_mb}M\nt\n${swappart}\n19\nx\nn\n${swappart}\n$swap_partition_name\nr\n"
    test "$is_crypt" = "y" && parttype="44" && partname="$luks_container_basename" || ! parttype="20" || partname="$root_partition_name"
    printf "${fdiskcmd}n\n${mainpart}\n\n\nt\n${mainpart}\n${parttype}\nx\nn\n${mainpart}\n${partname}\nr\nw\n" | run fdisk -w always -W always "$disk"
    while test ! -r "${partprefix:=$(printf "$disk"*1)}"; do partprefix="$(printf "$disk"*1)"; done; partprefix="${partprefix%1}"
}

# write an fstab
write_fstab() {
    printf "%s\t%s\t%s\t%s\t%s\t%s\n" "tmpfs" "/tmp" "tmpfs" "defaults,nosuid,nodev" "0" "0"
    test -n "$efipart" && printf "UUID=%s\t%s\t%s\t%s\t%s\t%s\n" "$(blk_uuid "${partprefix}${efipart}")" "/boot/efi" "vfat" "defaults,relatime,lazytime,quiet,discard" "0" "0"
    test -n "$swappart" && printf "UUID=%s\t%s\t%s\t%s\t%s\t%s\n" "$(blk_uuid "${partprefix}${swappart}")" "swap" "swap" "defaults" "0" "0"
    test "$is_crypt" = "y" && printf "%s\t%s\t%s\t%s\t%s\t%s\n" "/dev/$luks_vgroup_name/$lvm_main_vol_name" "/" "$filesystem" "defaults,relatime,lazytime,discard" "0" "0"
    test "$is_crypt" != "y" && printf "UUID=%s\t%s\t%s\t%s\t%s\t%s\n" "$(blk_uuid "${partprefix}${mainpart}")" "/" "$filesystem" "defaults,relatime,lazytime,discard" "0" "0"
    return 0
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

# get/compare/format timestamps
get_timestamp() { test "$(date +%N)" = "%N" && printf "%d" "$(date +%s)" && return; printf "%1.3f" "$(date +%s.%N)"; }
diff_timestamp() { awk -v a="${1:-0}" -v b="${2:-0}" 'BEGIN{print b - a; exit}'; }
fmt_timestamp() {
    sec="${1%%.*}"; ms="${1##$sec}"; day="$((sec / 86400))"; sec="$((sec % 86400))"; hr="$((sec / 3600))"; sec="$((sec % 3600))"; min="$((sec / 60))"; sec="$((sec % 60))"; sec="$sec$ms"
    printf "$(test "$day" -gt 0 && printf "%%d%%s%%s%%s")" "$day" "$(test "$time_fmt" = "s" && printf "d" || printf " day")" "$(test "$day" != "1" -a "$time_fmt" != "s" && printf "s")" "$(test "$hr" = "0" -a "$min" = "0" -a "$sec" = "0" || printf ", ")"
    printf "$(test "$hr" -gt 0 && printf "%%d%%s%%s%%s")" "$hr" "$(test "$time_fmt" = "s" && printf "h" || printf " hour")" "$(test "$hr" != "1" -a "$time_fmt" != "s" && printf "s")" "$(test "$min" = "0" -a "$sec" = "0" || printf ", ")"
    printf "$(test "$min" -gt 0 && printf "%%d%%s%%s%%s")" "$min" "$(test "$time_fmt" = "s" && printf "h" || printf " minute")" "$(test "$min" != "1" -a "$time_fmt" != "s" && printf "s")" "$(test "$sec" = "0" -a "$sec" = "0" || printf ", ")"
    printf "$(test "$sec" != "0" && printf "%%s%%s%%s")" "$sec" "$(test "$time_fmt" = "s" -o "${sec%%.*}" = "0" && printf "s" || printf " second")" "$(test "$sec" != "1" -a "$sec" != "1.000" -a "${sec%%.*}" != "0" -a "$time_fmt" != "s" && printf "s")"
}

# used when the script exits by error/completion/pkill
exit_signal() {
    trap '' EXIT
    stty echo 2>/dev/null
    test "$in_progress" != "y" && return
    run cd "$scriptdir"
    while ! is_empty "$vdir/dev"; do (run umount -R "$vdir/dev"); done
    while ! is_empty "$vdir/sys"; do (run umount -R "$vdir/sys"); done
    while ! is_empty "$vdir/run"; do (run umount -R "$vdir/run"); done
    while ! is_empty "$vdir/proc"; do (run umount -R "$vdir/proc"); done
    while ! is_empty "$vdir"; do (run umount -R "$vdir"); done
    in_progress=""
    test -e "/dev/$luks_vgroup_name/$lvm_main_vol_name" && in_progress="y" && (run lvchange -an "/dev/$luks_vgroup_name/$lvm_main_vol_name") && in_progress=""
    test -e "/dev/mapper/$luks_container_name" && in_progress="y" && (run cryptsetup -q luksClose "/dev/mapper/$luks_container_name") && in_progress=""
    test "$in_progress" = "y" && printf "\033[1;33mWarning\033[39m:\033[22m %s was not freed cleanly and might still be in use.\n" "$disk"
}


# Step 2: set up the environment
# ------------------------------------------------------------------------------

# we need these
require awk mkdir

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

# salt container/logical volume names to prevent name collisions
luks_container_name="${luks_container_basename}.$(tr -dc 0-9 </dev/urandom 2>/dev/null | head -c3 2>/dev/null || printf "$((${$##${$%%?}}*($(date +10%-S 2>/dev/null || printf "${$%%${$##?}}${$##${$%%?}}"))))")"
luks_vgroup_name="${luks_vgroup_basename}.$(tr -dc 0-9 </dev/urandom 2>/dev/null | head -c3 2>/dev/null || printf "$((${$##${$%%?}}*($(date +10%-S 2>/dev/null || printf "${$%%${$##?}}${$##${$%%?}}"))))")"

# create dirs
test ! -d "$vdir" && ! mkdir -p "$vdir" && exit 1
test ! -d "$scriptdir/cache" && ! mkdir -p "$scriptdir/cache" && exit 1

# trap these signals
for sig in HUP QUIT INT TERM ABRT KILL STOP SYS; do
    trap '{ exit_signal; printf "\n%s: recieved signal '"$sig"'\n" "$0"; exit 2; }' "$sig"
done

# when the script exits normally, the signal doesn't need to be printed
trap "exit_signal" EXIT


# Step 3: user-interactive script configuration
# ------------------------------------------------------------------------------

# we need stdin
test ! -t 0 && printf "%s: error: stdin must be a terminal\n" "${0##*/}" >&2 && exit 4

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
linec="$((diskct+1))"

# read the user's choice
while true; do
    printf "\033[1mEnter your choice [\033[36m1\033[39m-\033[36m$diskct\033[39m]\033[22m "
    linec="$((linec+1))"
    read inum
    test "$inum" -gt 0 -a "$inum" -le "$diskct" >&- 2>&- && break
done
eval "disk=\"\$disk$inum\""
printf "\033[${linec}F\033[0J"
unset inum

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

# set efi entry name
model="$(printf "$(blk_model "$disk")" | trim_ws)"
vendor="$(printf "$(blk_vendor "$disk")" | trim_ws)"
test -z "$efi_entry_name" -o "$efi_entry_name" = "Void Linux" && test -n "${vendor:+$vendor }$model" && efi_entry_name="Void Linux (on ${vendor:+$vendor }$model)"

# create as many users as desired
while mkuser; do
    continue
done

# get root password
linec="1"
while true; do
    stty -echo 2>/dev/null
    printf "\033[1mWhat do you want to set as the root password?\033[22m [ENTER=%s] " "$(test -n "$user_1_password" && printf '\033[3;94m$user_1_password\033[0m' || printf "1234")"
    read root_password && root_pwconfirm=""
    test -z "$root_password" -a -n "$user_1_password" && root_password="$user_1_password" && root_pwconfirm="$root_password"
    test -z "$root_password" && root_password="1234"
    while test -z "$root_pwconfirm"; do
        printf "\033[1F\033[0J"
        printf "\n\033[1mConfirm password:\033[0m "
        read root_pwconfirm
    done
    test "$root_password" != "$root_pwconfirm" && printf "\033[1F\033[0Jerror: Passwords do not match\n" && ((sleep 1.5 || return 0; printf "\0337\033[s\033[1F\033[2K\0338\033[u") &) && continue
    stty echo 2>/dev/null
    printf "\n\033[$((linec+1))F\033[0J\n"
    break
done

# ask the user whether to proceed
test "$partmethod" != "manual" -a "$warn" != "n" && (
test "$(chmenu "Disk $disk has been selected for automatic partitioning, which will\noverwrite the current data and partition table. Do you want to continue?" "yes" "no")" != "yes" && return 0
test "$(chmenu "\033[33mFINAL WARNING\033[39m: All the contents of $disk will be \033[31mLOST\033[39m during\nautomatic partitioning. Are you SURE you want to continue?" "yes" "no")" != "yes") && printf "\033[1F\033[0Jexited\n" >&2 && exit 0

# if partitioning is being done manually
test "$partmethod" = "manual" -a "$warn" != "n" && while true; do
    manualmethod="$(nummode="y" chmenu "Disk $disk has been selected for manual partitioning. What would you like to do?" "continue (if $disk's volumes are mounted at $vdir)" "set rootfs mount location [$vdir]" "spawn a new shell and prepare $disk as needed")"
    test "$manualmethod" = "1" && break
    test "$manualmethod" = "2" && while ! vdir="$(chopt "Where is $disk's root filesystem mounted?" "$vdir")" && test -d "$vdir"; do printf "$vdir: No such file or directory\n"; done
    test "$manualmethod" = "3" && (printf "\nYou have entered a subshell spawned by ${0##*/}.\nSet up $disk's partitions and their filesystems and exit with \`exit\` or ^D.\n" >&2; eval "${SHELL:-/bin/sh}")
done

# try pinging voidlinux.org
printf "Testing network...\n"
while ! (ping -c 1 "${mirror:=repo-default.voidlinux.org}") >/dev/null 2>&1; do
    setup_net="$(nummode="y" chmenu "How would you like to set up an internet connection?" "Add a wireless network to wpa_supplicant" "Retry network config (restart runit services)" "Test connection" "Proceed without testing connection")"
    test "$setup_net" = "1" && netname="$(chopt 'What is the network name/SSID?')" && netpw="$(chopt 'What is the password? [ENTER=none]')" && (
    test -n "$netname" -a -z "$netpw" && printf "network={\n\tssid=\"$netname\"\n}\n" >>/etc/wpa_supplicant/wpa_supplicant.conf && return
    test -n "$netname" -a -n "$netpw" && wpa_passphrase "$netname" "$netpw" >>/etc/wpa_supplicant/wpa_supplicant.conf) && continue
    test "$setup_net" = "2" && (sv restart wpa_supplicant dhcpcd;:) && continue
    test "$setup_net" = "3" && continue
    test "$setup_net" = "4" && break
done

# install required utils
test "$partmethod" != "$manual" && {
    test "$is_crypt" = "y" && ! (require cryptsetup) && run pkgm "cryptsetup"
    test "$is_crypt" = "y" && ! (require lvcreate lvchange vgcreate) && run pkgm "lvm2"
    test "$efipart" != "" && ! (require mkfs.fat) && run pkgm "dosfstools"
    test "$filesystem" = "f2fs" && ! (require mkfs.f2fs) && run pkgm f2fs-tools && mkfs="has"
    test "$filesystem" = "btrfs" && ! (require mkfs.btrfs) && run pkgm btrfs-progs && mkfs="has"
    test "$filesystem" = "xfs" && ! (require mkfs.xfs) && run pkgm xfsprogs && mkfs="has"
    test "$filesystem" = "ext2" && ! (require mkfs.ext2) && run pkgm e2fsprogs && mkfs="has"
    test "$filesystem" = "ext3" && ! (require mkfs.ext3) && run pkgm e2fsprogs && mkfs="has"
    test "$filesystem" = "ext4" && ! (require mkfs.ext4) && run pkgm e2fsprogs && mkfs="has"
    test "$mkfs" != "has" && require "mkfs.$filesystem"
}
(require xz) || run pkgm "xz"
(require wget) || test -d "$scriptdir/cache/$tarball" || run pkgm "wget"
(require mount umount mkswap swapon swapoff fdisk) || run pkgm "util-linux"
(require tar) || run pkgm "tar"
(require sort cp chroot mkdir readlink head tr rm sleep) || run pkgm "coreutils"
(require awk) || run pkgm "gawk"
(require sed) || pkgm "sed"


# Step 4: partition the disk
# ------------------------------------------------------------------------------

# get starting time
install_time_start="$(get_timestamp)"

# if partitioning is done automatically
test "$partmethod" != "manual" && {
    # set up the disk
    while ! prep_disk "$disk"; do printf "accessing $disk failed. retrying in 3s...\n" >&2; sleep 3; done
    provision_fdisk "$disk"

    # create some filesystems
    test -n "$efipart" && run mkfs.fat -v -F32 -n "VOIDEFI" "${partprefix}${efipart}"
    test -n "$swappart" && run mkswap -L "$swap_partition_name" "${partprefix}${swappart}"

    # format the remaining space for full-disk encryption
    test "$is_crypt" = "y" &&
    run cryptsetup -q -v luksFormat --type luks1 "${partprefix}${mainpart}" &&
    run cryptsetup -q -v luksOpen "${partprefix}${mainpart}" "$luks_container_name" && in_progress="y" &&
    run vgcreate -v "$luks_vgroup_name" /dev/mapper/"$luks_container_name" &&
    run lvcreate -v --name "$lvm_main_vol_name" -l 100%FREE "$luks_vgroup_name" &&
    run mkfs.$filesystem $mkfs_opts "/dev/$luks_vgroup_name/$lvm_main_vol_name" &&
    run mount -v "/dev/$luks_vgroup_name/$lvm_main_vol_name" "$vdir" &&
    run mkdir -pv "$vdir/boot" &&
    (run dd if="/dev/urandom" of="$vdir/boot/volume.key" bs=128 count=1 status=progress;:) &&
    (test ! -r "$vdir/boot/volume.key" && (run head -c128 </dev/urandom >"$vdir/boot/volume.key");:) &&
    (test ! -r "$vdir/boot/volume.key" && (run od -vAn -N128 -tu1 </dev/urandom >"$vdir/boot/volume.key");:) &&
    run test -f "$vdir/boot/volume.key" && run cryptsetup -q -v luksAddKey "${partprefix}${mainpart}" "$vdir/boot/volume.key"

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

# download tarball and extract it at the new root
while true; do
    run cd "$scriptdir/cache"
    test ! -r "$tarball" && run wget -v "https://${mirror:=repo-default.voidlinux.org}/live/current/$tarball"
    run cd "$vdir"
    (run tar -xpf "$scriptdir/cache/$tarball") && break
    run rm -v "$scriptdir/cache/$tarball"
done

# xbps env vars
export XBPS_REPO="https://${mirror:=repo-default.voidlinux.org}/current""$(test -z "${arch%%*musl*}" && printf "/musl")"
export XBPS_ARCH="$arch"

# copy xbps keys
run mkdir -pv "$vdir/var/db/xbps/keys"
test -d /var/db/xbps/keys && run cp -v /var/db/xbps/keys/* "$vdir/var/db/xbps/keys/"

# use network in the chroot
test -r /etc/resolv.conf && run cp -v /etc/resolv.conf "$vdir/etc/"

# use the other mirror
for f in $(find "$vdir/usr/share/xbps.d" -type f); do
    run chroot "$vdir" sed "s/repo-default.voidlinux.org/$mirror/g" -i "${f##$vdir}"
done

# these are bloat
test -d "$vdir/etc/xbps.d" && sudo printf "ignore=linux\nignore=linux-headers\nignore=linux-base\nignore=sudo\n" >>"$vdir/etc/xbps.d/10-ignore.conf"

# update existing packages
run chroot "$vdir" xbps-install -Sfyu

# install packages
run chroot "$vdir" xbps-install -fy $PACKAGES

# install nonfree packages
test -n "$NONFREE_PACKAGES" &&
run chroot "$vdir" xbps-install -Sfy $NONFREE_PACKAGES

# remove packages
test -n "$DEL_PACKAGES" &&
run chroot "$vdir" xbps-remove -fy $DEL_PACKAGES

# configure libc locales
test -r "$vdir/etc/default/libc-locales" && run chroot "$vdir" sed "s/#$language/$language/g" -i "/etc/default/libc-locales"
run printf "LANG=$language.UTF-8\nLC_ALL=$language.UTF-8\nLC_COLLATE=C\n" >"$vdir/etc/locale.conf"

# set hostname
run printf "%s\n" "$hostname" >"$vdir/etc/hostname"

# fix broken ladspa shared lib path
test -r "$vdir/usr/lib/ladspa/caps.so" -a ! -r "$vdir/usr/lib/caps.so" && run chroot "$vdir" ln -sfv "/usr/lib/ladspa/caps.so" "/usr/lib/caps.so"

# set timezone
test -f "$vdir/usr/share/zonein${timezone:+fo/$timezone}" && run chroot "$vdir" ln -sfv "/usr/share/zoneinfo/$timezone" "/etc/localtime"

# link doas to sudo
run chroot "$vdir" sh -c 'ln -sfv $(which doas) $(dirname $(which doas))/sudo'

# copy wpa supplicant config
test -f "/etc/wpa_supplicant/wpa_supplicant.conf" -a -d "$vdir/etc/wpa_supplicant" && run cp -v /etc/wpa_supplicant/wpa_supplicant.conf "$vdir/etc/wpa_supplicant/wpa_supplicant.conf"

# root shell
run chroot "$vdir" usermod -s "$root_shell" root

# root password
printf "%s\n%s\n" "$root_password" "$root_password" | run chroot "$vdir" passwd root

# copy custom /etc overrides
test -d "$scriptdir/etc/skel" && run rm -rf "$vdir/etc/skel"
run cp -rfv "$scriptdir/etc" "$vdir"

# enable services
for srv in $SERVICES; do
    run chroot "$vdir" ln -sfv "/etc/sv/$srv" "/etc/runit/runsvdir/default/$srv"
done

# create users
for i in $(seq 1 ${userct:-0}); do
    eval 'run chroot "$vdir" useradd --badname -mG "$user_'"$i"'_groups" -s "$user_'"$i"'_shell" -c "$user_'"$i"'_comment" "$user_'"$i"'_name"'
    eval 'printf "%s\n%s\n" "$user_'"$i"'_password" "$user_'"$i"'_password" | run chroot "$vdir" passwd $user_'"$i"'_name'
done

# write the filesystem table if the script knows how to do it
test "$partmethod" != "manual" && run write_fstab >"$vdir/etc/fstab"

# configure encrypted boot setup
test "$is_crypt" = "y" &&
run chroot "$vdir" chmod -v 000 "/boot/volume.key" &&
run chroot "$vdir" chmod -vR g-rwx,o-rwx "/boot" &&
run printf "%s\tUUID=%s\t/boot/volume.key\tluks,discard\n" "$luks_vgroup_name" "$(blk_uuid "${partprefix}${mainpart}")" >>"$vdir/etc/crypttab" &&
run printf 'install_items+=" /boot/volume.key /etc/crypttab "\n' >>"$vdir/etc/dracut.conf.d/10-crypt.conf" &&
(test "$(. "$vdir/etc/default/grub"; printf "$GRUB_ENABLE_CRYPTODISK")" != "y" && run printf 'GRUB_ENABLE_CRYPTODISK="y"\n' >>"$vdir/etc/default/grub";:) &&
run printf 'GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT rd.lvm.vg=%s rd.luks.uuid=%s"\n' "$luks_vgroup_name" "$(blk_uuid "${partprefix}${mainpart}")" >>"$vdir/etc/default/grub" &&
run printf 'GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX rd.lvm.vg=%s rd.luks.uuid=%s"\n' "$luks_vgroup_name" "$(blk_uuid "${partprefix}${mainpart}")" >>"$vdir/etc/default/grub" &&

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

# get end time
install_time_end="$(get_timestamp)"


# Step 6: clean up and exit
# ------------------------------------------------------------------------------

# if everything succeeds, we probably don't need the tarball anymore
test "$keep_cache" != "y" && run rm -rf "$scriptdir/cache"

# clean up
exit_signal

# print install duration
printf "\nInstall finished (took %s)\n" "$(fmt_timestamp "$(diff_timestamp "$install_time_start" "$install_time_end")")"
