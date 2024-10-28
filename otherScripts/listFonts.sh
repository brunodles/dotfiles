#!/bin/bash
# List installed fonts-families and their style
# Author: Bruno de Lima <github.com/brunodles>
fc-list --format="%{family[0]} | %{style[0]}\n" | sort | uniq

