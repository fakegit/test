# -*- coding:utf-8 -*-
import re
import os
import sys
import js2py
import random
import requests
import threading
from bs4 import BeautifulSoup
from urllib.parse import quote

# 当前脚本真实路径
file_realpath = os.path.realpath(__file__)
# 当前脚本所在文件夹
file_dir = os.path.dirname(file_realpath)
# 当前脚本文件名
file_name = os.path.basename(file_realpath)

# 默认下载线程数
down_thread_num = 10
# 网站host
host_tingchina = 'www.tingchina.com'
# 寻找 定义下载链接的JavaScript脚本 的正则表达式 var url = new Array(); ... url[3] = "/yousheng...";
down_url_re = down_re = r'var *url *= *new *Array\(\) *;[\s\S]*"/yousheng.*".*;'

# 网站编码
encoding_tingchina = 'GBK'
# 生成下载地址页面中下载链接编码方式
encoding_tingchina_down = 'UTF-8'
# 网站地址
web_tingchina = 'https://%s'%host_tingchina
# User-Agent
user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36'
# 请求头
headers_this = {
	'Accept':'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3',
	'Accept-Encoding':'gzip, deflate, br','Accept-Language':'zh-CN,zh;q=0.9','Connection':'keep-alive','Upgrade-Insecure-Requests':'1',
	'DNT':'1','Host':host_tingchina,'User-Agent':user_agent
}
# 下载请求头
headers_down = {
	'Accept':'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3',
	'Accept-Encoding':'gzip, deflate','Accept-Language':'zh-CN,zh;q=0.9','DNT':'1',	'User-Agent':user_agent,
	'Connection':'keep-alive','Host':'t44.tingchina.com','Upgrade-Insecure-Requests':'1'
}


def main():
	print('\n当前仅支持下载 "有声小说" 分类\n')
	# 脚本入参
	argvs = sys.argv
	# 使用说明
	tips = "\n格式: python %s 播放页面地址 [下载线程数(可选,默认10,最大50)]\n    示例: python %s https://%s/yousheng/22101/play_22101_0.htm [10]"%(file_name,file_name,host_tingchina)
	if len(argvs) < 2 or len(argvs) > 3:
		print(tips)
	else:
		# 播放地址
		audio_url_play = argvs[1]
		if audio_url_play:
			if not audio_url_play.startswith('https://%s/yousheng/'%host_tingchina):
				print("\n播放页面地址格式有误\n%s"%tips)
			else:
				if len(argvs) == 3:
					# 线程数
					down_thread_num_this = argvs[2]
					if down_thread_num_this.isdigit():
						down_thread_num_this = int(down_thread_num_this)
						if down_thread_num_this < 1:
							print("\n---线程数最必须大于0---\n%s"%tips)
							down_thread_num_this = None
						elif down_thread_num_this > 50:
							print("\n---线程数最大为50---\n%s"%tips)
							down_thread_num_this = None
					else:
						print("\n---线程数必须为数字---\n%s"%tips)
						down_thread_num_this = None
				else:
					# 默认线程数
					down_thread_num_this = down_thread_num
				if down_thread_num_this:
					down(audio_url_play,down_thread_num_this)
		else:
			print("\n必须输入播放页面地址\n%s"%tips)


def down(audio_url_play, down_thread_num_this):
	"""
		audio_url_play:播放页面地址 """
	httpSession = requests.session()
	# 更新headers
	httpSession.headers.update(headers_this)

	# 获取网页标题作为保存文件夹名
	res = httpSession.get(audio_url_play)
	res.encoding = encoding_tingchina
	bsoup = BeautifulSoup(res.text,'html.parser')
	res.close()
	web_title = bsoup.title.text
	web_title = web_title[:web_title.index('有声小说')+4]

	# 下载文件夹
	this_down_path = "%s/%s"%(file_dir,web_title)
	this_down_path = this_down_path.replace('//','/')
	# 文件夹不存在的话创建文件夹
	if not os.path.exists(this_down_path):
		print("文件夹 %s 不存在,创建"%this_down_path)
		os.mkdir(this_down_path)

	# 从首页中获取所有播放地址页面
	audio_url_all_num,audio_url_all = get_all_url(httpSession, audio_url_play)
	print("共有 %d 个语音文件"%audio_url_all_num)

	# 下载
	downThreads = downPicRecursion(httpSession, this_down_path, audio_url_all, down_thread_num_this)

	# 防止提前退出
	for th in downThreads:
		th.join()
	print("全部下载完毕")


def downPicRecursion(httpSession, this_down_path, audio_url_all, down_thread_num_this):
	"""
		遍历下载
			this_down_path: 下载文件夹
			audio_url_all: 所有下载信息
			down_thread_num_this: 下载最大线程数 """
	# 下载线程
	downThreads = []
	# 遍历获取数据
	audio_url_all_items = audio_url_all.items()
	for audio_url_all_item in audio_url_all_items:
		# 获取下载路径
		down_url = get_down_url(httpSession, audio_url_all_item)
		if down_url:
			# 文件名
			audio_play_name = audio_url_all_item[0]
			# 创建下载线程
			th = myThread(audio_play_name,httpSession,this_down_path,audio_play_name,down_url)
			downThreads.append(th)
			# 启动线程
			th.start()
		while len(downThreads) >= down_thread_num_this:
			for th in downThreads:
				# 判断线程的 run() 函数是否已经执行完成
				if not th.is_alive():
					# 线程执行结束后就从列表中将线程移除
					downThreads.remove(th)
			continue
	return downThreads


def down_audio(httpSession, audio_down_dir, audio_down_name, audio_down_url):
	"""
		下载文件
			audio_down_dir:下载文件夹
			audio_down_name: 下载文件名
			audio_down_url: 下载地址 """
	# 保存路径
	audio_file_path = "%s/%s"%(audio_down_dir,audio_down_name)
	# 文件不存在才下载
	if not os.path.exists(audio_file_path):
		print("%s 开始下载"%audio_down_name)
		host_down = audio_down_url[audio_down_url.index('//')+2:]
		host_down = host_down[:host_down.index('/')]
		headers_down['Host'] = host_down
		headers_down['Referer'] = quote(audio_down_url)
		# 获取响应
		audio_res = httpSession.get(audio_down_url,headers=headers_down)
		# 保存
		with open(audio_file_path, 'wb') as f:
			f.write(audio_res.content)
		audio_res.close()
		print("%s 下载完成"%audio_down_name)


def get_down_url(httpSession, audio_url_all_item):
	"""
		从播放页面中获取下载地址
			audio_url_all_item:播放页面地址信息 文件名=播放地址 """
	# 文件名
	audio_play_name = audio_url_all_item[0]
	# 播放地址
	audio_play_url = audio_url_all_item[1]

	# 访问播放页面
	res = httpSession.get(audio_play_url)
	res.encoding = encoding_tingchina
	bsoup = BeautifulSoup(res.text,'html.parser')
	res.close()

	# 从 当前位置 标签处获取小说信息,替换获取到的下载地址,防止乱码
	down_url_div_info = bsoup.select_one('div.summary.padding5')
	down_url_div_a_info = down_url_div_info.select('a')
	# 书籍类型 比如 玄幻奇幻
	book_type = down_url_div_a_info[1].text
	# 书名
	book_name = down_url_div_a_info[2].text[:-4]

	# 获取播放按钮处的小页面获取生成下载地址的页面地址 <div id="playdiv" class="infobook"><IFRAME id="playmedia" name="playmedia" ... src=""></IFRAME></div>
	audio_url_play_btn = bsoup.select_one('#playmedia')['src']
	audio_url_play_btn = "%s%s"%(web_tingchina,audio_url_play_btn)

	# 先更新headers Referer是当前页
	httpSession.headers.update({'Referer':audio_play_url})
	# 访问flash播放页面 即播放按钮处的小页面
	res = httpSession.get(audio_url_play_btn)
	res.encoding = encoding_tingchina_down
	bsoup = BeautifulSoup(res.text,'html.parser')
	res.close()
	# 更新headers
	httpSession.headers.update({'Referer':''})

	# 获取操作下载地址的JavaScript脚本
	down_url_script = bsoup.select_one('body script[type="text/javascript"]').text
	# 正则获取 定义下载地址 的脚本 var url = new Array(); ... url[3] = "/yousheng...";
	# var url = new Array();
	# url[1] = "http://t44.tingchina.com";
	# url[2] = "http://t33.tingchina.com";
	# url[3] = "/yousheng/玄幻奇幻/庆余年_秋水雁翎/001.mp3?key=eaddc72d38abe18cb1a49f7f310dda4d_629738601";
	audio_down_url_result = re.search(down_url_re,down_url_script,flags=re.M)
	if audio_down_url_result:
		audio_down_url_result_script = audio_down_url_result.group()
		audio_down_url_result_script = "%s; url;"%audio_down_url_result_script
		# 执行js 获取数据 元祖tuple类型
		down_url_tup = js2py.eval_js(audio_down_url_result_script)
		# 下载地址前缀
		down_url_prefix_list = []
		for down_url_sub in down_url_tup:
			if down_url_sub:
				if down_url_sub.startswith('http'):
					# 下载地址域名
					down_url_prefix_list.append(down_url_sub)
				elif down_url_sub.startswith('/yousheng'):
					# 下载地址 /yousheng/玄幻奇幻/庆余年_秋水雁翎/001.mp3?key=3e66756322e1c999dce454b452c01ff2_629751946
					down_url_sub = down_url_sub.replace('filename=','/').replace('/?key=','?key=')
					# 获取 key
					down_key = down_url_sub[down_url_sub.index('?key='):]
					# 替换原链接防止乱码
					down_url_sub = "/yousheng/%s/%s/%s%s"%(book_type,book_name,audio_play_name,down_key)
					down_url_suffix = down_url_sub
		# 最终下载地址
		down_url = "%s%s"%(down_url_prefix_list[random.randint(0,len(down_url_prefix_list)-1)],down_url_suffix)
		return down_url
	else:
		print("%s 未找到下载地址JavaScript"%audio_play_name)
		return None


def get_all_url(httpSession, audio_url_play):
	"""
		从首页中获取所有播放地址页面
			audio_url_play: 要下载的音乐随便一页的播放地址
		返回参数 文件总数量,所有播放地址 int:dict{'文件名':'播放地址'} """
	# 播放页面地址前缀 示例:https://www.tingchina.com/yousheng/22101/
	audio_url_play_prefix = audio_url_play[:audio_url_play.rindex('/')+1]
	# 所有播放地址
	audio_url_all = {}

	# 访问播放地址
	res = httpSession.get(audio_url_play)
	res.encoding = encoding_tingchina
	bsoup = BeautifulSoup(res.text,'html.parser')
	res.close()

	# 寻找播放列表
	audio_list_div = bsoup.select_one('div.list')
	# 所有a标签 <li><div class="b2"><a href="play_22101_0.htm">001.mp3</a></div></li>
	audio_list_li_a_all = audio_list_div.select('li div.b2 a')
	# 遍历获取数据
	for audio_list_li_a in audio_list_li_a_all:
		# 播放页面地址
		audio_play_url = "%s%s"%(audio_url_play_prefix,audio_list_li_a['href'])
		# 页面对应的文件名
		audio_play_name = audio_list_li_a.text
		# 放入字典中
		audio_url_all[audio_play_name] = audio_play_url
	return len(audio_url_all),audio_url_all


class myThread (threading.Thread):
	"""
		多线程下载
			thread_name: 线程名,用以出错时区分
			httpSession: requests.session()
			audio_down_dir:下载文件夹
			audio_down_name: 下载文件名
			audio_down_url: 下载地址 """
	def __init__(self, thread_name, httpSession, audio_down_dir, audio_down_name, audio_down_url):
		threading.Thread.__init__(self, name=thread_name)
		self.httpSession = httpSession
		self.audio_down_dir = audio_down_dir
		self.audio_down_name = audio_down_name
		self.audio_down_url = audio_down_url
	def run(self):
		# 下载图片
		down_audio(self.httpSession, self.audio_down_dir, self.audio_down_name, self.audio_down_url)


if __name__ == '__main__':
	main()
