 自用,记录
=============
<p>Mail-in-a-Box  一个非常方便的邮件系统，适用于Ubuntu 14.0.4<br>
拥有无限别名邮箱、云盘、日历等功能<br>
一键式安装，很简单<br></p>

--------------------------------------------
##  DNS记录
### 指定NS记录
<p>指定两条A记录作为NS服务器</p>
<pre><code>ns1.box.example.com A yourserverip
ns2.box.example.com A yourserverip
</code></pre>
<p>将邮箱后缀NS记录设置为上面的NS服务器</p>
<pre><code>example.com NS ns1.box.example.com
example.com NS ns2.box.example.com
</code></pre>

---------------------------------------------
##  VPS相关
###  vps主机名修改
<pre><code>sudo nano /etc/hosts </code></pre>
<p>位于第一行,修改为：</p>
<pre><code>127.0.0.1 box.example.com localhost localhost.localdomain</code></pre>
<p>或者修改为(未尝试)</p>
<pre><code>127.0.0.1 localhost.localdomain localhost
your_server_ip box.example.com box
</code></pre>
修改/etc/hostname 最好重启
<pre><code>sudo echo "box.example.com" > /etc/hostname
hostname -F /etc/hostname 
</code></pre>
<p>查看hostname是否修改成功</p>
<pre><code>hostname -f</code></pre>
<p>应该显示</p>
<pre><code>box.example.com</code></pre>

----------------------------------------------
##  安装
<p>Ubuntu 14.04雏机</p>
<pre><code>curl -s https://mailinabox.email/setup.sh | sudo bash</code></pre>
<p>期间需要输入管理员邮箱和hostname<br>
<br>管理员邮箱</p>

![输入管理员邮箱](http://i.imgur.com/Y2MHRk0.png "管理员邮箱")
<p>hostname</p>

![输入hostname](http://i.imgur.com/LGHOcar.png "hostname")
<p>之后会要求选择地区以及时区等(无图)<br>
<br>然后设置管理员密码</p>
<pre><code>Okay. I'm about to set up contact@example.com for you. This account will also have access to the box's control panel.
password:</code></pre>
<p>等待安装结束,会出现管理页面地址,用户名密码即之前设置的邮箱密码</p>
<pre><code>https://your_server_ip/admin</code></pre>
<p>此时还未安装SSL证书,因此地址栏会出现红叉<br>
登陆之后默认显检查页面,有什么工作没做会出现在这<br>
一般来说有DNSSEC记录设置(这个需要域名提供商支持，我做测试的TK域名没找到在哪设置),作者的视频频教程中有<br>
还有免费SSL证书的安装如下</p>

![进入SSL安装页面](http://ws4.sinaimg.cn/large/afa1af45ly1fegw1ofor0j20gp08ljud.jpg "SSL安装页面进入")

![SSL安装](http://ws1.sinaimg.cn/large/afa1af45ly1fegwggemmyj20i108wq5o.jpg "SSL安装")

![SSL安装成功](http://wx2.sinaimg.cn/large/afa1af45ly1fegw6jainpj20ii05zacc.jpg "SSL安装成功")
<p>证书安装完毕,注意,该免费证书有效期90天,也可以自己更换其他证书<br>
现在可以进入下面的地址进行管理了,也不会出现红叉</p>
<pre><code>https://box.example.com/mail</code></pre>
<p>可以拥有无限别名,这是我很喜欢的功能<br>
另外，将其他域名的NS记录指向之前设置的两个NS服务器就可以添加该域名的邮箱了</p>

![用户相关设置](http://wx1.sinaimg.cn/large/afa1af45ly1fegwu41fbqj20m50g10uh.jpg "用户、别名等")
<p>还拥有云盘功能</p>

![云盘](http://ws4.sinaimg.cn/large/afa1af45ly1fegww81l41j20fj0bnaan.jpg "云盘")

----------------------------------------------------------------------
<p>暂时就这些,其他好玩的东西等着你去发现</p>

[作者的GitHub](https://github.com/mail-in-a-box/mailinabox "原作者GitHub")

[作者的网站](https://mailinabox.email/ "原作者网站")

