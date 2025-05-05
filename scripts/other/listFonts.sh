#!/bin/bash
# List installed fonts-families and their style
# Author: Bruno de Lima <github.com/brunodles>

if [[ -z "$@" ]] ;then
  fc-list --format="%{family[0]} | %{style[0]}\n" | sort | uniq
else
  fc-list --format="%{family[0]} | %{style[0]}\n" | sort | uniq | grep -i "$@"
fi

