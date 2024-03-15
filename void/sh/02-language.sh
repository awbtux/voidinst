#!/bin/sh

# set the language
printf "LANG=$language.UTF-8\nLC_ALL=$language.UTF-8\nLC_COLLATE=C" >$VDIR/etc/locale.conf

# generate it
sed "s/#${language}/${language}/g" -i $VDIR/etc/default/libc-locales
