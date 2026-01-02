#!/bin/env python
from collections import defaultdict
from dataclasses import dataclass
from enum import Enum
import os
import sys
import subprocess
import platform


# Example: Get the current working directory
#result = subprocess.run(["pwd"], capture_output=True, text=True)
#print("Command output:", result.stdout)
#print("Errors (if any):", result.stderr)
#print("Exit code:", result.returncode)


class Command(str, Enum):
  pacman = ("pacman -S")
  apk = ("apk add")
  apt = ("apt install")
  brew = ("brew install")
  brew_cask = ("brew install --cask")
  echo = ("echo install?")

@dataclass
class OsData:
  key: str
  fullName: str
  uname: str
  release: str
  desktop: bool
  installCommand: str

class OsDataEnum(OsData, Enum):
  Arch_Linux        = ( "Ar",        "Arch Linux",  "Linux",      "arch",  True, Command.pacman)
  Alpine_Desktop    = ("Ald",    "Alpine Desktop",  "Linux",    "alpine",  True, Command.apk) # to be checked
  Alpine_Server     = ("Als",    "Alpine Server" ,  "Linux",    "alpine", False, Command.apt) # to be checked
  Ubuntu_Desktop    = ( "Ud",    "Ubuntu Desktop",  "Linux",    "ubuntu",  True, Command.apt)
  Ubuntu_Server     = ( "Us",    "Ubuntu Server" ,  "Linux",    "ubuntu", False, Command.apt)
  Raspberry_Desktop = ( "Rd", "Raspberry Desktop",  "Linux", "raspibian",  True, Command.apt)
  Raspberry_Server  = ( "Rs", "Raspberry Server" ,  "Linux", "raspibian", False, Command.apt)
  Mac_Os            = (  "M", "Mac Os (brew)"    , "Darwin",          "",  True, Command.brew)
  Default           = ( "",            "Test"    ,       "",          "",  True, Command.echo)

class OsDataProvider:
  @staticmethod
  def findPlatform():
    current_platform_uname = platform.uname().system
    current_os_release = platform.freedesktop_os_release()["ID"]
    current_desktop = os.environ["XDG_CURRENT_DESKTOP"]
    current_os_data = OsDataEnum.Default
    for name, os_data in OsDataEnum.__members__.items():
      if not os_data.uname == current_platform_uname:
        continue
      if not os_data.release == current_os_release:
        continue
      if not((len(current_desktop)>0) == os_data.desktop):
        continue
      current_os_data = os_data
      break

    return current_os_data

class FileEvaluator:
  def __init__(self, script_file, os_data=OsDataEnum.Default, is_dry_run=False):
    self.script_file = script_file
    self.is_dry_run = is_dry_run
    self.install_packages = defaultdict(list)
    # self.output_commands = list()
    self.os_data = os_data
    self.recipes = list()
    self.command_order = list()

  def includePackagesToOutputCommands(self):
    for install_command in self.command_order:
      package_list=self.install_packages[install_command]
      if len(package_list) > 0:
        self.output_commands.append(f"{install_command.value} {" ".join(package_list)}")
        package_list.clear()
    self.install_packages.clear()
    self.command_order.clear()

  def removePackageFromPreviousCommands(self, package):
    for install_command in self.install_packages:
      package_list=self.install_packages[install_command]
      if package in package_list:
        package_list.remove(package)

  def registerPackageList(self, command, package_list):
    for package in package_list:
      self.registerPackage(command, package)
          
  def registerPackage(self, command, package):
    if package in self.install_packages[Command.brew_cask]:
      return
    if command == Command.brew_cask:
      self.removePackageFromPreviousCommands(package)
    self.install_packages[command].append(package)
    self.command_order.append(command)

  def readFile(self):
    self.output_commands = list()
    with open(self.script_file, 'r') as file:
      for line in file:
        line = line.strip()
        if line.startswith("#"):
          continue
        if not line:
          continue

        split_line = line.split()
        line_systems = split_line.pop(0)
        if ("*" not in line_systems) and (self.os_data.key not in line_systems):
          continue

        line_command = split_line[0]
        if line_command == "i":
          self.registerPackageList(self.os_data.installCommand, split_line[1:])
          continue
        if line_command == "cask":
          self.registerPackageList(Command.brew_cask, split_line[1:])
          continue

        self.includePackagesToOutputCommands()
        self.output_commands.append(" ".join(split_line))

    self.includePackagesToOutputCommands()
    # for line in self.output_commands:
    #   print(line)

    return self.output_commands
    #print(f"Packages: {" ".join(install_packages)}")







# global vars
is_dry_run=("--dry" in sys.argv)
last_argument = sys.argv[-1]
current_os_data = OsDataProvider.findPlatform()
evaluator = FileEvaluator(
  script_file=last_argument,
  os_data=current_os_data,
  is_dry_run=is_dry_run,
)

print(f"Detected: {current_os_data.fullName} ({current_os_data.key})")
# if is_dry_run:
#   print(f" -   uname: \"{current_platform_uname}\"")
#   print(f" - release: \"{current_os_release}\"")
#   print(f" - desktop: \"{current_desktop}\"")
#   print("")
print("\n".join(evaluator.readFile()))

