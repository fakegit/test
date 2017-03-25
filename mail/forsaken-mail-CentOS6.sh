#安装git
yum install git -y

#安装nvm
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

#安装nodejs和 npm
nvm install 6.10.0

#查看nodejs版本是否正确，显示 6.10.0
node -v

#下载项目源码
git clone https://github.com/malaohu/forsaken-mail.git
cd forsaken-mail

#安装项目需要的库
npm install

#安装pm2工具
npm install -g pm2

#启动项目
pm2 start bin/www

#设置开机启动
pm2 startup
pm2 save
