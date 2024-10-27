#!/bin/bash
# Print the terminal colors
# Original source unknwon, some other interesting script can be found here:
# https://askubuntu.com/questions/27314/script-to-display-all-terminal-colors


print_color(){
    printf "\e[0;${1};${2}m%03d" $1;
    printf '\e[0m';
    printf ' '
    # [ ! $((($1) % 6)) -eq 0 ] && printf ' ' || printf '\n'
}

between(){
  for((i=$1; i<$2; i++)); do
    eval "$3 $i $i"
  done
  echo ""
}

add_to() {
  local resultVar=""
  for((i=$1; i<$2; i++)); do
    resultVar="$resultVar $i"
  done
  echo $resultVar
}

#between 0 110 print_color
echo "# FG"
between 30 39 print_color
between 90 97 print_color
echo ""

echo "# BG"
between 40 49 print_color
between 100 107 print_color
echo ""

bg=""
fg=""
fg+=$(add_to 30 39)
fg+=" $(add_to 90 97)"
bg+=$(add_to 40 49)
bg+=" $(add_to 100 107)"

#echo "bg $bg"
#echo "fg $fg"

for i in $fg ; do
  for j in $bg ; do
    print_color $i $j
  done
  echo ""
done

