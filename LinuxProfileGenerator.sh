#!/bin/bash

## Author : Maki
## Contact : alan.marrec@protonmail.com

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

	echo "Welcome to the volatility profile generator ! :)"
	echo "I'll by your guide."

	echo "[+] Checking kernel version..."

	if [[ $(uname -r) != "$1" ]]; then
		# Easier way to find the script for adding at boot
		updatedb
		echo "[-] Kernel different than expected for the Linux profile."
		apt install -y linux-headers-"$1" linux-image-"$1" volatility-tools zip git &> /dev/null
		echo "[+] New Kernel installed, removing old kernel version..."
		apt purge -y linux-headers-$(uname -r) linux-image-$(uname -r) &> /dev/null
		echo "[+] Add this script at boot..."
		location=$(locate $(basename $0))
		# rc.local file overwriting for :
		# /home/vagrant/LinuxProfileGenerator.sh 4.4.0-93-lowlatency
		# exit 0;
		# Where 4.4.0-93-lowlatency is first argument of the first execution of this script
		echo "$location $1" > /etc/rc.local
		echo "exit 0" >> /etc/rc.local
		echo "[!] Reboot in 5 seconds..."
		sleep 5
		reboot
	else
		echo "[+] Kernel are similar ! Profil creation in progress..."
		cd /usr/src/volatility-tools/linux
		# Volatility profile creation
		# Default module.c is outdated for old kernel
		rm module.c
		# Up-to-date one
		wget https://raw.githubusercontent.com/volatilityfoundation/volatility/master/tools/linux/module.c
		make -C /lib/modules/$1/build CONFIG_DEBUG_INFO=y M=$PWD modules
		dwarfdump -di ./module.o > module.dwarf
		zip Linux_"$1"_version.zip module.dwarf /boot/System.map-"$1"
		mv Linux_"$1"_version.zip /profile/
	fi
}

if [[ $# == 0 ]]; then
	echo "Wrong argument, run -h"
else
	Generator "$1"
fi