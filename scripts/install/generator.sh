#!/usr/bin/env python3
# This script will read each line of the configuration script to translate into performable commands.
# It is also responsible replacing the install command by the recipe or add the post-install into the final script.
# Author: Bruno de Lima <github.com/brunodles>

from collections import defaultdict
from dataclasses import dataclass
from enum import Enum
import os
import sys
import platform
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent

class RecipeProvider:
  def __init__(self, install_scripts_path: Path = SCRIPT_DIR):
    self.install_script_folder = install_scripts_path
    self.recipe_folder = install_scripts_path / "recipe"
    self.post_install_folder = install_scripts_path / "post_install"

  def load_files(self):
    self.recipes = self.__find_files_on_folder(self.recipe_folder)
    self.post_install = self.__find_files_on_folder(self.post_install_folder)

  def __find_files_on_folder(self, folder:Path): #-> dict[str,Path]
    return {
      p.stem.lower(): p
      for p in folder.iterdir()
      if p.is_file()
    }

# Data representation of command
@dataclass(frozen=True)
class CommandData:
  alias: str
  command: str
  install: str
  require_sudo: bool
  override: bool

  def build_install(self, *parameters):
    result=""
    if self.require_sudo:
      result += "sudo "
    result += f"{self.command} {self.install}"
    if len(parameters) > 0:
      result += " " + " ".join(parameters)
    return result

# todo: might be good to read this from a csv file? or use the csv file to expand this list
class CommandEnum(CommandData, Enum):
  pacman    = ("pacman", "pacman",             "-S",  True, False)
  yay       = (   "yay",    "yay",             "-S",  True, False)
  apk       = (   "apk",    "apk",            "add",  True, False)
  apt       = (   "apt",    "apt",        "install",  True, False)
  brew      = (  "brew",   "brew",        "install",  True, False)
  brew_cask = (  "cask",   "brew", "install --cask",  True,  True)
  snap      = (  "snap",   "snap",        "install",  True,  True)
  zypper    = ("zypper", "zypper",        "install",  True, False)
  echo      = (  "e",   "echo",                  "", False, False)

@dataclass
class OsData:
  alias: str
  fullName: str
  uname: str
  release: str
  desktop: bool
  command: CommandData

# todo: might be good to read this from a csv file? or use the csv file to expand this list
class OsDataEnum(OsData, Enum):
  Arch_Linux        = ( "Ar",        "Arch Linux",  "Linux",      "arch",  True, CommandEnum.pacman)
  Alpine_Desktop    = ("Ald",    "Alpine Desktop",  "Linux",    "alpine",  True, CommandEnum.apk) # to be checked
  Alpine_Server     = ("Als",    "Alpine Server" ,  "Linux",    "alpine", False, CommandEnum.apt) # to be checked
  Ubuntu_Desktop    = ( "Ud",    "Ubuntu Desktop",  "Linux",    "ubuntu",  True, CommandEnum.apt)
  Ubuntu_Server     = ( "Us",    "Ubuntu Server" ,  "Linux",    "ubuntu", False, CommandEnum.apt)
  Raspberry_Desktop = ( "Rd", "Raspberry Desktop",  "Linux", "raspibian",  True, CommandEnum.apt)
  Raspberry_Server  = ( "Rs", "Raspberry Server" ,  "Linux", "raspibian", False, CommandEnum.apt)
  Mac_Os            = (  "M", "Mac Os (brew)"    , "Darwin",          "",  True, CommandEnum.brew)
  Default           = (  "",           "Test"    ,       "",          "",  True, CommandEnum.echo)

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
  def __init__(self, script_file, os_data=OsDataEnum.Default, recipe_provider:RecipeProvider=RecipeProvider()):
    self.script_file = script_file
    self.install_packages: dict[CommandData, list[str]] = defaultdict(list)
    self.output_commands = list()
    self.os_data = os_data
    self.command_order: list[CommandData] = list()
    self.recipe_provider = recipe_provider
    self.overriden_packages: list[str] = list()

  def __register_output_command(self, command:str, aggregate=True):
    if aggregate and len(self.command_order) > 0:
      self.__perform_aggregation()
    self.output_commands.append(command)

  def __perform_aggregation(self):
    for install_command in self.command_order:
      package_list=self.install_packages[install_command]
      if len(package_list) > 0:
        self.__register_output_command(f"{install_command.value.build_install(" ".join(package_list))}", False)
        package_list.clear()
    self.install_packages.clear()
    self.command_order.clear()

  def __remove_package_from_previous_commands(self, package:str):
    for install_command in self.install_packages:
      package_list=self.install_packages[install_command]
      if package in package_list:
        package_list.remove(package)

  def __register_package_list(self, command:CommandData, package_list: list[str]):
    for package in package_list:
      self.__register_package(command, package)
          
  def __register_package(self, command:CommandData, package: str):
    if package in self.recipe_provider.recipes:
      self.__register_output_command(f"sh {self.recipe_provider.recipes[package]}")
      return
    if package in self.overriden_packages:
      return
    if command.override:
      self.overriden_packages.append(package)
      self.__remove_package_from_previous_commands(package)
    self.install_packages[command].append(package)
    self.command_order.append(command)
    if package in self.recipe_provider.post_install:
      self.__register_output_command(f"sh {self.recipe_provider.post_install[package]}")

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
        if ("*" not in line_systems) and (self.os_data.alias not in line_systems):
          continue

        line_command = split_line[0]
        if line_command == "i":
          self.__register_package_list(self.os_data.command, split_line[1:])
          continue
        found_command = False
        for command in CommandEnum:
          if line_command == command.alias:
            self.__register_package_list(command, split_line[1:])
            found_command = True
            break
        if found_command:
          continue
        self.__register_output_command(" ".join(split_line))

    self.__perform_aggregation()
    # for line in self.output_commands:
    #   print(line)

    return self.output_commands
    #print(f"Packages: {" ".join(install_packages)}")


# global vars
last_argument = sys.argv[-1]
current_os_data = OsDataProvider.findPlatform() # todo: add a way to override for testing purposes
recipe_provider = RecipeProvider()
recipe_provider.load_files()
evaluator = FileEvaluator(
  script_file=last_argument,
  os_data=current_os_data,
  recipe_provider=recipe_provider,
)

print(f"# Detected: {current_os_data.fullName} ({current_os_data.alias})")
commands = evaluator.evaluateCommandsFromFile()
for command in commands:
  print(command)


