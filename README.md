# Auto_vol - Automated basics volatility tasks

## Usage

```bash
./auto_vol [-h] [-d <dump_name>] [-f <folder_name>] [-p <vol_plugin_path>] [-a <volume_path>] -- Script that performs basic volatility command and stores them into a directory

where:
	-h	Show this help
	-d 	Name of the memory dump to analyze
	-f	Name of the folder
	-p  Volatility plugins path
	-a 	Volume path (if a volume has to be mount)

Examples : 

./auto_vol -d /home/maki/memory.raw -f /home/maki/tests -p /home/maki/zTools/plug_vol
./auto_vol -d /home/maki/memory.raw -f /home/maki/tests -p /home/maki/zTools/plug_vol -a /home/maki/image.dd
```

This script will create an output folder and store every result. It can also detect if it's a Windows or Linux dump.

## Prerequisites

This script will need :

* Bitlocker plugin : https://github.com/elceef/bitlocker
* Libbde : https://github.com/libyal/libbde
* Findaes : https://sourceforge.net/projects/findaes/?SetFreedomCookie
* Foremost : http://foremost.sourceforge.net/


## Windows

### Tree

```bash
<-f argument>
├── all_process.txt
├── audit.txt
├── current_process.txt
├── hash.txt
├── iehistory.txt
├── netscan.txt
├── present_file.txt
├── screenshot
│   ├── session_0.msswindowstation.mssrestricteddesk.png
│   ├── [...]
│   └── session_1.WinSta0.Winlogon.png
└── truecrypt_info.txt or bitlocker_infos.txt

```


### Features 

* Find windows profiles _(audit.txt)_
* Find computer name _(audit.txt)_
* Find user hash and try to crack it with online database _(hash.txt)_
* cmdscan _(audit.txt)_
* consoles _(audit.txt)_
* pstree _(current_process.txt)_
* psxview _(all_process.txt)_
* clipboard _(audit.txt)_
* screenshot _(screenshot folder)_
* filescan _(present_file.txt)_
* iehistory _(iehistory.txt)_
* netscan _(netscan.txt)_
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

## Linux - IN PROGRESS

### Prerequisite

* Virtualbox
* vagrant
* vagrant-scp (vagrant plugin)

### Vagrant box commands

* install new kernel
* restart


### To do

* Linux part