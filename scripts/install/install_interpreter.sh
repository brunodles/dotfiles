#!/bin/bash

tmp_script=/tmp/install_script.sh
if [ -f "$tmp_script" ]; then
  rm $tmp_script
fi
./install_output.sh $@ | while read -r line; do
  echo "$line">>$tmp_script
done
bash -x $tmp_script
rm $tmp_script