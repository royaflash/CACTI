# CACTI
#####
# 2010 jan 24th - v0.40c
# Deel - <tobby.ziegler::altzero::gmail.com>
# Can be found here : http://forums.cacti.net/viewtopic.php?t=38633
#####

cd ~
wget http://forums.cacti.net/download/file.php?id=22710 -O cacti_autoinstall_v0.40c.sh
wget http://forums.cacti.net/download/file.php?id=22711 -O README_CAIS_v0.40c.txt
cat ./README_CAIS_v0.40c.txt
chmod a+x cacti_autoinstall_v0.40c.sh
./cacti_autoinstall_v0.40c.sh


I/ Licence
This script is released under the GNU GENERAL PUBLIC LICENSE
Version 3, 29 June 2007 - http://www.gnu.org/licenses/gpl.html

II/ Using the script

II-A/ The "A" part of the script
It contains a list of "softwares" that can be installed, you can 
choose what you want to install changing the default 0/1 value according to 
your needs.

- SPINE plugin setup:
Configuration=>Settings=>Paths : Set the Spine Poller File Path to :
/usr/local/spine/spine
SAVE & check that "OK: FILE FOUND" appears
Configuration=>Settings=>Poller : Change the Poller Type to : spine

- REALTIME plugin setup :
Configuration=>Settings=>Misc : Set the Cache directory to :
/var/www/cacti/plugins/rt_cache/
SAVE & check that "OK: FILE FOUND" appears.

II-B/ The "B" part of the script
It contains a list of options that are not enabled by default because they 
require specific user configurations or because they are not directly 
related to Cacti

- Spikekill plugin : 
Spikekill installation is not enabled by default because it needs some 
additional configurations that can not be done by the script, you'll have to 
enable the creation of backup files, and allow the www-data user to write RRD 
files.

- Quiet Lamp:
This option allows to change the default configuration of Apache and PHP in
order to prevent them from being too chatty, in terms of security this is a 
small yet necessary step.

- ModSecurity :
This option installs the Apache Mod-Security module and only allows the usage 
of the "base_rules" rule set, using the "optional_rules" or "experimental 
rules" requires some configuration that cannot be done by the script.

II-C/ The "C" part of the script
It contains the different versions of the "softwares" to be installed, you 
shouldn't change these values unless you know what you're doing.

II-D/ The "D" part of the script
It contains some user/passwords definitions that you should change

WARNING : If you change the MySQL Password in the "MySQLRootPwd" var, make 
sure you remember it, during MySQL installation, the system will ask your for this password, this 
process is not a part of the script but a part of the MySQL server package 
installation. 

II-E/ The "E" part of the script
You should not change anything here unless you know what you're doing

III/ Disclaimer

III-A/ Standard
This script is released under the disclaimer of its licence

III-B/ extended
This Script has been written to TEST the latest Cacti version as well as the 
newest plugins. For a "Prod" environment I don't recommend using it, you'd 
better install everything by yourself. I can not guarantee that everything will 
work fine on a different Debian version or on a distro based on Debian 5 
(Ubuntu for instance), this script has been written and tested for 
Debian 5.X.
EDIT - 2011/01/24 - The script works with Ubuntu 10.10

IV/ Support
I will only answer the questions posted on the Cacti.net forum or by email, 
references are at the very beginning of the script. I cannot guarantee the 
delay between your question and my answer, this is best-effort.

V/ Changelog
v0.00 	- 2010/07/18 - 	Cacti and PA installation(+)
v0.10 	- 2010/07/19 - 	Handling cactiuser password changes(bugfix), 
			"En" translation of comments(+)
v0.20 	- 2010/07/20 - 	Spine installation(+)
v0.21 	- 2010/07/20 - 	Script uses functions(change)
v0.30 	- 2010/07/21 - 	Settings plugin installation(+)
v0.31 	- 2010/07/21 - 	Cycle plugin installation(+)
v0.32 	- 2010/07/22 - 	Script uses slightly better user rights(change)
v0.33 	- 2010/07/23 - 	Realtime plugin installation(+)
v0.33a 	- 2010/07/27 - 	Sed enhancements(change)
v0.34 	- 2010/08/04 - 	Cacti patch(+)
v0.35 	- 2010/09/20 - 	Spine patch(+), cycle plugin upgrade(change),
			realtime plugin upgrade(change)
v0.36 	- 2011/01/01 - 	PA version upgrade(change), cacti patch(+)
v0.37 	- 2011/01/02 - 	plugin additions (+) : LoginMod, Monitor, Nectar, 
			SpikeKill, Thold
v0.38 	- 2011/01/07 - 	plugin additions(+) : NetworkWeathermap, Clog
v0.40 	- 2011/01/09 - 	Apache ModSecurity addition (+), major changes in the 
			code structure, test if the softwares have already 
			been installed
v0.40b	- 2011/01/23 -	DEPRECATED
v0.40c	- 2011/01/24 - 	bugfix for ubuntu users (#!/bin/bash thing)
