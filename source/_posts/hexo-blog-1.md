---
title: 用Hexo+github搭建本站 
date: 2016-01-15 12:10:10
categories: Hexo
tags: [Hexo,Blog] 
description: 
---

[Hexo](https://hexo.io)是一个基于`Node.js`免费开源的静态博客框架，方便将生成的静态网页托管在`github`和`Heroku`上，可快速部署，并支持`Markdown`写作，这也是选择`Hexo`部署本站的理由。无特殊说明，本站所有操作均在`Mac OS`下完成。
<!--more-->
## 搭建Hexo博客
- 安装`Node.js`
		$ brew install node #该命令执行后，自动装好node和npm
		$ brew upgrade node #更新node
安装完成后 我们测试一下 在任意目录下 创建js文件, 如helloworld.js
``` javascript
		var http = require('http');
		http.createServer(function (req, res) {
			res.writeHead(200, {'Content-Type': 'text/plain'});
				res.end('Hello World\n');
			}).listen(1337, '127.0.0.1');
		console.log('Server running at http://127.0.0.1:1337/');
```
	在终端进入该目录下 输入node helloworld.js
	在浏览器中输入 地址 http://127.0.0.1:1337/ 查看结果 至此 NODEJS 运行环境已经配置好。

- 安装 `hexo`
		$ npm install hexo-cli -g

- 创建本地博客
		$ hexo init blog #这里是在/Users/lihong/ 这个目录下执行这个目录
		$ cd blog  #pwd 目录为: /Users/lihong/blog
		$ npm install
		$ hexo server
浏览器输入localhost:4000即可看到搭建的博客,此时只能本地访问，可通过部署到github上，使得在公网同样可以访问。

- 部署到`github`上
注册一个`github`账号，在自己`github`主页右下角，创建一个新的`repository`。例如我的github账号为`researchlab`,那么我应该创建的repository名字应该是`researchlab.github.io`。
编辑`_config.yml`(在`Users/lihong/blog`目录下)。你在部署时，要把下面的researchlab都换成你的账号名。(没有看到repository:, branch:等字段则加上即可）

		deploy:
		type: git
		repository: https://github.com/researchlab/researchlab.github.io.git
		branch: master
回到/Users/lihong/blog目录下执行如下命令
		$ hexo generate #生成静态网页
		$ hexo deploy #部署到github上
	**记住:** 每次修改本地文件后，需要hexo generate才能保存。每次使用命令时，都要在$pwd/blog目录下。现在可在浏览器访问`researchlab.github.io`看到我们到博客了。
- Hexo常用命令
	`hexo g` == `hexo generate` #生成静态页面
	`hexo d` == `hexo deploy` #部署到远程服务器上（如本站部署到 github)
	`hexo s` == `hexo server` #启动本地服务器
	`hexo n` == `hexo new` #新建一篇文章或一个页面

## 配置Hexo博客
Hexo站点配置用到两个文件，一个是对整站的配置`$pwd/blog/_config.yml`，另一个是对主题的配置 `$pwd/blog/themes/jacman/_config.yml`，我们来分别介绍。
- 对整站的配置`$pwd/blog/_config.yml`
``` md 
		# Hexo Configuration
		## Docs: https://hexo.io/docs/configuration.html
		## Source: https://github.com/hexojs/hexo/
		
		# Site
		title: 朴实的一线码农 #站点名 站点左上角 
		subtitle: 十年磨一剑，一步一步脚踏实地的耕种 #站点副标题
		description: Leehong's Blog #给搜索引擎看的, 对站点的描述，可以自定义
		author: Lee Hong 
		language: zh-CN #页面语言
		timezone:
		
		# URL
		## If your site is put in a subdirectory, set url as 'http://yoursite.com/child' and root as '/child/'
		url: http://www.grdtechs.com
		root: /
		permalink: :year/:month/:day/:title/
		permalink_defaults:
		
		# Directory #目录配置 默认即可
		source_dir: source
		public_dir: public
		tag_dir: tags
		archive_dir: archives
		category_dir: categories
		code_dir: downloads/code
		i18n_dir: :lang
		skip_render:
		
		# Writing 文章布局，写作格式定义 默认即可
		new_post_name: :title.md # File name of new posts
		default_layout: post
		titlecase: false # Transform title into titlecase
		external_link: true # Open external links in new tab
		filename_case: 0
		render_drafts: false
		post_asset_folder: false
		relative_link: false
		future: true
		highlight:
		  enable: true
		  line_number: true
		  auto_detect: false
		  tab_replace:
		
		# Category & Tag
		default_category: uncategorized
		category_map:
		tag_map:
		
		# Date / Time format 期日格式 默认即可
		## Hexo uses Moment.js to parse and display date
		## You can customize the date format as defined in
		## http://momentjs.com/docs/#/displaying/format/
		date_format: YYYY-MM-DD
		time_format: HH:mm:ss
		
		# Pagination 每页显示的文章数目 默认每页显示10篇
		## Set per_page to 0 to disable pagination
		per_page: 10
		pagination_dir: page
		
		# Extensions
		## Plugins: https://hexo.io/plugins/
		## Themes: https://hexo.io/themes/
		theme: jacman 
		
		# Deployment 部署站点到github
		## Docs: https://hexo.io/docs/deployment.html
		deploy:
		  type: git 
		  repository: https://github.com/researchlab/researchlab.github.io.git
		  branch: master
```
-  对主题的配置 `$pwd/blog/themes/jacman/_config.yml`
``` md
##### Menu 站点右上角导航栏
menu:
  首页: /
  归档: /archives
  关于: /about
## you can create `tags` and `categories` folders in `../source`.
## And create a `index.md` file in each of them.
## set `front-matter`as
## layout: tags (or categories)
## title: tags (or categories)
## ---

#### Widgets 站点右边栏
widgets: 
    #- github-card
- intro
- category
- tag
- links
- douban
- rss
- weibo
  ## provide eight widgets:github-card,category,tag,rss,archive,tagcloud,links,weibo

#### RSS 
rss: /atom.xml ## RSS address.

#### Image
imglogo:
  enable: true             ## display image logo true/false.
  src: #img/logo.png        ## `.svg` and `.png` are recommended,please put image into the theme folder `/jacman/source/img`.
favicon: #img/favicon.ico   ## size:32px*32px,`.ico` is recommended,please put image into the theme folder `/jacman/source/img`.     
apple_icon: #img/jacman.jpg ## size:114px*114px,please put image into the theme folder `/jacman/source/img`.
author_img: #img/author.jpg ## size:220px*220px.display author avatar picture.if don't want to display,please don't set this.
banner_img: #img/banner.jpg ## size:1920px*200px+. Banner Picture
### Theme Color 
theme_color:
    theme: '#2ca6cb'    ##the defaut theme color is blue

# 代码高亮主题
# available: default | night
highlight_theme: default

#### index post is expanding or not 
index:
  expand: true           ## default is unexpanding,so you can only see the short description of each post.
  excerpt_link: Read More  

close_aside: false  #close sidebar in post page if true
mathjax: false      #enable mathjax if true

### Creative Commons License Support, see http://creativecommons.org/ 
### you can choose: by , by-nc , by-nc-nd , by-nc-sa , by-nd , by-sa , zero
creative_commons: none

#### Toc
toc:
  article: true   ## show contents in article.
  aside: true     ## show contents in aside.
## you can set both of the value to true of neither of them.
## if you don't want display contents in a specified post,you can modify `front-matter` and add `toc: false`.

#### Links
links:
  Linux/c/c++: http://blog.csdn.net/xiaolongwang2010,小龙王2010csdn技术博客

#### Comment 添加多说评论
duoshuo_shortname: gamedp   ## e.g. Leehong   your duoshuo short name.
disqus_shortname:     ## e.g. Leehong   your disqus short name.

#### Share button
jiathis:
  enable: true ## if you use jiathis as your share tool,the built-in share tool won't be display.
  id:  2084050  ## e.g. 2084050 your jiathis ID. 
  tsina: ## e.g. 2176287895 Your weibo id,It will be used in share button.

#### Analytics
google_analytics:
  enable: false
  id:        ## e.g. UA-46321946-2 your google analytics ID.
  site:      ## e.g. Leehong.me your google analytics site or set the value as auto.
## You MUST upgrade to Universal Analytics first!
## https://developers.google.com/analytics/devguides/collection/upgrade/?hl=zh_CN
baidu_tongji:
  enable: true
  sitecode: ## e.g. e6d1f421bbc9962127a50488f9ed37d1 your baidu tongji site code
cnzz_tongji:
  enable: false
  siteid:    ## e.g. 1253575964 your cnzz tongji site id

#### Miscellaneous
ShowCustomFont: true  ## you can change custom font in `variable.styl` and `font.styl` which in the theme folder `/jacman/source/css`.
fancybox: true        ## if you use gallery post or want use fancybox please set the value to true.
totop: true           ## if you want to scroll to top in every post set the value to true

#### Custom Search
google_cse: 
  enable: false
  cx:   ## e.g. 018294693190868310296:abnhpuysycw your Custom Search ID.
## https://www.google.com/cse/ 
## To enable the custom search You must create a "search" folder in '/source' and a "index.md" file
## set the 'front-matter' as
## layout: search 
## title: search
## ---
baidu_search:     ## http://zn.baidu.com/
  enable: false
  id:   ## e.g. "783281470518440642"  for your baidu search id
  site: http://zhannei.baidu.com/cse/search  ## your can change to your site instead of the default site
  
tinysou_search:     ## http://tinysou.com/
  enable: false
  id:  ## e.g. "4ac092ad8d749fdc6293" for your tiny search id
```

## 用Hexo写博客
站点配置好了之后，可通过执行如下命令开始写文章并发布

		$ hexo new "the_first_post" #在/Users/lihong/blog 目录下执行hexo new 命令
打开新建的`source/_posts/the_first_post.md`, 如下：
``` md
---
title: the_first_post # 这个是文章的标题,可随意修改,如: 用Hexo+github搭建本站 
date: 2016-01-15 12:10:10 #发表日期
categories: Hexo #文章分类
tags: [Hexo,Blog] #文章标签,多于一项时用这种格式
description: 
---
# 这里是正文
<!--more--> #这后面的正文在首页不予以显示
```
写好之后，执行`hexo g` 命令生成静态网页，执行`hexo s`启动本地服务器此时可通过localhost:4000在本地浏览器访问,执行`hexo d`部署到github上，则可通过公网访问了。
	
## 优化Hexo博客
- 导航栏添加"关于"
	1. `hexo new page "about"`
	2. 到`source/about/index.md`编辑内容
	3. 在`themes/jacman/_config.yml`中,添加如下：
			menu:
				关于: /about

- 添加RSS
hexo提供了RSS的生成插件，需要手动安装和设置。步骤如下：
	1. 安装RSS插件到本地：`npm install hexo-generator-feed`
	2. 开启RSS功能：编辑`$pwd/blog/_config.yml`，添加如下代码：
			plugins:
				- hexo-generator-feed
	3. 在`themes/jacman/_config.yml`中，编辑 `rss: /atom.xml`
	** 注意 ** 如果发现没有生成`atom.xml`, 可接着执行`npm install hexo-generator-feed --save`即可。
- 添加sitemap
hexo也提供了sitemap到生成插件，与添加RSS插件类似。
	1. 安装sitemap插件到本地：`npm install hexo-generator-sitemap`
	2. 开启sitmap功能: 编辑`$pwd/blog/_config.yml`,添加如下代码：
			plugins:
				- hexo-generator-feed
				- hexo-generator-sitemap

	3. 访问researchlab.github.io/sitemap.xml即可看到站点地图。不过，sitemap的初衷是给搜索引擎看的，为了提高搜索引擎对自己站点的收录效果，我们最好手动到google和百度等搜索引擎提交sitemap.xml。

- 文章中插入图片
使用markdown写文章，插入图片的格式为`![图片名称](链接地址)`，这里要说的是链接地址怎么写。对于hexo，有两种方式：
	1. 使用本地路径：在`$pwd/blog/source`目录下新建一个img文件夹，将图片放入该文件夹下，插入图片时链接即为`/img/图片名称`。
	2. 使用微博图床，地址:[http://weibotuchuang.sinaapp.com/](http://weibotuchuang.sinaapp.com/)，将图片拖入区域中，会生成图片的URL，这就是链接地址。

## 问题解决方案
1. 执行`Hexo d` 出现`ERROR Deployer not found:git`,解决方案：`npm install hexo-deployer-git --save` 即可。
