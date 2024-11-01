#!/usr/bin/python3
# Generate json based on the content received
# Author: Bruno de Lima <github.com/brunodles>

import sys
import json

def main(argv):
  dict={}
  for arg in argv:
    splited = arg.split("=")
    dict[splited[0]]=splited[1]
    print(json.dumps(dict))

if __name__ == "__main__":
   main(sys.argv[1:])
