#脚本写入到gv.sh文件，curl更换为自己的
cat << EOF > gv.sh
for (( i=1; i>0; i++ ))
do
      curl 'https://www.google.com/voice/b/0/service/post' -H 'origin: https://www.google.com' -H 'dnt: 1' -H 'accept-encoding: gzip, deflate, br' -H 'accept-language: zh-CN,zh;q=0.8,en;q=0.6' -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.95 Safari/537.36' -H 'content-type: application/x-www-form-urlencoded;charset=UTF-8' -H 'accept: */*' -H 'referer: https://www.google.com/voice/b/0' -H 'authority: www.google.com' -H 'cookie: gv=.........; GV_NR=1;-eVupmL6qR...........ncdG7vO' --data 'sid=...' --compressed
      sleep 2s
done
EOF

#nohup命令(即no hang up)脱离终端后台运行shell
nohup bash ./gv.sh &   #会输出到当前目录的nohup.out文件
#当shell中提示了nohup成功后还需要按终端上键盘任意键退回到shell输入命令窗口
#然后通过在shell中输入exit来退出终端
#否则会断掉该命令所对应的session，导致nohup对应的进程被通知需要一起shutdown
#使用 jobs  查看任务 
#使用 fg %n 关闭任务

#安装远程桌面已便获得本机的curl(非必须)，使用Windows的mstsc连接
#因centos和Debian的vnc有问题无法解决所以又折腾的Ubuntu
apt-get update
apt-get -y install xrdp
apt-get update
apt-get -y install vnc4server
apt-get update
apt-get -y install xubuntu-desktop
#修改配置文件避免桌面间不兼容导致的无画面
echo "xfce4-session" > ~/.xsession
service xrdp restart
#安装Chrome
#32位
wget https://dl.google.com/linux/direct/google-chrome-stable_current_i386.deb
sudo dpkg -i google-chrome-stable_current_i386.deb
#64位
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
