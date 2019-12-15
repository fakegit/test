# encoding=utf-8
import os
import sys
import requests
import threading
from bs4 import BeautifulSoup

# 当前脚本真实路径
file_realpath = os.path.realpath(__file__)
# 当前脚本所在文件夹
file_dir = os.path.dirname(file_realpath)
# 当前脚本文件名
file_name = os.path.basename(file_realpath)

# 是否使用代理
isProxy = True
# 网站域名
web_host = "www.8muses.com"

# 下载路径
baseDownPath = file_dir

# 代理
proxies={
	'http':'socks5://127.0.0.1:10086',
	'https':'socks5://127.0.0.1:10086'
}
# User Agent
user_agent = 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36'


def main(picIndex,picPath,picUrl):
	"""
		picIndex: 网站域名
		picPath: 图片目录部分地址
		picUrl: 图片目录完整地址 """
	# 下载文件夹名
	downDirName = picPath[15:].replace('/','_').strip()

	# 初始化
	httpSession = requests.session()
	if isProxy:
		httpSession.proxies = proxies
	httpSession.headers.update({'User-Agent': user_agent, 'Accept-Language': "zh-CN,zh;q=0.8,ko;q=0.6,zh-TW;q=0.4"})
	# 访问第一页
	res = httpSession.get(picUrl)
	bsoup = BeautifulSoup(res.text,'html.parser')
	res.close()

	# 获取子级图片目录与图片地址
	pic_link_sub_all, pic_link_all = findPicUrl(picIndex,bsoup)
	# 遍历下载
	downThreads = downPicRecursion(httpSession, baseDownPath, downDirName, downDirName, pic_link_sub_all, pic_link_all)

	# 防止提前退出
	for th in downThreads:
		th.join()
	print("全部下载完毕")


def downPicRecursion(httpSession, thisBaseDownPath, downDirName, pic_link_sub_title, pic_link_sub_all, pic_link_all):
	"""
		递归下载图片
			thisBaseDownPath: 当前图片下载目录父级
			downDirName: 当前图片下载目录文件夹名
			pic_link_sub_title: 子级目录title
			pic_link_sub_all: 子级目录地址
			pic_link_all: 原图地址 """
	print('---------------%s 中共有 %d 张图片---------------'%(pic_link_sub_title, len(pic_link_all)))

	# 下载地址
	thisDownPath = "%s/%s/"%(thisBaseDownPath, downDirName)
	thisDownPath = thisDownPath.replace('//','/')
	# 文件夹不存在的话创建文件夹
	if not os.path.exists(thisDownPath):
		os.mkdir(thisDownPath)

	# 所有下载线程
	downThreads = []
	# 遍历下载图片
	index = 1
	for pic_name, pic_link in pic_link_all.items():
		# 线程方式下载
		t = myThread('%s||%d||%s'%(pic_link_sub_title,index,pic_name), httpSession, thisDownPath, pic_name, pic_link, index)
		downThreads.append(t)
		# 启动线程
		t.start()
		index = index + 1
	if pic_link_sub_all and len(pic_link_sub_all) > 0:
		# 遍历下载子级目录
		for pic_link_sub_title_sub, pic_link_sub in pic_link_sub_all.items():
			# 保存图片文件夹名 即图片网址
			downDirName_sub = pic_link_sub[36:].replace('/','_').strip()
			# 访问子级图片目录
			res = httpSession.get(pic_link_sub)
			bsoup_sub = BeautifulSoup(res.text,'html.parser')
			res.close()
			# 获取子级图片目录与图片地址
			pic_link_sub_all_recur, pic_link_all_recur = findPicUrl(picIndex,bsoup_sub)
			# 递归下载 当前下载目录即为子目录的父目录
			downThreads_sub = downPicRecursion(httpSession, thisDownPath, downDirName_sub, pic_link_sub_title_sub, pic_link_sub_all_recur, pic_link_all_recur)
			# 将子级目录线程记录下
			downThreads = downThreads + downThreads_sub
	return downThreads


def findPicUrl(picIndex,bsoup):
	"""
		从BeautifulSoup中获取图片地址和子级目录地址
			picIndex: 网站域名"""
	# 图片链接 格式{'图片名':'图片地址'}
	pic_link_all = {}
	# 子级目录 格式{'子级目录title':'子级目录地址'}
	pic_link_sub_all = {}

	# 获取所有图片的标签
	pic_a_all = bsoup.select('a.c-tile.t-hover')
	# 获取所有图片地址
	for pic_a in pic_a_all:
		# 子级图片目录
		pic_img_sub_title = pic_a.select_one('div.image-title')
		if pic_img_sub_title:
			# 完整地址
			pic_img_sub_link = "%s%s"%(picIndex, pic_a['href'])
			# 放入列表中
			pic_link_sub_all[pic_a['title']] = pic_img_sub_link
			continue
		# 子级目录与图片之间的间隔占位
		pic_placeholder = pic_a.select_one('iframe')
		if pic_placeholder:
			continue
		# 图片的img标签
		pic_img = pic_a.select_one('img.lazyload')
		if pic_img:
			pic_src = pic_img['data-src']
			# 缩略图地址替换为原图地址
			pic_src = pic_src.replace('/th/','/fl/')
			# 完整地址
			pic_src = "%s%s"%(picIndex, pic_src)
			# 放入字典中
			pic_link_all[pic_a['title']] = pic_src
	return pic_link_sub_all, pic_link_all


def downPic(httpSession, dirPath, pic_name, pic_img_src, pic_num):
	"""
		下载图片
		httpSession: requests.session()
		dirPath: 保存文件夹
		pic_name: 图片名
		pic_img_src: 图片地址
		pic_num: 图片第几张 """
	# 图片后缀名
	pic_name_suffix = pic_img_src[pic_img_src.rindex('.'):]
	# 图片名
	pic_name_save = "%s%s%s"%(dirPath,pic_name,pic_name_suffix)
	# 如果文件不存在才去下载
	if not os.path.exists(pic_name_save):
		print("%s 中第 %d 张 %s 开始下载"%(dirPath[dirPath.rindex('/',1,len(dirPath)-1)+1:-1], pic_num, pic_name))
		# 获取图片的响应
		pic = httpSession.get(pic_img_src)
		with open(pic_name_save, 'wb') as f:
			f.write(pic.content)
		pic.close()
		print("%s 中第 %d 张 %s 下载完毕"%(dirPath[dirPath.rindex('/',1,len(dirPath)-1)+1:-1], pic_num, pic_name))


class myThread (threading.Thread):
	"""
		多线程下载
		thread_name: 线程名,用以出错时区分
		httpSession: requests.session()
		dirPath: 保存文件夹
		pic_name: 图片名
		pic_img_src: 图片地址
		pic_num: 图片第几张 """
	def __init__(self, thread_name, httpSession, dirPath, pic_name, pic_img_src, pic_num):
		threading.Thread.__init__(self, name=thread_name)
		self.httpSession = httpSession
		self.dirPath = dirPath
		self.pic_name = pic_name
		self.pic_img_src = pic_img_src
		self.pic_num = pic_num
	def run(self):
		# 下载图片
		downPic(self.httpSession, self.dirPath, self.pic_name, self.pic_img_src, self.pic_num)


if __name__ == '__main__':
	# 脚本入参
	argvs = sys.argv
	# 使用说明
	tips = "格式: python %s 图片第一页地址\n    示例: python %s https://%s/comics/album/Affect3D-Comics/Jared999D/Message"%(file_name,file_name,web_host)
	if len(argvs) != 2:
		print(tips)
	else:
		# 图片目录完整地址
		picUrl = argvs[1]
		if not picUrl:
			print(tips)
		else:
			if not picUrl.startswith('https://%s/comics/album/'%web_host):
				print(tips)
			else:
				# 网站域名
				picIndex = "https://%s"%web_host
				# 图片部分地址
				picPath = picUrl[len(picIndex)-1:]
				main(picIndex,picPath,picUrl)
