#!/bin/sh

export PACKAGES="${PACKAGES:+$PACKAGES }${user_packages:-$(chopt "Which additional packages would you like to install?")}"
