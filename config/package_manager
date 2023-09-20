#! /bin/bash

declare -A PKG_package_manager_distros

PKG_package_manager_distros["apt"]="Debian"
PKG_package_manager_distros["pacman"]="Arch"
PKG_package_manager_distros["dnf"]="RedHat"
PKG_package_manager_distros["zypper"]="OpenSUSE"

declare -A PKG_distros_package_manager

PKG_distros_package_manager["Debian"]="apt"
PKG_distros_package_manager["Arch"]="pacman"
PKG_distros_package_manager["RedHat"]="dnf"
PKG_distros_package_manager["openSUSE"]="zypper"

declare -A PKG_package_manager_install 

PKG_package_manager_install["apt"]="sudo apt-get install" 
PKG_package_manager_install["pacman"]="sudo pacman -S"
PKG_package_manager_install["dnf"]="sudo dnf install"
PKG_package_manager_install["zypper"]="sudo zypper install"

declare -A PKG_package_manager_unistall 

PKG_package_manager_unistall["apt"]="sudo apt-get remove" 
PKG_package_manager_unistall["pacman"]="sudo pacman -R"
PKG_package_manager_unistall["dnf"]="sudo dnf remove"
PKG_package_manager_unistall["zypper"]="sudo zypper remove"

