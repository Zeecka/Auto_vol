#!/bin/bash

## Author : Maki
## Contact : alan.marrec@protonmail.com

# Colors management
NC='\033[0m' # No color
RED='\033[0;31m'
LRED='\033[1;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BLUE='\033[1;34m'
GRAY='\033[1;37m'

usage="$(basename "$0") [-h] <kernel_version>
This script must be run as root user !

where:
	-h 	Help page

Examples : 

./$(basename $0) 4.4.0-93-lowlatency
"

while getopts "hk:" optionName; do
	case "$optionName" in
		h)	printf "$usage" 
			exit ;;
		k)	kern=$2;;
		[?])	echo "Wrong argument, please see the help page (-h)" 
			exit 1;;
	esac
done

function Generator() {
	if [[ $EUID -ne 0 ]]; then
		echo "[-] This script must be run as root." 1>&2
		exit 1
	fi

	mkdir /profile &> /dev/null

	printf "[*] ${PURPLE}Checking kernel${NC} version...\n"

	if [[ $(uname -r) != "$1" ]]; then
		# Easier way to find the script for adding at boot
		updatedb
		printf "[-] ${LRED}Kernel different than expected for the Linux profile.${NC}\n"
		apt install -y linux-headers-"$1" linux-image-"$1" volatility-tools zip make gcc &> /dev/null
		printf "[+] New Kernel ${GREEN}installed${NC}, ${PURPLE}removing${NC} old kernel version...\n"
		apt purge -y linux-headers-$(uname -r) linux-image-$(uname -r) &> /dev/null
		printf "[!] ${LRED}Reboot in 2 seconds...${NC}\n"
		sleep 2
		reboot
	else
		printf "[+] ${GREEN}Kernel are similar !${NC} Profil creation in progress...\n"
		cd /usr/src/volatility-tools/linux
		# Volatility profile creation
		# Default module.c is outdated for old kernel
		rm module.c
		# Up-to-date one
		wget https://raw.githubusercontent.com/volatilityfoundation/volatility/master/tools/linux/module.c &> /dev/null
		printf "[+] ${GREEN}New module.c${NC} downloaded.\n"
		make -C /lib/modules/$1/build CONFIG_DEBUG_INFO=y M=$PWD modules &> /dev/null
		printf "[+] Module output ${GREEN}generated${NC}.\n"
		dwarfdump -di ./module.o > module.dwarf 
		printf "[+] ${PURPLE}module.dwarf${NC} has been ${GREEN}successfully generated${NC}.\n"
		linuxType=$(lsb_release -a | grep -i "distributor" | awk '{print $3}')
		zip "$linuxType"_"$1"_version.zip module.dwarf /boot/System.map-"$1"
		mv "$linuxType"_"$1"_version.zip /profile/
	fi
}

if [[ $# == 0 ]]; then
	echo "Wrong argument, run -h"
else
	Generator "$1"
fi