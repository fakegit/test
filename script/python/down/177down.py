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
picUrl = "http://www.177pic.info/html/2014/03/42992.html"
# 下载路径
downPath = "%s/"%file_dir
proxies={
	'http':'socks5://127.0.0.1:10086',
	'https':'socks5://127.0.0.1:10086'
}

def main():
	http = requests.session()
	http.headers.update({
			'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36',
			'Accept-Language': "zh-CN,zh;q=0.8,ko;q=0.6,zh-TW;q=0.4"
		})
	# 第一页
	res = http.get(picUrl,proxies=proxies)
	# 转bs4对象
	bs = BeautifulSoup(res.text, "html.parser")
	# 网页标题,作为保存文件夹名 去除文件夹名称不支持的字符串
	title = bs.title.text.replace("|","").replace("\\","").replace("/","").replace("\"","").replace("'","").replace("?","")
	thisDownPath = r"{}{}/".format(downPath, title)
	# 文件夹不存在的话创建文件夹
	if not os.path.exists(thisDownPath):
		os.mkdir(thisDownPath)
	# 下载本页的图片
	#downPic(http, findPic(bs), thisDownPath)
	# 线程方式
	t1 = myThread(http, picUrl, thisDownPath, 0)
	threads = [t1]
	t1.start()
	# 获取该套漫画所有的网页链接
	links = bs.select('.page-links a')
	l = len(links)-1
	# 遍历其他页面,下载图片,去除第一个和最后一个,重复数据
	for i in range(1,l):
		# 下载本页的图片
		#downPic(http, findPic(bs), thisDownPath)
		t2 = myThread(http, links[i].attrs['href'], thisDownPath, i)
		threads.append(t2)
		t2.start()
	for th in threads:
		th.join()
	print("下载完毕")


"""
	从bs4对象中获取pic链接
"""
def findPic(soup):
	pics = soup.select('.single-content img')
	picLinks = []
	l = len(pics)
	for i in range(0,l):
		picLink = pics[i].attrs['src']
		if picLink.startswith("http") or picLink.startswith("ftp"):
			picLinks.append(picLink)
	return picLinks


"""
	下载图片
"""
def downPic(http, picLinks, dirPath, pageNum):
	for picLink in picLinks:
		# 文件名,在原始文件名前面加三位数字的页数
		picName = pageNum + "_" + picLink[picLink.rindex('/')+1:]
		# 如果文件不存在才去下载
		if not os.path.exists(dirPath + picName):
			# 获取图片的响应
			pic = http.get(picLink,proxies=proxies)
			with open(dirPath + picName, 'wb') as f:
				f.write(pic.content)


class myThread (threading.Thread):
	def __init__(self, http, htmlLink, dirPath, pageNum):
		threading.Thread.__init__(self)
		self.http = http
		self.htmlLink = htmlLink
		self.dirPath = dirPath
		self.pageNum = str(pageNum + 1001)[1:]
	def run(self):
		print("第" + self.pageNum + "页开始下载")
		# 访问链接
		res = self.http.get(self.htmlLink,proxies=proxies)
		# 转bs4对象
		bs = BeautifulSoup(res.text, "html.parser")
		# 下载
		downPic(self.http, findPic(bs), self.dirPath, self.pageNum)
		print("第" + self.pageNum + "页下载完成")


if __name__ == '__main__':
	main()
