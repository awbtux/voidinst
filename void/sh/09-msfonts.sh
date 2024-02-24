#!/bin/sh

# download microsoft fonts
[ "$microsoft_fonts" = "y" ] || return

# make the font dir
[ -d "$VDIR/usr/share/fonts" ] || mkdir -p "$VDIR/usr/share/fonts"

# download microsoft fonts
[ -r "$SCDIR/msfonts.tar.bz2" ] || wget "https://files.catbox.moe/ij53ka.bz2" -O "$SCDIR/msfonts.tar.bz2"

# cd to font dir
cd "$VDIR/usr/share/fonts"

# extract fonts
tar -xpf "$SCDIR/msfonts.tar.bz2"

# cd to the previous dir
cd -
