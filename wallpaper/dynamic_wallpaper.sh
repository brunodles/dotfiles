#!/usr/bin/env bash
#####################################################################
# Dynamic Wallpaper
# Author: Bruno de Lima <github.com/brunodles>
#####################################################################
# This script will receive a single parameter: image path.
# It is used to look for images in 'jpeg' and 'png' formats.
# With the list of images it randonly pick one to be set as background.
#
# Depends on: 'feh' to update the background image.
# (maybe update to another tool to support more formats)
#
# Usage: $ dynamic_wallpaper "~/Downloads/backgroundImages"
#####################################################################

images_dir=$1
images=($(find $images_dir -type f -name '*' | grep -E "je?pg|png" ))
images_c="${#images[*]}"
image_r=$(( RANDOM % images_c ))
image="${images[$image_r]}"
feh --bg-fill "$image"
printf '%s' "$image"

