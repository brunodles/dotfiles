#!/bin/bash

tmp_script=/tmp/install_script.sh
install_dir=$(dirname $0)
if [ -f "$tmp_script" ]; then
  rm $tmp_script
fi
#echo "install dir ${install_dir}"
$install_dir/generator.sh $@ | while read -r line; do
  echo "$line">>$tmp_script
done
export PS4='\n--------------------------------------\n + '
bash -x $tmp_script
rm $tmp_script