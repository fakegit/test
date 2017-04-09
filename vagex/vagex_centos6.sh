#安装Xfce桌面
wget https://raw.githubusercontent.com/catonisland/Vagex-For-CentOS-6/master/epel-release-6-8.noarch.rpm
rpm -ivh epel-release-6-8.noarch.rpm 
yum search xfce
yum groupinfo xfce
yum groupinstall -y xfce
#安装tigervnc客户端和tigervnc-server服务器
yum install -y tigervnc tigervnc-server
#写入配置文件
cat > /etc/sysconfig/vncservers<<EOF
VNCSERVERS="1:root"
VNCSERVERARGS[1]="-geometry 800x600"
EOF
#创建密码
echo
echo
echo "You will be requested to enter a password not less than six digits."
vncpasswd
#启动服务
vncserver
#写入配置文件
cat << EOF > /root/.vnc/xstartup
#!/bin/sh
# Uncomment the following two lines for normal desktop:
unset SESSION_MANAGER
#exec /etc/X11/xinit/xinitrc
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
xsetroot -solid grey
vncconfig -iconic &
#xterm -geometry 80x24+10+10 -ls -title "$VNCDESKTOP Desktop" &
#twm &
startxfce4 &
EOF
#配置权限
chmod +x /root/.vnc/xstartup
#重启
service vncserver restart
#开机启动
chkconfig vncserver on
#安装Firefox和中文支持
yum -y install firefox
yum -y groupinstall chinese-support
#将下面EOF之前的数据覆盖写入/root/reboot.sh
cat << EOF > /root/reboot.sh
#!/bin/bash
#VPS重启
rm -rf /root/.vnc/*.log
reboot
echo
EOF
cat << EOF > /root/firefox.sh
#!/bin/bash
#Firefox启动
#pkill -9 firefox
killall firefox
#vncserver  暂时注释掉，测试ebesucher状态
export DISPLAY=:1;firefox
echo
EOF
#将下面EOF之前的数据覆盖写入/root/refirefox.sh
cat << EOF > /root/refirefox.sh
#!/bin/bash
#Firefox重启
rm -rf /root/.vnc/*.log
#pkill -9 firefox
killall firefox
export DISPLAY=:1;firefox
echo
EOF
#添加权限
chmod a+x /root/reboot.sh
chmod a+x /root/firefox.sh
chmod a+x /root/refirefox.sh
#设定定时任务重启VPS和Firefox
#将下面EOF之前的数据追加写入/root/root.cron文件
cat << EOF > /root/root.cron
#每隔10分钟运行一次/root/refirefox.sh
#03 * * * * bash /root/refirefox.sh
#13 * * * * bash /root/refirefox.sh
#23 * * * * bash /root/refirefox.sh
#33 * * * * bash /root/refirefox.sh
#43 * * * * bash /root/refirefox.sh
#53 * * * * bash /root/refirefox.sh
#每个小时的0分运行/root/reboot.sh，每个小时的2分运行/root/refirefox.sh
00 * * * * bash /root/reboot.sh
02 * * * * bash /root/firefox.sh
EOF
#安装crontab文件到/var/spool/cron文件夹，上面的写入操作+该命令==crontab -e
crontab /root/root.cron
rm /root/root.cron

