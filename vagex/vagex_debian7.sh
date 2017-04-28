apt-get update
#安装桌面环境及VNC
apt-get -q -y --force-yes install tightvncserver xterm jwm mercurial libasound2-dev libcurl4-openssl-dev libnotify-dev libxt-dev libiw-dev mesa-common-dev autoconf2.13 yasm libidl-dev screen unzip bzip2 nano
apt-get install iceweasel
#wget http://atomstar.eu.org/eb/vncxstartup.txt http://atomstar.eu.org/eb/vncserverinit.txt
#启动VNC，第一次需设置密码
vncserver
#VNC配置
cat > /root/.vnc/xstartup<<EOF
#!/bin/sh
# Uncomment the following two lines for normal desktop:
# unset SESSION_MANAGER
# exec /etc/X11/xinit/xinitrc
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
xsetroot -solid grey
vncconfig -iconic &
x-terminal-emulator -geometry 80x24+10+10 -ls -title "$VNCDESKTOP Desktop" &
x-window-manager &
startjwm &
firefox --display=:1
EOF
chmod +x ~/.vnc/xstartup
cat > /root/.vnc/xstartup<<EOF
### BEGIN INIT INFO
# Provides: vncserver
# Required-Start: $remote_fs $syslog
# Required-Stop: $remote_fs $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Start daemon at boot time
# Description: Enable service provided by daemon.
### END INIT INFO
PATH="$PATH:/usr/X11R6/bin/"
# The Username:Group that will run VNC
export USER="root"
#${RUNAS}
# The display that VNC will use
DISPLAY="1"
# Color depth (between 8 and 32)
DEPTH="16"
# The Desktop geometry to use.
#GEOMETRY="x"
GEOMETRY="1024x768"
#You Can Choice GEOMETRY="1024x768" && GEOMETRY="1280x1024"
# The name that the VNC Desktop will have.
NAME="Vncserver"
OPTIONS="-name ${NAME} -depth ${DEPTH} -geometry ${GEOMETRY} :${DISPLAY}"
. /lib/lsb/init-functions
case "$1" in
start)
su ${USER} -c "/usr/bin/vncserver ${OPTIONS}"
;;
stop)
su ${USER} -c "/usr/bin/vncserver -kill :${DISPLAY}"
;;
restart)
$0 stop
$0 start
;;
esac
exit 0
EOF
chmod +x /etc/init.d/vncserver
update-rc.d vncserver defaults
#可以安装Firefox的源
#echo -e "\ndeb http://downloads.sourceforge.net/project/ubuntuzilla/mozilla/apt all main" | sudo tee -a /etc/apt/sources.list > /dev/null
#apt-key adv --recv-keys --keyserver keyserver.ubuntu.com C1289A29
#apt-get update
# Debian源
#echo -e "\ndeb http://ftp.cn.debian.org/debian wheezy main contrib non-free" | sudo tee -a /etc/apt/sources.list > /dev/null
#或者
#echo -e "\ndeb http://ftp.debian.org/debian wheezy main contrib non-free" | sudo tee -a /etc/apt/sources.list > /dev/null
#apt-get update
#手动安装flashplay
mkdir flash
#32位
wget -P ./flash https://fpdownload.adobe.com/get/flashplayer/pdc/25.0.0.148/flash_player_npapi_linux.i386.tar.gz
tar -xzf ./flash/flash_player_npapi_linux.i386.tar.gz  -C ./flash
#64位
#wget -P ./flash https://fpdownload.adobe.com/get/flashplayer/pdc/25.0.0.148/flash_player_npapi_linux.x86_64.tar.gz
#tar -xzf ./flash/flash_player_npapi_linux.x86_64.tar.gz  -C ./flash
mkdir /root/.mozilla/plugins/
mv ./flash/usr/* /usr
cp ./flash/libflashplayer.so /root/.mozilla/plugins/
mv ./flash/libflashplayer.so /usr/lib/flashplugin-nonfree
update-alternatives --quiet --install /usr/lib/mozilla/plugins/flash-mozilla.so flash-mozilla.so /usr/lib/flashplugin-nonfree/libflashplayer.so 50
echo 'should return “ /usr/lib/flashplugin-nonfree/libflashplayer.so ”'
update-alternatives --list flash-mozilla.so

