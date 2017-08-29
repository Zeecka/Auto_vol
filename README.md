# Auto_vol - Automated basics volatility tasks

## Usages

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

This script will create an output folder and stored every results. It can also detect if it's a Windows or Linux dump.

## Prerequistes

This script will need :

* Bitlocker plugin : https://github.com/elceef/bitlocker
1. Libbde : https://github.com/libyal/libbde
For Arch user, install the libbde-git
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

* Find windows profil _(audit.txt)_
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

### Truecrypt

![](https://img11.hostingpics.net/pics/33553321tc.png)

### Bitlocker

![](https://img11.hostingpics.net/pics/201051bitlocker.png)
