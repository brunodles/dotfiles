#!/bin/bash
# Open one of my prefered terminals

if [ ! -z "$(command -v alacritty)" ] ; then
  alacritty
else
  i3-sensible-terminal
fi

