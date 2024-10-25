#!/bin/bash
# Open one of my prefered terminals

if [ ! -z "$(where alacritty)" ] ; then
  alacrity
else
  i3-sensible-terminal
fi

