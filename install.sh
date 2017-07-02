#!/bin/bash

# Copyright (c) 2015, Bob Tidey
# All rights reserved.

# Redistribution and use, with or without modification, are permitted provided
# that the following conditions are met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Neither the name of the copyright holder nor the
#      names of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Description
# This script installs a browser-interface to control the RPi Cam. It can be run
# on any Raspberry Pi with a newly installed raspbian and enabled camera-support.
# RPI_Cam_Web_Interface installer by Silvan Melchior
# Edited by jfarcher to work with github
# Edited by slabua to support custom installation folder
# Additions by btidey, miraaz, gigpi
# Rewritten and split up by Bob Tidey 

#Debug enable next 3 lines
exec 5> install.txt
BASH_XTRACEFD="5"
set -x

cd $(dirname $(readlink -f $0))

if [ $(dpkg-query -W -f='${Status}' "dialog" 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  sudo apt-get install -y dialog
fi

# Terminal colors
color_red="tput setaf 1"
color_green="tput setaf 2"
color_reset="tput sgr0"

# Version stuff moved out functions as we need it more when one time.
versionfile="./www/config.php"
version=$(cat $versionfile | grep "'APP_VERSION'" | cut -d "'" -f4)
backtitle="Copyright (c) 2015, Bob Tidey. RPi Cam $version"

# Config options located in ./config.txt. In first run script makes that file for you.
if [ ! -e ./config.txt ]; then
      sudo echo "#This is config file for main installer. Put any extra options in here." > ./config.txt
      sudo echo "rpicamdir=\"html\"" >> ./config.txt
      sudo echo "webserver=\"apache\"" >> ./config.txt
      sudo echo "webport=\"80\"" >> ./config.txt
      sudo echo "user=\"\"" >> ./config.txt
      sudo echo "webpasswd=\"\"" >> ./config.txt
      sudo echo "autostart=\"yes\"" >> ./config.txt
      sudo echo "" >> ./config.txt
      sudo chmod 664 ./config.txt
fi

source ./config.txt
rpicamdirold=$rpicamdir
if [ ! "${rpicamdirold:0:1}" == "" ]; then
   rpicamdirold=/$rpicamdirold
fi


#Allow for a quiet install
rm exitfile.txt >/dev/null 2>&1
if [ $# -eq 0 ] || [ "$1" != "q" ]; then
   exec 3>&1
   dialog                                         \
   --separate-widget $'\n'                        \
   --title "Configuration Options"    \
   --backtitle "$backtitle"					   \
   --form ""                                      \
   0 0 0                                          \
   "Cam subfolder:"        1 1   "$rpicamdir"   1 32 15 0  \
   "Autostart:(yes/no)"    2 1   "$autostart"   2 32 15 0  \
   "Webport:"              4 1   "$webport"     4 32 15 0  \
   "User:(blank=nologin)"  5 1   "$user"        5 32 15 0  \
   "Password:"             6 1   "$webpasswd"   6 32 15 0  \
   2>&1 1>&3 | {
      read -r rpicamdir
      read -r autostart
      read -r webserver
      read -r webport
      read -r user
      read -r webpasswd
   if [ -n "$webport" ]; then
      sudo echo "#This is edited config file for main installer. Put any extra options in here." > ./config.txt
      sudo echo "rpicamdir=\"$rpicamdir\"" >> ./config.txt
      sudo echo "webserver=\"$webserver\"" >> ./config.txt
      sudo echo "webport=\"$webport\"" >> ./config.txt
      sudo echo "user=\"$user\"" >> ./config.txt
      sudo echo "webpasswd=\"$webpasswd\"" >> ./config.txt
      sudo echo "autostart=\"$autostart\"" >> ./config.txt
      sudo echo "" >> ./config.txt
   else
      echo "exit" > ./exitfile.txt
   fi
   }
   exec 3>&-

   if [ -e exitfile.txt ]; then
      rm exitfile.txt
      exit
   fi

   source ./config.txt
fi

if [ ! "${rpicamdir:0:1}" == "" ]; then
   rpicamdirEsc="\\/$rpicamdir"
   rpicamdir=/$rpicamdir
else
   rpicamdirEsc=""
fi

fn_stop ()
{ # This is function stop
        sudo killall raspimjpeg
        sudo killall php
}

fn_reboot ()
{ # This is function reboot system
  dialog --title "You may need to reboot your system" --backtitle "$backtitle" --yesno "Do you want to reboot now?" 5 33
  response=$?
    case $response in
      0) sudo reboot;;
      1) dialog --title 'Reboot message' --colors --infobox "\Zb\Z1"'Pending system changes that require a reboot!' 4 28 ; sleep 2;;
      255) dialog --title 'Reboot message' --colors --infobox "\Zb\Z1"'Pending system changes that require a reboot!' 4 28 ; sleep 2;;
    esac
}


fn_apache ()
{
aconf="etc/apache2/sites-available/raspicam.conf"
cp $aconf.1 $aconf
if [ -e "\/$aconf" ]; then
   sudo rm "\/$aconf"
fi
if [ -e /etc/apache2/conf-available/other-vhosts-access-log.conf ]; then
   aotherlog="/etc/apache2/conf-available/other-vhosts-access-log.conf"
else
   aotherlog="/etc/apache2/conf.d/other-vhosts-access-log"
fi
tmpfile=$(mktemp)
sudo awk '/NameVirtualHost \*:/{c+=1}{if(c==1){sub("NameVirtualHost \*:.*","NameVirtualHost *:'$webport'",$0)};print}' /etc/apache2/ports.conf > "$tmpfile" && sudo mv "$tmpfile" /etc/apache2/ports.conf
sudo awk '/Listen/{c+=1}{if(c==1){sub("Listen.*","Listen '$webport'",$0)};print}' /etc/apache2/ports.conf > "$tmpfile" && sudo mv "$tmpfile" /etc/apache2/ports.conf
awk '/<VirtualHost \*:/{c+=1}{if(c==1){sub("<VirtualHost \*:.*","<VirtualHost *:'$webport'>",$0)};print}' $aconf > "$tmpfile" && sudo mv "$tmpfile" $aconf
sudo sed -i "s/<Directory\ \/var\/www\/.*/<Directory\ \/var\/www$rpicamdirEsc>/g" $aconf
if [ "$user" == "" ]; then
	sudo sed -i "s/AllowOverride\ .*/AllowOverride None/g" $aconf
else
   sudo htpasswd -b -c /usr/local/.htpasswd $user $webpasswd
	sudo sed -i "s/AllowOverride\ .*/AllowOverride All/g" $aconf
   if [ ! -e /var/www$rpicamdir/.htaccess ]; then
      sudo bash -c "cat > /var/www$rpicamdir/.htaccess" << EOF
AuthName "RPi Cam Web Interface Restricted Area"
AuthType Basic
AuthUserFile /usr/local/.htpasswd
Require valid-user
EOF
      sudo chown -R www-data:www-data /var/www$rpicamdir/.htaccess
   fi
fi
sudo mv $aconf /$aconf
if [ ! -e /etc/apache2/sites-enabled/raspicam.conf ]; then
   sudo ln -sf /$aconf /etc/apache2/sites-enabled/raspicam.conf
fi
sudo sed -i 's/^CustomLog/#CustomLog/g' $aotherlog
sudo a2dissite 000-default.conf >/dev/null 2>&1
sudo service apache2 restart
}

fn_autostart ()
{
tmpfile=$(mktemp)
sudo sed '/#START/,/#END/d' /etc/rc.local > "$tmpfile" && sudo mv "$tmpfile" /etc/rc.local
# Remove to growing plank lines.
sudo awk '!NF {if (++n <= 1) print; next}; {n=0;print}' /etc/rc.local > "$tmpfile" && sudo mv "$tmpfile" /etc/rc.local
if [ "$autostart" == "yes" ]; then
   if ! grep -Fq '#START RASPIMJPEG SECTION' /etc/rc.local; then
      sudo sed -i '/exit 0/d' /etc/rc.local
      sudo bash -c "cat >> /etc/rc.local" << EOF
#START RASPIMJPEG SECTION
mkdir -p /dev/shm/mjpeg
chown www-data:www-data /dev/shm/mjpeg
chmod 777 /dev/shm/mjpeg
sleep 4;su -c 'raspimjpeg > /dev/null 2>&1 &' www-data
#END RASPIMJPEG SECTION

exit 0
EOF
   else
      tmpfile=$(mktemp)
      sudo sed '/#START/,/#END/d' /etc/rc.local > "$tmpfile" && sudo mv "$tmpfile" /etc/rc.local
      # Remove to growing plank lines.
      sudo awk '!NF {if (++n <= 1) print; next}; {n=0;print}' /etc/rc.local > "$tmpfile" && sudo mv "$tmpfile" /etc/rc.local
   fi

fi
sudo chown root:root /etc/rc.local
sudo chmod 755 /etc/rc.local
}

#Main install)
fn_stop

#move old material if changing from a different install folder
if [ ! "$rpicamdir" == "$rpicamdirold" ]; then
   if [ -e /var/www$rpicamdirold/index.php ]; then
      sudo mv /var/www$rpicamdirold/* /var/www$rpicamdir
   fi
fi

sudo cp -r www/* /var/www$rpicamdir/
if [ -e /var/www$rpicamdir/index.html ]; then
   sudo rm /var/www$rpicamdir/index.html
fi

sudo apt-get install -y apache2 php5 php5-cli libapache2-mod-php5 gpac motion zip libav-tools
fn_apache

#Make sure user www-data has bash shell
sudo sed -i "s/^www-data:x.*/www-data:x:33:33:www-data:\/var\/www:\/bin\/bash/g" /etc/passwd

if [ ! -e /var/www$rpicamdir/FIFO ]; then
   sudo mknod /var/www$rpicamdir/FIFO p
fi
sudo chmod 666 /var/www$rpicamdir/FIFO

if [ ! -e /var/www$rpicamdir/FIFO1 ]; then
   sudo mknod /var/www$rpicamdir/FIFO1 p
fi
sudo chmod 666 /var/www$rpicamdir/FIFO1

if [ ! -e /var/www$rpicamdir/cam.jpg ]; then
   sudo ln -sf /run/shm/mjpeg/cam.jpg /var/www$rpicamdir/cam.jpg
fi

if [ -e /var/www$rpicamdir/status_mjpeg.txt ]; then
   sudo rm /var/www$rpicamdir/status_mjpeg.txt
fi
if [ ! -e /run/shm/mjpeg/status_mjpeg.txt ]; then
   echo -n 'halted' > /run/shm/mjpeg/status_mjpeg.txt
fi
sudo chown www-data:www-data /run/shm/mjpeg/status_mjpeg.txt
sudo ln -sf /run/shm/mjpeg/status_mjpeg.txt /var/www$rpicamdir/status_mjpeg.txt

sudo chown -R www-data:www-data /var/www$rpicamdir
sudo cp etc/sudoers.d/RPI_Cam_Web_Interface /etc/sudoers.d/
sudo chmod 440 /etc/sudoers.d/RPI_Cam_Web_Interface

sudo cp -r bin/raspimjpeg /opt/vc/bin/
sudo chmod 755 /opt/vc/bin/raspimjpeg
if [ ! -e /usr/bin/raspimjpeg ]; then
   sudo ln -s /opt/vc/bin/raspimjpeg /usr/bin/raspimjpeg
fi

sed -e "s/www/www$rpicamdirEsc/" etc/raspimjpeg/raspimjpeg.1 > etc/raspimjpeg/raspimjpeg
if [ `cat /proc/cmdline |awk -v RS=' ' -F= '/boardrev/ { print $2 }'` == "0x11" ]; then
   sed -i 's/^camera_num 0/camera_num 1/g' etc/raspimjpeg/raspimjpeg
fi
if [ -e /etc/raspimjpeg ]; then
   $color_green; echo "Your custom raspimjpg backed up at /etc/raspimjpeg.bak"; $color_reset
   sudo cp -r /etc/raspimjpeg /etc/raspimjpeg.bak
fi
sudo cp -r etc/raspimjpeg/raspimjpeg /etc/
sudo chmod 644 /etc/raspimjpeg
if [ ! -e /var/www$rpicamdir/raspimjpeg ]; then
   sudo ln -s /etc/raspimjpeg /var/www$rpicamdir/raspimjpeg
fi

sudo usermod -a -G video www-data
if [ -e /var/www$rpicamdir/uconfig ]; then
   sudo chown www-data:www-data /var/www$rpicamdir/uconfig
fi

fn_autostart

if [ -e /var/www$rpicamdir/uconfig ]; then
   sudo chown www-data:www-data /var/www$rpicamdir/uconfig
fi

fn_reboot
