#!/bin/env python
from collections import defaultdict
from dataclasses import dataclass
from enum import Enum
import os
import sys
import platform
from pathlib import Path

RECIPE_PATH="./rcp"

class RecipeProvider:
  def __init__(self, recipe_folder_path=RECIPE_PATH):
    self.recipe_folder = Path(recipe_folder_path)

  def findRecipes(self):
    self.recipes = {
      p.stem.lower(): p
      for p in self.recipe_folder.iterdir()
      if p.is_file()
    }
    return self.recipes

class Command(str, Enum):
  pacman    = ("sudo pacman -S")
  apk       = ("sudo apk add")
  apt       = ("sudo apt install")
  brew      = ("sudo brew install")
  brew_cask = ("sudo brew install --cask")
  echo      = ("echo install?")

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
  Default           = (  "",           "Test"    ,       "",          "",  True, Command.echo)

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
  def __init__(self, script_file, os_data=OsDataEnum.Default, recipes=defaultdict(str)):
    self.script_file = script_file
    self.install_packages = defaultdict(list)
    # self.output_commands = list()
    self.os_data = os_data
    self.recipes = list()
    self.command_order = list()
    self.recipes = recipes


  def __register_output_command__(self, command, aggregate=True):
    if aggregate and len(self.command_order) > 0:
      self.__perform_aggregation__()
    self.output_commands.append(command)

  def __perform_aggregation__(self):
    for install_command in self.command_order:
      package_list=self.install_packages[install_command]
      if len(package_list) > 0:
        self.__register_output_command__(f"{install_command.value} {" ".join(package_list)}", False)
        package_list.clear()
    self.install_packages.clear()
    self.command_order.clear()

  def __remove_package_from_previous_commands__(self, package):
    for install_command in self.install_packages:
      package_list=self.install_packages[install_command]
      if package in package_list:
        package_list.remove(package)

  def __register_package_list__(self, command, package_list):
    for package in package_list:
      self.__register_package__(command, package)
          
  def __register_package__(self, command, package):
    if package in self.recipes:
      self.__perform_aggregation__()
      self.__register_output_command__(f"./{self.recipes[package]}")
      return
    if package in self.install_packages[Command.brew_cask]:
      return
    if command == Command.brew_cask:
      self.__remove_package_from_previous_commands__(package)
    self.install_packages[command].append(package)
    self.command_order.append(command)

  def evaluateCommandsFromFile(self):
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
          self.__register_package_list__(self.os_data.installCommand, split_line[1:])
          continue
        if line_command == "cask":
          self.__register_package_list__(Command.brew_cask, split_line[1:])
          continue

        self.__register_output_command__(" ".join(split_line))

    self.__perform_aggregation__()
    # for line in self.output_commands:
    #   print(line)

    return self.output_commands
    #print(f"Packages: {" ".join(install_packages)}")


# global vars
last_argument = sys.argv[-1]
current_os_data = OsDataProvider.findPlatform()
recipe_provider = RecipeProvider()
evaluator = FileEvaluator(
  script_file=last_argument,
  os_data=current_os_data,
  recipes=recipe_provider.findRecipes(),
)

print(f"# Detected: {current_os_data.fullName} ({current_os_data.key})")
commands = evaluator.evaluateCommandsFromFile()
for command in commands:
  print(command)


