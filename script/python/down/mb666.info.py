# encoding=utf-8
import os
import requests
import threading
from bs4 import BeautifulSoup

# 当前脚本真实路径
file_realpath = os.path.realpath(__file__)
# 当前脚本所在文件夹
file_dir = os.path.dirname(file_realpath)
# 当前脚本文件名
file_name = os.path.basename(file_realpath)

# 漫画的首页
picUrl = "https://mb666.info/pics/chengrenmanhua//107029.html"
# 下载路径
downPath = "%s/"%file_dir
proxies={
	'http':'socks5://127.0.0.1:10086',
	'https':'socks5://127.0.0.1:10086'
}


def main():
	http = requests.session()
	#http.proxies = proxies
	http.headers.update({
			'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36',
			'Accept-Language': "zh-CN,zh;q=0.8,ko;q=0.6,zh-TW;q=0.4"
		})
	# 第一页
	res = http.get(picUrl)
	res.encoding = "UTF-8"
	# 转bs4对象
	bs = BeautifulSoup(res.text, "html.parser")
	# 网页标题,作为保存文件夹名 去除文件夹名称不支持的字符串
	title = bs.title.text.replace("|","").replace("\\","").replace("/","").replace("\"","").replace("'","").replace("?","").replace(" ","")
	thisDownPath = r"{}{}/".format(downPath, title)
	# 文件夹不存在的话创建文件夹
	if not os.path.exists(thisDownPath):
		os.mkdir(thisDownPath)
	# 所有图片
	picLinks = findPic(bs)
	# 下载
	threads = downPic(http,picLinks,thisDownPath)
	for th in threads:
		th.join()
	print("下载完毕")


def findPic(soup):
	"""
		从bs4对象中获取pic链接"""
	pics = soup.select('.bod img')
	picLinks = []
	l = len(pics)
	for i in range(0,l):
		picLink = pics[i].attrs['src']
		if picLink.startswith("http") or picLink.startswith("ftp"):
			picLinks.append(picLink)
	return picLinks


def downPic(http, picLinks, dirPath):
	"""
		下载图片"""
	threads = []
	for x in range(0,len(picLinks)):
		# 图片地址
		picLink = picLinks[x]
		# 图片序号
		picNum = str(x + 1001)[1:]
		# 文件名,在原始文件名前面加三位数字作为顺序
		picName = "%s_%s"%(picNum,picLink[picLink.rindex('/')+1:])
		# 如果文件不存在才去下载
		if not os.path.exists(dirPath + picName):
			# 线程方式
			t = myThread(http, picLink, dirPath, picName, picNum)
			t.start()
			threads.append(t)
	return threads


class myThread (threading.Thread):
	def __init__(self, http, picLink, dirPath, picName, picNum):
		threading.Thread.__init__(self)
		self.http = http
		self.picLink = picLink
		self.dirPath = dirPath
		self.picName = picName
		self.picNum = picNum
	def run(self):
		print("第" + self.picNum + "张开始下载")
		# 获取图片的响应
		pic = self.http.get(self.picLink)
		with open(self.dirPath + self.picName, 'wb') as f:
			f.write(pic.content)
		print("第" + self.picNum + "张下载完成")


if __name__ == '__main__':
	main()