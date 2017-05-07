#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
clear
echo '
    ************************************************************
                                                                                                 
                           本脚本在debian8x32上通过测试  
                           64位无法安装迅雷远程下载 
                           Debian8锐速应该不支持
                                                                                                  
    ************************************************************
                                
'
	if [ -f /etc/redhat-release ];then
        OS=CentOS
 
    elif [ ! -z "`cat /etc/issue | grep bian`" ];then
        OS=Debian
 
    elif [ ! -z "`cat /etc/issue | grep Ubuntu`" ];then
        OS=Ubuntu
    else
        echo "Not support OS, Please reinstall OS and retry!"
        exit 1
    fi
 
 
function update(){
	if [ "$OS" == 'CentOS' ]; then
		echo "Centos凑什么热闹！换系统去"
	else
		echo "准备更新清理系统"
		sleep 5
		apt-get update -y >/dev/null 2>&1
		apt-get remove http* apache* -y >/dev/null 2>&1
		apt-get install vim wget unzip tar screen -y >/dev/null 2>&1
	fi
}
 
 
function setconfig(){
echo 
 echo -e "请选择模式（默认：域名模式）" 
 echo -e "1：公网ip模式" 
 echo -e "2：域名模式" 
 read moshi 
  if [[ ${moshi} == '1' ]]
 then 
read -p '请输入你的IP地址： ' dl;
pan=${dl}
[ -z "$dl" ] && echo "你是猪吗，让你填外网ip地址 已经给你设置为127.0.0.1，自己改" && dl="127.0.0.1"
[ -z "$pan" ] && echo "你是猪吗，让你填外网ip地址 已经给你设置为127.0.0.1，自己改" && pan="127.0.0.1"
read -p '请输入离线下载地址端口： ' port1;
[ -z "$port1" ] && echo "你是猪吗，让你填端口 已经给你设置为8546，自己改" && port1="8546"
read -p '请输入网盘观看地址端口： ' port2;
[ -z "$port2" ] && echo "你是猪吗，让你填端口 已经给你设置为8547，自己改" && port2="8547"
sleep 3
else
read -p '请输入域名作为离线下载地址（例如 dl.xxx.com）： ' dl;
read -p '请输入域名作为网盘下载地址（例如 pan.xxx.com）： ' pan;
read -p '请输入域名作为transmission管理地址（例如 tr.xxx.com）： ' tr;
port1='80'; 
port2='80'; 
ver="latest"
echo "安装什么版本(latest / stable) 的transmission(默认stable):"
echo -e "1：latest" 
echo -e "2：stable" 
read  ver
if [ ${ver} = "1" ]; then
	ver="latest"
else
  ver="stable"
fi
# CONFIGURATION
username=""
read -p "输入transmission的username(默认123):" username
if [ "$username" = "" ]; then
	username="123"
fi
password=""
read -p "输入transmission的password(默认123):" password
if [ "$password" = "" ]; then
	password="123"
fi
transport=""
read -p "输入transmission的port(默认2048):" transport
if [ "$transport" = "" ]; then
	transport="2048"
fi
token=""
read -p "输入RPC授权令牌(默认不设置):" token
if [ "$token" = "" ]; then
	tokenset="#rpc-secret= <TOKEN>"
	else
	tokenset="rpc-secret=${token}"
fi


[ -z "$dl" ] && echo "你是猪吗，让你填域名 已经给你设置为www.baidu.com，自己改" && dl="www.baidu.com"
[ -z "$pan" ] && echo "你是猪吗，让你填域名 已经给你设置为www.baidu.com，自己改" && pan="www.baidu.com"
sleep 3
fi
}
 
function lep(){
echo '开始安装NGINX PHP环境 这里没有卡住，时间由你服务器性能 网络决定'
sleep 2
echo "deb ftp://ftp.deb-multimedia.org jessie main" >>/etc/apt/sources.list 
apt-get update -y >/dev/null 2>&1
apt-get install -y --force-yes deb-multimedia-keyring >/dev/null 2>&1
apt-get update -y >/dev/null 2>&1
apt-get install -y -t jessie nginx php5 php5-fpm php5-gd ffmpeg unzip >/dev/null 2>&1
}
 
function makeconfig(){
echo '开始创建配置文件'
sleep 5
 
mkdir -p /home/wwwroot/${dl}:${port1}
mkdir -p /home/wwwroot/${pan}:${port2}
#mkdir -p /home/wwwroot/${tr}:${transport}
#chmod 777 /home/wwwroot/${tr}:${transport}
chmod 777 /home/wwwroot/${pan}:${port2}
cd /etc/nginx/
rm -rf fastcgi_params
echo '
fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
fastcgi_param  REDIRECT_STATUS    200;
fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;
fastcgi_param  QUERY_STRING       $query_string;
fastcgi_param  REQUEST_METHOD     $request_method;
fastcgi_param  CONTENT_TYPE       $content_type;
fastcgi_param  CONTENT_LENGTH     $content_length;
fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
fastcgi_param  REQUEST_URI        $request_uri;
fastcgi_param  DOCUMENT_URI       $document_uri;
fastcgi_param  DOCUMENT_ROOT      $document_root;
fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
fastcgi_param  SERVER_PROTOCOL    $server_protocol;
fastcgi_param  HTTPS              $https if_not_empty;
fastcgi_param  REMOTE_ADDR        $remote_addr;
fastcgi_param  REMOTE_PORT        $remote_port;
fastcgi_param  SERVER_ADDR        $server_addr;
fastcgi_param  SERVER_PORT        $server_port;
fastcgi_param  SERVER_NAME        $server_name;
' >> fastcgi_params
 
cd conf.d
 
echo "
server {
    listen ${port1};
    server_name ${dl};
    root /home/wwwroot/${dl}:${port1};
 
    location / {
        index index.html index.php;
    }
    location ~* \.php$ {
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_split_path_info ^(.+\.php)(.*)$;
        include fastcgi_params;
    }
}
" >> ${dl}:${port1}.conf
 
echo "
server {
    listen ${port2};
    server_name ${pan};
    root /home/wwwroot/${pan}:${port2};
 
    location / {
        index index.html index.php /_h5ai/public/index.php;
    }
    location ~* \.php$ {
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_split_path_info ^(.+\.php)(.*)$;
        include fastcgi_params;
    }
}
" >> ${pan}:${port2}.conf
 

 echo "
server {
    listen ${port2};
#    listen ${transport};
    server_name ${tr};
#    root /home/wwwroot/${tr}:${transport};
    root /usr/share/transmission/web;
 
    location / {
        index index.html index.php ;
    }
    location ~* \.php$ {
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_split_path_info ^(.+\.php)(.*)$;
        include fastcgi_params;
    }
}
" >> ${tr}:${transport}.conf

cd
 
mkdir /root/.aria2
 
cat >/root/.aria2/aria2.conf <<EOF
## '#'开头为注释内容, 选项都有相应的注释说明, 根据需要修改 ##
## 被注释的选项填写的是默认值, 建议在需要修改时再取消注释  ##
 
## 文件保存相关 ##
 
# 文件的保存路径(可使用绝对路径或相对路径), 默认: 当前启动位置
dir=/home/wwwroot/${pan}:${port2}
# 启用磁盘缓存, 0为禁用缓存, 需1.16以上版本, 默认:16M
#disk-cache=32M
# 文件预分配方式, 能有效降低磁盘碎片, 默认:prealloc
# 预分配所需时间: none < falloc ? trunc < prealloc
# falloc和trunc则需要文件系统和内核支持
# NTFS建议使用falloc, EXT3/4建议trunc, MAC 下需要注释此项
file-allocation=none
# 断点续传
continue=true
 
## 下载连接相关 ##
 
# 最大同时下载任务数, 运行时可修改, 默认:5
max-concurrent-downloads=10
# 同一服务器连接数, 添加时可指定, 默认:1
max-connection-per-server=10
# 最小文件分片大小, 添加时可指定, 取值范围1M -1024M, 默认:20M
# 假定size=10M, 文件为20MiB 则使用两个来源下载; 文件为15MiB 则使用一个来源下载
min-split-size=5M
# 单个任务最大线程数, 添加时可指定, 默认:5
split=20
# 整体下载速度限制, 运行时可修改, 默认:0
#max-overall-download-limit=0
# 单个任务下载速度限制, 默认:0
#max-download-limit=0
# 整体上传速度限制, 运行时可修改, 默认:0
#max-overall-upload-limit=0
# 单个任务上传速度限制, 默认:0
#max-upload-limit=0
# 禁用IPv6, 默认:false
disable-ipv6=true
 
## 进度保存相关 ##
 
# 从会话文件中读取下载任务
input-file=/root/aria2.session
# 在Aria2退出时保存`错误/未完成`的下载任务到会话文件
save-session=/root/aria2.session
# 定时保存会话, 0为退出时才保存, 需1.16.1以上版本, 默认:0
save-session-interval=60
 
## RPC相关设置 ##
 
# 启用RPC, 默认:false
enable-rpc=true
# 允许所有来源, 默认:false
rpc-allow-origin-all=true
# 允许非外部访问, 默认:false
rpc-listen-all=true
# 事件轮询方式, 取值:[epoll, kqueue, port, poll, select], 不同系统默认值不同
#event-poll=select
# RPC监听端口, 端口被占用时可以修改, 默认:6800
rpc-listen-port=6800
# 设置的RPC授权令牌, v1.18.4新增功能, 取代 --rpc-user 和 --rpc-passwd 选项
${tokenset}
# 设置的RPC访问用户名, 此选项新版已废弃, 建议改用 --rpc-secret 选项
#rpc-user= <username>
# 设置的RPC访问密码, 此选项新版已废弃, 建议改用 --rpc-secret 选项
#rpc-passwd= <password>
 
## BT/PT下载相关 ##
 
# 当下载的是一个种子(以.torrent结尾)时, 自动开始BT任务, 默认:true
#follow-torrent=true
# BT监听端口, 当端口被屏蔽时使用, 默认:6881-6999
listen-port=51413
# 单个种子最大连接数, 默认:55
#bt-max-peers=55
# 打开DHT功能, PT需要禁用, 默认:true
enable-dht=true
# 打开IPv6 DHT功能, PT需要禁用
#enable-dht6=false
# DHT网络监听端口, 默认:6881-6999
#dht-listen-port=6881-6999
# 本地节点查找, PT需要禁用, 默认:false
#bt-enable-lpd=true
# 种子交换, PT需要禁用, 默认:true
enable-peer-exchange=true
# 每个种子限速, 对少种的PT很有用, 默认:50K
#bt-request-peer-speed-limit=50K
# 客户端伪装, PT需要
peer-id-prefix=-TR2770-
user-agent=Transmission/2.77
# 当种子的分享率达到这个数时, 自动停止做种, 0为一直做种, 默认:1.0
seed-ratio=0.1
# 强制保存会话, 即使任务已经完成, 默认:false
# 较新的版本开启后会在任务完成后依然保留.aria2文件
#force-save=false
# BT校验相关, 默认:true
#bt-hash-check-seed=true
# 继续之前的BT任务时, 无需再次校验, 默认:false
bt-seed-unverified=true
# 保存磁力链接元数据为种子文件(.torrent文件), 默认:false
bt-save-metadata=false
EOF
 
echo '' > /root/aria2.session
#创建启动Aria2c的脚本
#echo  'screen -dmS aria2 aria2c --conf-path=/root/.aria2/aria2.conf -c' > /root/aria2start.sh
#开机运行脚本
sed -i '1i\screen -dmS aria2 aria2c --conf-path=/root/.aria2/aria2.conf -c' /etc/rc.local
}
 
 function xunlei(){
#安装迅雷远程下载
echo '安装迅雷远程下载'
mkdir /home/xunlei
cd /home/xunlei
wget http://dl.138vps.com/software/Xware1.0.19_x86_32_glibc.zip
unzip Xware1.0.19_x86_32_glibc.zip
mkdir /mnt/xunlei
chmod 0777 /mnt/xunlei
mount --bind /home/wwwroot/${pan}:${port2}/ /mnt/xunlei
chmod -R 777 /home/xunlei/
chown -hR root:root /home/xunlei
#/home/xunlei/portal
#echo '复制 ACTIVE CODE 到 http://yuancheng.xunlei.com/ ，登陆迅雷账号，输入绑定码'
#echo "/home/xunlei/portal"  >> /etc/rc.d/rc.local
sed -i '1i\/home/xunlei/portal' /etc/rc.local

}

function xunleistart(){
/home/xunlei/portal
#echo '复制 ACTIVE CODE 到 http://yuancheng.xunlei.com/  登陆迅雷账号，输入绑定码'
}

function main(){
echo '开始安装主程序'
apt-get install aria2  -y
cd /home/wwwroot/${dl}:${port1}
wget --no-check-certificate https://codeload.github.com/mayswind/AriaNg-DailyBuild/zip/master -O AriaNg.zip >/dev/null 2>&1
#wget --no-check-certificate https://raw.githubusercontent.com/godzlalala/onlineplayer/master/yaaw.zip >/dev/null 2>&1
#unzip yaaw.zip >/dev/null 2>&1
unzip AriaNg.zip >/dev/null 2>&1
mv AriaNg-DailyBuild-master/* .
rm -rf AriaNg-DailyBuild-master/
cd /home/wwwroot/${pan}:${port2}
wget --no-check-certificate https://raw.githubusercontent.com/godzlalala/onlineplayer/master/_h5ai.zip >/dev/null 2>&1
unzip _h5ai.zip >/dev/null 2>&1
chmod 777 /home/wwwroot/${pan}:${port2}/_h5ai/public/cache 
chmod 777 /home/wwwroot/${pan}:${port2}/_h5ai/private/cache

screen -dmS aria2 aria2c --conf-path=/root/.aria2/aria2.conf -c

}
 
 
function startc(){
echo '配置完毕，启动程序'
#screen -dmS aria2  aria2c --enable-rpc --rpc-listen-all=true --rpc-allow-origin-all -c >/dev/null 2>&1
bash /root/aria2start.sh
service nginx restart >/dev/null 2>&1
service php5-fpm restart >/dev/null 2>&1
 
}
 
 function transmission(){
 cd
#安装transmission
 # START
if [ "$ver" = "latest" ]; then
	echo "deb http://ftp.debian.org/debian/ sid main" >> /etc/apt/sources.list
	echo "deb http://ftp.debian.org/debian/ experimental main" >> /etc/apt/sources.list
	apt-get update
	apt-get -t experimental install transmission-daemon -y
	echo "APT::Default-Release \"stable\";" >> /etc/apt/apt.conf.d/71distro
else
	apt-get update
	apt-get -y install transmission-daemon
fi

# SETTINGS.JSON
/etc/init.d/transmission-daemon stop
#wget http://dadi.me/wp-content/uploads/dir/Transmission/settings.json
#mv -f settings.json /var/lib/transmission-daemon/info/
#sed -i 's/^.*rpc-username.*/"rpc-username": "'$(echo $username)'",/' /var/lib/transmission-daemon/info/settings.json
#sed -i 's/^.*rpc-password.*/"rpc-password": "'$(echo $password)'",/' /var/lib/transmission-daemon/info/settings.json
#sed -i 's/^.*rpc-port.*/"rpc-port": '$(echo $transport)',/' /var/lib/transmission-daemon/info/settings.json
cat >  /var/lib/transmission-daemon/info/settings.json<<EOF
{
    "alt-speed-down": 50, 
    "alt-speed-enabled": false, 
    "alt-speed-time-begin": 540, 
    "alt-speed-time-day": 127, 
    "alt-speed-time-enabled": false, 
    "alt-speed-time-end": 1020, 
    "alt-speed-up": 50, 
    "bind-address-ipv4": "0.0.0.0", 
    "bind-address-ipv6": "::", 
    "blocklist-enabled": false, 
    "dht-enabled": true, 
    "download-dir": "/home/wwwroot/${pan}:${port2}", 
    "encryption": 1, 
    "incomplete-dir": "/home/transmission/Downloads", 
    "incomplete-dir-enabled": false, 
    "lazy-bitfield-enabled": true, 
    "lpd-enabled": false, 
    "message-level": 2, 
    "open-file-limit": 32, 
    "peer-limit-global": 240, 
    "peer-limit-per-torrent": 60, 
    "peer-port": 51413, 
    "peer-port-random-high": 65535, 
    "peer-port-random-low": 49152, 
    "peer-port-random-on-start": false, 
    "peer-socket-tos": 0, 
    "pex-enabled": true, 
    "port-forwarding-enabled": true, 
    "preallocation": 1, 
    "proxy": "", 
    "proxy-auth-enabled": false, 
    "proxy-auth-password": "", 
    "proxy-auth-username": "", 
    "proxy-enabled": false, 
    "proxy-port": 80, 
    "proxy-type": 0, 
    "ratio-limit": 2.0000, 
    "ratio-limit-enabled": false, 
    "rename-partial-files": true, 
    "rpc-authentication-required": true, 
    "rpc-bind-address": "0.0.0.0", 
    "rpc-enabled": true, 
    "rpc-password": "${password}", 
    "rpc-port": ${transport}, 
    "rpc-username": "${username}", 
    "rpc-whitelist": "127.0.0.1", 
    "rpc-whitelist-enabled": false, 
    "script-torrent-done-enabled": false, 
    "script-torrent-done-filename": "", 
    "speed-limit-down": 100, 
    "speed-limit-down-enabled": false, 
    "speed-limit-up": 100, 
    "speed-limit-up-enabled": false, 
    "start-added-torrents": true, 
    "trash-original-torrent-files": false, 
    "umask": 18, 
    "upload-slots-per-torrent": 14
}
EOF
wget https://github.com/ronggang/transmission-web-control/raw/master/release/tr-control-easy-install-en-http.sh --no-check-certificate
bash tr-control-easy-install-en-http.sh
 
/etc/init.d/transmission-daemon start
}
 
function serverspeeder(){
cd
read -p '是否安装锐速。（输入y安装，其他不安装）不一定支持你的内核' isspeeder;
echo '支持内核请查看https://www.91yun.org/wp-content/plugins/91yun-serverspeeder/systemlist.html '
if [ ${isspeeder} == 'y' ];then
	wget -N --no-check-certificate https://raw.githubusercontent.com/91yun/serverspeeder/master/serverspeeder-all.sh && bash serverspeeder-all.sh
	wget -N --no-check-certificate https://raw.githubusercontent.com/godzlalala/start/master/rs.sh
	mv rs.sh rs
	chmod +x rs
else  
	echo '你选择不安装锐速，如需要可以执行 ./yundebian8.sh serverspeeder 来安装'
fi
}
 
function installover(){
 
echo "
    *************************************************************
    *                                                           *
    *                        程序安装完毕                       *
           aria2离线下载域名http://${dl}:${port1}    
           在线观看域名http://${pan}:${port2}    
           Transmission 管理页面: http://${tr}:${transport}
           Transmission: ${username}
           Transmission: ${password}                        
离线下载配置文件地址/etc/nginx/conf.d/${dl}:${port1}.conf
在线观看配置文件地址/etc/nginx/conf.d/${pan}:${port2}.conf
Transmission配置文件地址/etc/nginx/conf.d/${tr}:${transport}.conf
Transmission web配置文件地址/etc/nginx/conf.d/${tr}:${transport}.conf
				./rs start 启动锐速
				./rs stop 停止锐速
				./rs restart 重启锐速
				./rs status 查看锐速状态
				./rs config 更改锐速配置文件
			    执行一下两行代码卸载锐速
		chattr -i /serverspeeder/etc/apx* 
		/serverspeeder/bin/serverSpeeder.sh uninstall -f
		   
    *                                                           *
    *************************************************************
"
 
}
 
function run(){
starttime=`date +%s`
update
setconfig
lep
transmission
makeconfig
main
xunlei
serverspeeder
startc
installover
stop=`date +%s`
echo " 脚本总共运行了  $[ stop - starttime ] 秒"
xunleistart
}
 
if [ ! -n "$1" ]; then
 run
elif [ $1 = "run" ]; then
 run
elif [ $1 = "serverspeeder" ]; then
 serverspeeder
else 
	echo "
		未知命令，脚本退出
	"
	exit 1
fi
