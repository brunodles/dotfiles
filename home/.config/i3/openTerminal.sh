#!/bin/bash
# Open one of my prefered terminals

try() {
  if [ ! -z "$(command -v $1)" ] ; then
    $1
    exit 0
  fi
}

try ghostty
try alacritty
try i3-sensible-terminal

