#!/bin/sh

kernel_version="${kernel_version:-$(chopt "Which kernel version do you want to use?" "5.4")}"

export PACKAGES="${PACKAGES:+$PACKAGES }${kernel_version:+linux$kernel_version}"
