# Auto_vol - Automated basics volatility tasks

## Usage

```bash
./auto_vol [-h] [-d <dump_name>] [-f <results_folder>] [-p <vol_plugin_path>] [-a <volume_path>] -- Script that performs basic volatility command and stores them into a directory

where:
	-h	Show this help
	-d 	Name of the memory dump to analyze
	-f	Results folder name
	-p  Volatility plugins path
	-a 	Volume path (if a volume has to be mount)

Examples : 

./auto_vol -d dump -f truecrypt_encrypted
./auto_vol -d memory.raw -f bitlocker_encrypted -p /home/maki/zTools/plug_vol -a image.dd 
./auto_vol -d memory.raw -f luks_encrypted -p /home/maki/zTools/plug_vol/ -a forensic.img"
```

This script will create an output folder and store every result. It can also detect if it's a Windows or Linux dump.

## Prerequisites

This script will need :

* Bitlocker plugin : https://github.com/elceef/bitlocker
* Libbde : https://github.com/libyal/libbde
* Aeskeyfind : https://github.com/eugenekolo/sec-tools/tree/master/crypto/aeskeyfind/aeskeyfind
* Foremost : http://foremost.sourceforge.net/
* Curl
* Vagrant + vagrant-scp plugin
* Foremost
* Aeskeyfind
* Tree


## Windows

### Tree

```bash
<-f argument>
dump_analyze
├── audit.txt
├── bitlocker_infos.txt
├── bitlock_tmp
│   ├── flag.jpg
│   ├── $RECYCLE.BIN
│   │   └── S-1-5-21-3927909812-3916504943-3837934204-1000
│   │       └── desktop.ini
│   └── System Volume Information
│       ├── FVE2.{24e6f0ae-6a00-4f73-984b-75ce9942852d}
│       ├── FVE2.{e40ad34d-dae9-4bc7-95bd-b16218c10f72}.1
│       ├── FVE2.{e40ad34d-dae9-4bc7-95bd-b16218c10f72}.2
│       ├── FVE2.{e40ad34d-dae9-4bc7-95bd-b16218c10f72}.3
│       └── tracking.log
└── cmd_windows
    ├── clipboard
    ├── cmdscan
    ├── consoles
    ├── filescan
    ├── iehistory
    ├── netscan
    ├── pstree
    └── psxview
```
**Bitlocker example**

### Features 

* Find windows profiles
* Find computer name 
* Find user hash and try to crack it with online database _(hash.txt)_
* cmdscan
* consoles
* pstree 
* psxview 
* clipboard 
* screenshot
* filescan
* iehistory 
* netscan 
* Bitlocker detection and encrypted volume mounting
* Truecrypt detection and key recovery

### Hash cracking

I use the hashdump plugin of volatility, here is the standard output :

```bash
Volatility Foundation Volatility Framework 2.6
Administrator:500:aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0:::
Guest:501:aad3b435b51404eeaad3b435b51404ee:31d6cfe0d16ae931b73c59d7e0c089c0:::
HomeGroupUser$:1001:aad3b435b51404eeaad3b435b51404ee:57e82f46aff390080f143c09ab2c5b68:::
info:1002:aad3b435b51404eeaad3b435b51404ee:dc3817f29d2199446639538113064277:::
```

We just need usernames and hash to crack.

#### Username extraction

```bash
volatility -f <memdump_path> --profile=<profile> hashdump 2> /dev/null | cut -f1 -d":"
```

* 2> /dev/null : Redirect the volatility stderr to /dev/null (just te delete the "Volatility Foundation Volatility Framework 2.6" on each volatility execution).
* cut -f1 -d":" : Remove everything after the first semicolon.

#### Hashs extraction

```bash
volatility -f <memdump_path> --profile=<profile> hashdump 2> /dev/null | sed 's/://g' | grep -o '.\{32\}$'
```

* 2> /dev/null : Redirect the volatility stderr to /dev/null (just te delete the "Volatility Foundation Volatility Framework 2.6" on each volatility execution).
* sed 's/://g' : Remove semicolon. 
* grep -o '.\{32\}$' : Keep only last 32 chars. LM hash to crack is always 32 chars.

#### Hash "cracking"

```bash
curl --data "hash=${plop}&decrypt=Décrypter" -s http://md5decrypt.net/Ntlm/ | sed 's/<[^>]*>//g' | grep <hash_extracted> | awk '{print $3}' | sed 's/.\{6\}$//g'
```
Line 72 - Windows function

* curl command : I let you check the man for more informations.
* sed 's/<[^>]*>//g' : The script remove all html tags.
* grep <hash_extracted> : The script grep the line with the hash and the crack.
* awk '{print $3}' : Keep only the third column, it contains the hash cracked.
* sed 's/.\{6\}$//g' : Remove last 8 chars, md5decrypt.net add the word "Trouvé" when a hash is find in the database.

Then we just print the username with the associate password.

### Truecrypt

![](https://img11.hostingpics.net/pics/33553321tc.png)

For this feature, I just used the truecrypt plugins suite :

* truecryptsummary
* truecryptpassphrase

To detect if there is a Truecrypt container open during the dump, the script just grep the _all_process.txt_ file with "Truecrypt" to find the process.

```bash
if [[ $(cat ${base}/all_process.txt | grep -i "truecrypt") ]]; then
```
Line 147 - TruecryptDetection function.

### Bitlocker

![](https://img11.hostingpics.net/pics/201051bitlocker.png)

This script follows those steps :

* Is bitlocker process present ?
* Find keys (FVEK & TWEAK)
* Parse keys 
* Auto mount (if disc dump is available)

#### Is bitlocker process present ?

Such as truecrypt, the script will just grep _all_process.txt_. Bitlocker process (fvenotify) is hidden, this is the main difference for detecting Truecrypt or Bitlocker.
This is why I do a **pstree** and a **psxview**, I let you check the command reference of Volatility for more informations.

```bash
if [[ $(cat ${base}/all_process.txt | grep -i "fvenotify") ]]; then
```
Line 128 - BitlockerDetection function

#### Find keys and parse them

To find keys, I'm simply use the bitlocker plugin (link above in Prerequisite section).

The standard output of this plugin is :

```bash
Volatility Foundation Volatility Framework 2.6

Address : 0xfa80018be720
Cipher  : AES-128
FVEK    : e7e576581fe26aa7c71a7e711c778da2
TWEAK   : b72f4e075edb7e734dfb08638cf29652
```

But I need this output to mount the encrypted volume :

> FVEK:TWEAK

I made a little one liner in bash to do the job :

```bash
volatility --plugin=<plugin_path> -f <mem_dump_path> --profile=<profile> bitlocker 2> /dev/null | head -n-1  | tail -n 2 | awk '{print $3}' | tr '\n' ':' | sed 's/.$//g'
```
Line 135 - BitlockerDetection function

* 2> /dev/null : To hide the stderr of volatility (to remove the Volatility Foundation Volatility Framework 2.6 on top of each volatility output).
* head -n-1 : Remove the last empty line.
* tail -n 2 : Remove first three lines (empty one, Address and Cipher).
* awk '{print $3}' : Keep only FVEK and TWEAK values.
* tr '\n' ':' : Put FVEK and TWEAK on the same line and seperate with semicolon.
* sed 's/.$//g' : Remove last ':'.
 
#### Auto mount

To mount bitlocker (BDE) volume, Linux users, you have to install **libbde**, link above in Prerequisite section.

/!\ Arch Linux users, use the libbde-git ! /!\
```bash
$ yaourt -S libbde-git
```

The bdemount binary works well with this syntax :

```bash
# bdemount -X allow_root -k <FVEK:TWEAK> -o <disc_offset> <bde_volume> <mounting_point> && chown ${USER}:${USER} -R <mounting_point> && chmod 655 -R <mouting_point>
```

* -X allow_root : In the mounting point we will have the bde volume decrypted, but we have to mount with "mount" command as a standard filesystem and we need **fdisk -l** for the offset, so this script needs to be start with root permissions.
* -k <FVEK:TWEAK> : You can understand why we parsed keys before ;)
* chown and chmod : To allow you current user to deal with mounting folder.

For the offset, we need to use **fdisk -l** command on our encrypt file. Below the standard output :

```bash
Disque <encrypted_volume_path> : 75 MiB, 78643200 octets, 153600 secteurs
Unités : secteur de 1 × 512 = 512 octets
Taille de secteur (logique / physique) : 512 octets / 512 octets
taille d'E/S (minimale / optimale) : 512 octets / 512 octets
Type d'étiquette de disque : dos
Identifiant de disque : 0x0a152bd9

Périphérique                                      Amorçage Début    Fin Secteurs Taille Id Type
<encrypted_volume_path>1            128 147583   147456    72M  7 HPFS/NTFS/ex
```

We just need to do this operation : <volume_start>*<sector_size>

Bash parsing :

```bash
a1=$(fdisk -l "$2" | tail -n 1 | awk '{print $2}')
a2=$(fdisk -l "$2" | sed '1d' | head -n 1 | awk '{print $6}')
```
BitlockerDetection function

Now we have everything to mount decrypt the volume.
Finally the decrypted volume is recognized as a regular filesystem (file command), so we just have to mount it.

```bash
mount -o loop,ro <path_to_decypted_volume> <folder_mount>
```

The script executes the **tree** command when the final fs is mounted (see the pictures above).

## Linux 

### Prerequisite

* Virtualbox
* vagrant
* vagrant-scp (vagrant plugin)
* libbde-git (for bdemount binary)
* curl
* foremost
* aeskeyfind (This package : https://github.com/eugenekolo/sec-tools/tree/master/crypto/aeskeyfind/aeskeyfind)
* tree

Auto_vol will check for dependancies at boot : 

![](https://img11.hostingpics.net/pics/883028linrequir.png)


### LinuxProfileGenerator script

```bash
LinuxProfileGenerator.sh [-h] <kernel_version>
This script must be run as root user !

where:
	-h 	Help page

Examples : 

./LinuxProfileGenerator.sh 4.4.0-93-lowlatency
```

This script will check is the current installed kernel is the same as expected for the volatility profile. 
If the wanted profile already exist in your **volatility/plugins/overlays/linux** path, then auto_vol will use the existing profile instead of create one.

#### If kernel are different

The script install the wanted kernel (ex : 4.4.0-93-lowlatency) and remove the old one.
Auto_vol main script will just call this script twice (before and after kernel modification).

```bash
vagrant ssh -c "chmod +x ~/LinuxProfileGenerator.sh && sudo ~/LinuxProfileGenerator.sh ${kernel_version}"
echo "[*] Kernel updated."
sleep 25
vagrant ssh -c "sudo ~/LinuxProfileGenerator.sh ${kernel_version}"
printf "[+] Profil ${GREEN}created${NC}.\n"
```
Line 176 - 180 ; Auto_vol script

#### If kernel are same

This script will go at this path : **/usr/src/volatility-tools/linux** to generate profile.

On old Ubuntu version I noticed that the **module.c** is outdated, then I remove it and download the new one :

```bash
rm module.c
wget https://raw.githubusercontent.com/volatilityfoundation/volatility/master/tools/linux/module.c	
```
Line 58 / 60 - Generator function

Then the script follows the volatility profile creation procedure : https://github.com/volatilityfoundation/volatility/wiki/Linux

![](https://img11.hostingpics.net/pics/532635linprof.png)

### Features

* linux_pslist
* linux_psaux
* linux_pstree
* linux_psxview
* linux_lsof
* linux_bash
* linux_lsmod
* linux_check_tty
* linux_arp
* linux_ifconfig
* linux_cpuinfo
* linux_dmesg
* linux_mount

![](https://img11.hostingpics.net/pics/308111lincmd.png)

### LUKS automount

Cipher used has to be AES-128 or AES-256,  because I'm using **aeskeyfind**.

![](https://img11.hostingpics.net/pics/607693lindecip.png)

#### If not Ubuntu

If the memory dump is not an Ubuntu memory dump, but if you have a disc dump ciphered, you don't need to create a volatility profile. 
Auti_vol will automount the disc dump and display hint to create the right profile as shown below :

![](https://img11.hostingpics.net/pics/958738lindebian.png)