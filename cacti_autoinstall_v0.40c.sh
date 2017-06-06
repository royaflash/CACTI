#!/bin/bash 
# (v0.40c)Cacti, Plugin Architecture, and Plugins automatic installation script for Linux Debian 5 
# Deel - 2011 jan 24th - <tobby.ziegler::altzero::gmail.com>
# Can be found here : http://forums.cacti.net/viewtopic.php?t=38633
#################################################################################################

# More info in the README_CAIS_v0.40.TXT

## A - Select what you want to install ( 1 stands for YES, 0 stands for NO )
#
install_lamp=1
install_cacti=1
patch_cacti=1
setup_snmp_public=1
install_spine=1
install_PA=1
install_settings=1
install_cycle=1
install_realtime=1
install_loginmod=1
install_monitor=1
install_nectar=1
install_thold=1
install_weathermap=1
install_clog=1


## B - Specific installation options not enabled by default
## Read the part II-B of README_CAIS_v0.40.TXT file
#
install_spikekill=0 
quiet_lamp=0 
install_modsecurity=0 

## C - Some Cacti related version definitions (No reason to change something here if you're using the latest script version)
#
CactiVersion="0.8.7g" 			# Cacti version to be installed
PAVersion="2.9" 				# Plugin architecture version to be installed
SpineVersion="0.8.7g" 			# Spine version to be installed
SettingsVersion="0.7-1" 		# Settings plugin version to be installed
CycleVersion="1.2-1" 			# Cycle plugin version to be installed
RealTimeVersion="0.43-1" 		# RealTime plugin version to be installed
LoginModVersion="1.0" 			# LoginMod plugin version to be installed
MonitorVersion="1.2-1" 			# Monitor plugin version to be installed
NectarVersion="0.30" 			# Nectar plugin version to be installed
SpikeKillVersion="1.2-1" 		# SpikeKill plugin version to be installed
TholdVersion="0.43" 			# Thold (Threshold) plugin version to be installed (for now this var is unused)
WeatherMapVersion="0.97a" 		# PHP Network WeatherMap Plugin to be installed
ClogVersion="1.6-1" 			# Clog plugin version to be installed
ModSecurityVersion="2.5.11"		# Modsecurity Version to be installed
ModSecurityCRSVersion="2.1.1"	# Modsecurity CRS Version to be installed

## D - Some System related definitions (EDIT 
#
MySQLCactiUser="_cactiuser" 	# MYSQL user for cacti database
MySQLCactiPwd="_cactipassw" 	# Password for the MYSQL user defined above
SystemCactiUser="usercacti" 	# Linux user running cacti
MySQLRootPwd="dbadmin" 			# Password for MYSQL user "root"

########################################################################
#### /!\ /!\ /!\ DO NOT EDIT ANYTHING BEYOND THIS LINE  /!\ /!\ /!\ ####
########################################################################

## E - Installation functions
#

## Apache2, PHP5 and MySQL5 installation
#
install_lamp(){
apt-get install apache2 -y
apt-get install php5 php5-gd php5-cli -y
apt-get install mysql-server php5-mysql -y
/etc/init.d/apache2 restart
}

## Cacti installation
#
install_cacti(){
apt-get install rrdtool snmp snmpd php5-snmp -y
cd /usr/src/
wget http://www.cacti.net/downloads/cacti-$CactiVersion.tar.gz
tar zxvf cacti-$CactiVersion.tar.gz
mv ./cacti-$CactiVersion/ /var/www/cacti/
mysqladmin -u root -p$MySQLRootPwd create cacti
echo "GRANT ALL ON cacti.* TO $MySQLCactiUser@localhost IDENTIFIED BY '$MySQLCactiPwd';"|mysql -u root -p$MySQLRootPwd mysql
mysql -u $MySQLCactiUser -p$MySQLCactiPwd cacti < /var/www/cacti/cacti.sql
cd /var/www/cacti/include/
sed -i -e 's/username = "cactiuser"/username = "'$MySQLCactiUser'"/' config.php
sed -i -e 's/password = "cactiuser"/password = "'$MySQLCactiPwd'"/' config.php
useradd $SystemCactiUser -g www-data -d /var/www/cacti -s /bin/false
chown -R $SystemCactiUser:www-data /var/www/cacti/rra/ /var/www/cacti/log/
chmod -R 770 /var/www/cacti/rra/ /var/www/cacti/log/
touch /etc/cron.d/cacti
echo "*/5 * * * * $SystemCactiUser php /var/www/cacti/poller.php >/dev/null 2>&1" > /etc/cron.d/cacti
rm -f /usr/src/cacti-$CactiVersion.tar.gz
}

## Patching Cacti
#
patch_cacti(){ 
apt-get install patch -y
cd /usr/src/
wget http://www.cacti.net/downloads/patches/$CactiVersion/data_source_deactivate.patch
wget http://www.cacti.net/downloads/patches/$CactiVersion/graph_list_view.patch
wget http://www.cacti.net/downloads/patches/$CactiVersion/html_output.patch
wget http://www.cacti.net/downloads/patches/$CactiVersion/ldap_group_authenication.patch
wget http://www.cacti.net/downloads/patches/$CactiVersion/script_server_command_line_parse.patch
wget http://www.cacti.net/downloads/patches/$CactiVersion/ping.patch
wget http://www.cacti.net/downloads/patches/$CactiVersion/poller_interval.patch
cd /var/www/cacti/
patch -b -p1 -N < /usr/src/data_source_deactivate.patch
patch -b -p1 -N < /usr/src/graph_list_view.patch
patch -b -p1 -N < /usr/src/html_output.patch
patch -b -p1 -N < /usr/src/ldap_group_authenication.patch
patch -b -p1 -N < /usr/src/script_server_command_line_parse.patch
patch -b -p1 -N < /usr/src/ping.patch
patch -b -p1 -N < /usr/src/poller_interval.patch
rm -f /usr/src/*.patch
}

## Configure Snmpd in order to access the public MIB on localhost
#
setup_snmp_public(){
cd /etc/snmp/
sed -i -e 's/com2sec paranoid/#com2sec paranoid/' snmpd.conf
sed -i -e 's/#com2sec readonly/com2sec readonly/' snmpd.conf
/etc/init.d/snmpd restart
}

## Cacti-Spine installation & patching
#
install_spine(){
apt-get install libsnmp-dev libmysqlclient15-dev libssl-dev make -y
apt-get install patch -y
cd /usr/src/
wget http://www.cacti.net/downloads/spine/cacti-spine-$SpineVersion.tar.gz
wget http://www.cacti.net/downloads/spine/patches/$SpineVersion/unified_issues.patch
tar zxvf cacti-spine-$SpineVersion.tar.gz
cd cacti-spine-$SpineVersion/
patch -p1 -N < /usr/src/unified_issues.patch
./configure
make
mkdir /usr/local/spine
mv ./spine /usr/local/spine/
mv ./spine.conf.dist /usr/local/spine/spine.conf
cd /usr/local/spine/
sed -i -e 's/DB_User         cactiuser/DB_User         '$MySQLCactiUser'/' spine.conf
sed -i -e 's/DB_Pass         cactiuser/DB_Pass         '$MySQLCactiPwd'/' spine.conf
rm -f /usr/src/cacti-spine-$SpineVersion.tar.gz
rm -rf /usr/src/cacti-spine-$SpineVersion/
rm -f /usr/src/unified_issues.patch
}

## Plugin Architecture Installation
#
install_PA(){
apt-get install patch -y
cd /usr/src/
wget http://www.cacti.net/downloads/pia/cacti-plugin-$CactiVersion-PA-v$PAVersion.tar.gz
tar zxvf cacti-plugin-$CactiVersion-PA-v$PAVersion.tar.gz
cd /var/www/cacti/
patch -b -p1 -N < /usr/src/cacti-plugin-arch/cacti-plugin-$CactiVersion-PA-v$PAVersion.diff
mysql -u $MySQLCactiUser -p$MySQLCactiPwd cacti < /usr/src/cacti-plugin-arch/pa.sql
cd /var/www/cacti/include/
sed -i -e 's/"\/"/"\/cacti\/"/' config.php
rm -f /usr/src/cacti-plugin-$CactiVersion-PA-v$PAVersion.tar.gz
rm -rf /usr/src/cacti-plugin-arch/
}

## Settings plugin installation
#
install_settings(){
cd /usr/src/
wget http://docs.cacti.net/_media/plugin:settings-v$SettingsVersion.tgz
mv plugin\:settings-v$SettingsVersion.tgz settings-v$SettingsVersion.tgz
tar zxvf ./settings-v$SettingsVersion.tgz
mv /usr/src/settings/ /var/www/cacti/plugins/
rm -f /usr/src/settings-v$SettingsVersion.tgz
}

## Cycle plugin installation
#
install_cycle(){
cd /usr/src/
wget http://docs.cacti.net/_media/plugin:cycle-v$CycleVersion.tgz
mv plugin\:cycle-v$CycleVersion.tgz cycle-v$CycleVersion.tgz
tar zxvf ./cycle-v$CycleVersion.tgz
mv /usr/src/cycle /var/www/cacti/plugins/cycle/
rm -f /usr/src/cycle-v$CycleVersion.tgz
}

## Realtime plugin installation
#
install_realtime(){
cd /usr/src/
wget http://docs.cacti.net/_media/plugin:realtime-v$RealTimeVersion.tgz
mv plugin:realtime-v$RealTimeVersion.tgz realtime-v$RealTimeVersion.tgz
tar zxvf ./realtime-v$RealTimeVersion.tgz
mv /usr/src/realtime/ /var/www/cacti/plugins/
mkdir /var/www/cacti/plugins/rt_cache/
chown -R www-data /var/www/cacti/plugins/rt_cache/
rm -f /usr/src/realtime-v$RealTimeVersion.tgz
}

## LoginMod plugin installation
#
install_loginmod(){
cd /usr/src/
wget http://docs.cacti.net/_media/plugin:loginmod-latest.tgz
mv plugin:loginmod-latest.tgz loginmod-latest.tgz
tar zxvf ./loginmod-latest.tgz
mv /usr/src/loginmod-$LoginModVersion /var/www/cacti/plugins/loginmod/
rm -f /usr/src/loginmod-latest.tgz
}

## Monitor plugin installation
#
install_monitor(){
cd /usr/src/
wget http://docs.cacti.net/_media/plugin:monitor-v$MonitorVersion.tgz
mv plugin:monitor-v$MonitorVersion.tgz monitor-v$MonitorVersion.tgz
tar zxvf ./monitor-v$MonitorVersion.tgz
mv /usr/src/monitor /var/www/cacti/plugins/
rm -f /usr/src/monitor-v$MonitorVersion.tgz
}

## Nectar plugin installation
#
install_nectar(){
cd /usr/src/
wget http://docs.cacti.net/_media/plugin:nectar-v$NectarVersion.tgz
mv plugin:nectar-v$NectarVersion.tgz nectar-v$NectarVersion.tgz
tar zxvf ./nectar-v$NectarVersion.tgz
mv /usr/src/nectar /var/www/cacti/plugins/
rm -f /usr/src/nectar-v$NectarVersion.tgz
}

## SpikeKill plugin installation
#
install_spikekill(){
cd /usr/src/
wget http://docs.cacti.net/_media/plugin:spikekill-v$SpikeKillVersion.tgz
mv plugin:spikekill-v$SpikeKillVersion.tgz spikekill-v$SpikeKillVersion.tgz
tar zxvf ./spikekill-v$SpikeKillVersion.tgz
mv /usr/src/spikekill /var/www/cacti/plugins/
rm -f /usr/src/spikekill-v$SpikeKillVersion.tgz
}

## Thold plugin installation
#
install_thold(){
cd /usr/src/
wget http://cactiusers.org/downloads/thold.gzip -O thold.tar.gz
tar zxvf ./thold.tar.gz
mv /usr/src/thold /var/www/cacti/plugins/
rm -f /usr/src/thold.tar.gz
# For some reason restarting apache and MySQL make the Mysql Thold related errors in cacti logs vanish, so...
/etc/init.d/apache2 restart
/etc/init.d/mysql restart
}

## PHP NetworkWeatherMap plugin installation
#
install_weathermap(){
cd /usr/src/
apt-get install unzip php-pear -y
wget http://www.network-weathermap.com/files/php-weathermap-$WeatherMapVersion.zip
unzip ./php-weathermap-$WeatherMapVersion.zip
mv /usr/src/weathermap /var/www/cacti/plugins/weathermap/
rm -f /usr/src/php-weathermap-$WeatherMapVersion.zip
chown -R $SystemCactiUser:www-data /var/www/cacti/plugins/weathermap/output/
chown -R www-data:www-data /var/www/cacti/plugins/weathermap/configs/
# Adding a "strict" security policy to the WeatherMap editor
echo '### Some security on the phpweathermap editor
 <Directory /var/www/cacti/plugins/weathermap>
        <Files editor.php>
            Order Deny,Allow
            Deny from all
            Allow from 127.0.0.1
        </Files>
    </Directory>' >> /etc/apache2/httpd.conf
sed -i -e 's/$ENABLED=false;/$ENABLED=true;/' /var/www/cacti/plugins/weathermap/editor.php
/etc/init.d/apache2 restart
}

## Clog plugin installation
#
install_clog(){
cd /usr/src/
wget http://docs.cacti.net/_media/plugin:clog-v$ClogVersion.tgz
mv plugin:clog-v$ClogVersion.tgz clog-v$ClogVersion.tgz
tar zxvf ./clog-v$ClogVersion.tgz
mv /usr/src/clog /var/www/cacti/plugins/
rm -f /usr/src/clog-v$ClogVersion.tgz
}

## Some Apache and PHP Tweaking to make it quiet
#
quiet_lamp(){
#Silencing Apache
sed -i -e 's/ServerTokens Full/ServerTokens Prod/' /etc/apache2/conf.d/security
sed -i -e 's/ServerSignature On/ServerSignature Off/' /etc/apache2/conf.d/security
sed -i -e 's/TraceEnable On/TraceEnable Off/' /etc/apache2/conf.d/security
#Removing Apache unused mod
a2dismod autoindex
#Silencing PHP
sed -i -e 's/expose_php = On/expose_php = Off/' /etc/php5/apache2/php.ini
sed -i -e 's/display_errors = On/display_errors = Off/' /etc/php5/apache2/php.ini
#Removing unused PHP options
sed -i -e 's/allow_url_fopen = On/allow_url_fopen = Off/' /etc/php5/apache2/php.ini
sed -i -e 's/allow_url_include = On/allow_url_include = Off/' /etc/php5/apache2/php.ini
sed -i -e 's/register_argc_argv = On/register_argc_argv = Off/' /etc/php5/apache2/php.ini
sed -i -e 's/file_uploads = On/file_uploads = Off/' /etc/php5/apache2/php.ini
}

## Install of Apache ModSecurity in order to tighten your cacti server security
#
install_modsecurity(){
apt-get install libxml2-dev liblua5.1-0 lua5.1 apache2-threaded-dev build-essential -y
cd /usr/src/
wget http://www.modsecurity.org/download/modsecurity-apache_$ModSecurityVersion.tar.gz
tar zxvf modsecurity-apache_$ModSecurityVersion.tar.gz
cd modsecurity-apache_$ModSecurityVersion/apache2/
# Compilation
./configure && make && make install
rm -rf /usr/src/modsecurity-apache_$ModSecurityVersion*
# Apache Modsecurity activation
echo '
LoadFile /usr/lib/libxml2.so
LoadFile /usr/lib/liblua5.1.so.0
LoadModule security2_module /usr/lib/apache2/modules/mod_security2.so
' >> /etc/apache2/mods-available/mod-security2.load
a2enmod mod-security2
a2enmod unique_id
# Apache Mod security base setup
mkdir /etc/modsecurity2
cp /usr/src/modsecurity-apache_$ModSecurityVersion/rules/*.conf /etc/modsecurity2
echo '
Include /etc/modsecurity2/*.conf
' >> /etc/apache2/conf.d/mod-security2.conf
# Logs handling
mkdir /var/log/modsecurity2
sed -i -e 's/logs\//\/var\/log\/modsecurity2\//' /etc/modsecurity2/modsecurity_crs_10_config.conf
# CRS rules installation
cd /usr/src/
wget http://sourceforge.net/projects/mod-security/files/modsecurity-crs/0-CURRENT/modsecurity-crs_$ModSecurityCRSVersion.tar.gz
tar zxvf modsecurity-crs_$ModSecurityCRSVersion.tar.gz
mv /usr/src/modsecurity-crs_$ModSecurityCRSVersion/ /etc/modsecurity2/
rm -f /usr/src/modsecurity-crs_$ModSecurityCRSVersion.tar.gz
# base_rules ruleset activation
echo '
Include /etc/modsecurity2/modsecurity-crs_'$ModSecurityCRSVersion'/base_rules/*.conf' >> /etc/apache2/conf.d/mod-security2.conf
# Apache restarts
/etc/init.d/apache2 restart
}

## Pre install tests, check if the softwares to be installed are not already installed
#
if [ "$install_lamp" = 1 ]; 
	then
	ls /etc/apache2 &>/dev/null
	checkprev=$?
	if [ "$checkprev" = 0 ]; 
		then
		echo -e "\a"\#\#\#\#\#\#\#\#\# WARNING
		echo Apache has already been installed, script ends now!
		exit
	else
	install_lamp
	fi
fi

if [ "$install_cacti" = 1 ]; 
	then
	ls /var/www/cacti &> /dev/null
	checkprev=$?
	if [ "$checkprev" = 0 ]; 
		then
		echo -e "\a"\#\#\#\#\#\#\#\#\# WARNING
		echo Cacti v$CactiVersion has already been installed, script ends now!
		exit
	else
	install_cacti
	fi
fi

if [ "$patch_cacti" = 1 ]; 
	then
	checkprev=`find /var/www/cacti -regex ".*orig$"`
	if [ "$checkprev" != "" ]; 
		then
		echo -e "\a"\#\#\#\#\#\#\#\#\# WARNING
		echo Cacti has already been Patched, script ends now!
		exit
	else
	patch_cacti
	fi
fi

if [ "$setup_snmp_public" = 1 ]; 
	then
	cat /etc/snmp/snmpd.conf | grep "#com2sec paranoid" &> /dev/null
	checkprev=$?
	if [ "$checkprev" = 0 ]; 
		then
		echo -e "\a"\#\#\#\#\#\#\#\#\# WARNING
		echo SNMPD has already been setup, script ends now!
		exit
	else
	setup_snmp_public
	fi
fi

if [ "$install_spine" = 1 ]; 
	then
	ls /usr/local/spine/ &> /dev/null
	checkprev=$?
	if [ "$checkprev" = 0 ]; 
		then
		echo -e "\a"\#\#\#\#\#\#\#\#\# WARNING
		echo Spine v$SpineVersion has already been installed, script ends now!
		exit
	else
	install_spine
	fi
fi

if [ "$install_PA" = 1 ]; 
	then
	ls /var/www/cacti/plugins/ &> /dev/null
	checkprev=$?
	if [ "$checkprev" = 0 ]; 
		then
		echo -e "\a"\#\#\#\#\#\#\#\#\# WARNING
		echo PA v$PAVersion has already been installed, script ends now!
		exit
	else
	install_PA
	fi
fi

if [ "$install_settings" = 1 ]; 
	then
	ls /var/www/cacti/plugins/settings/ &> /dev/null
	checkprev=$?
	if [ "$checkprev" = 0 ]; 
		then
		echo -e "\a"\#\#\#\#\#\#\#\#\# WARNING
		echo Settings v$SettingsVersion has already been installed, script ends now!
		exit
	else
	install_settings
	fi
fi

if [ "$install_cycle" = 1 ]; 
	then
	ls /var/www/cacti/plugins/cycle/ &> /dev/null
	checkprev=$?
	if [ "$checkprev" = 0 ]; 
		then
		echo -e "\a"\#\#\#\#\#\#\#\#\# WARNING
		echo Cycle v$CycleVersion has already been installed, script ends now!
		exit
	else
	install_cycle
	fi
fi

if [ "$install_realtime" = 1 ]; 
	then
	ls /var/www/cacti/plugins/realtime/ &> /dev/null
	checkprev=$?
	if [ "$checkprev" = 0 ]; 
		then
		echo -e "\a"\#\#\#\#\#\#\#\#\# WARNING
		echo Realtime v$RealTimeVersion has already been installed, script ends now!
		exit
	else
	install_realtime
	fi
fi

if [ "$install_loginmod" = 1 ]; 
	then
	ls /var/www/cacti/plugins/loginmod/ &> /dev/null
	checkprev=$?
	if [ "$checkprev" = 0 ]; 
		then
		echo -e "\a"\#\#\#\#\#\#\#\#\# WARNING
		echo LoginMod v$LoginModVersion has already been installed, script ends now!
		exit
	else
	install_loginmod
	fi
fi

if [ "$install_monitor" = 1 ]; 
	then
	ls /var/www/cacti/plugins/monitor/ &> /dev/null
	checkprev=$?
	if [ "$checkprev" = 0 ]; 
		then
		echo -e "\a"\#\#\#\#\#\#\#\#\# WARNING
		echo Monitor v$MonitorVersion has already been installed, script ends now!
		exit
	else
	install_monitor
	fi
fi

if [ "$install_nectar" = 1 ]; 
	then
	ls /var/www/cacti/plugins/nectar/ &> /dev/null
	checkprev=$?
	if [ "$checkprev" = 0 ]; 
		then
		echo -e "\a"\#\#\#\#\#\#\#\#\# WARNING
		echo Nectar v$NectarVersion has already been installed, script ends now!
		exit
	else
	install_nectar
	fi
fi

if [ "$install_thold" = 1 ]; 
	then
	ls /var/www/cacti/plugins/thold/ &> /dev/null
	checkprev=$?
	if [ "$checkprev" = 0 ]; 
		then
		echo -e "\a"\#\#\#\#\#\#\#\#\# WARNING
		echo Thold v$TholdVersion has already been installed, script ends now!
		exit
	else
	install_thold
	fi
fi

if [ "$install_weathermap" = 1 ]; 
	then
	ls /var/www/cacti/plugins/weathermap/ &> /dev/null
	checkprev=$?
	if [ "$checkprev" = 0 ]; 
		then
		echo -e "\a"\#\#\#\#\#\#\#\#\# WARNING
		echo PHP NetworkWeatherMap v$WeatherMapVersion has already been installed, script ends now!
		exit
	else
	install_weathermap
	fi
fi

if [ "$install_clog" = 1 ]; 
	then
	ls /var/www/cacti/plugins/clog/ &> /dev/null
	checkprev=$?
	if [ "$checkprev" = 0 ]; 
		then
		echo -e "\a"\#\#\#\#\#\#\#\#\# WARNING
		echo Clog v$ClogVersion has already been installed, script ends now!
		exit
	else
	install_clog
	fi
fi

if [ "$install_spikekill" = 1 ]; 
	then
	ls /var/www/cacti/plugins/spikekill/ &> /dev/null
	checkprev=$?
	if [ "$checkprev" = 0 ]; 
		then
		echo -e "\a"\#\#\#\#\#\#\#\#\# WARNING
		echo SpikeKill v$SpikeKillVersion has already been installed, script ends now!
		exit
	else
	install_spikekill
	fi
fi

if [ "$quiet_lamp" = 1 ]; 
	then
	cat /etc/apache2/conf.d/security | grep "ServerTokens Prod" &> /dev/null
	checkprev=$?
	if [ "$checkprev" = 0 ]; 
		then
		echo -e "\a"\#\#\#\#\#\#\#\#\# WARNING
		echo LAMP server has already been setup to be more quiet, script ends now!
		exit
	else
	quiet_lamp
	fi
fi

if [ "$install_modsecurity" = 1 ]; 
	then
	ls /etc/modsecurity2/ &> /dev/null
	checkprev=$?
	if [ "$checkprev" = 0 ]; 
		then
		echo -e "\a"\#\#\#\#\#\#\#\#\# WARNING
		echo Modsecurity v$ModSecurityVersion with CRS v$ModSecurityCRSVersion has already been installed, script ends now!
		exit
	else
	install_modsecurity
	fi
fi

## This will retrieve your eth0 IP address, it's used at the very end of the script,
#
NetworkInterface="eth0"		# Main network interface
MainIP=`ifconfig $NetworkInterface | grep 'inet adr:' | cut -d: -f2 | awk '{ print $1}'`

## Let's go
#
echo ###############
echo Point your browser to : http://$MainIP/cacti
echo Remember to activate the PA for admin user, and to enable the plugins.
