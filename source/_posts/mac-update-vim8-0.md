---
title: "mac vim7.3 升级到vim8.0"
date: 2016-10-16 23:08:56
categories: [DevOps]
tags: [vim8.0]
description:
---

将mac自带的vim7.3 升级到vim8.0
<!--more-->

## 升级vim8.0

- 升级终端用得vim 
> brew install vim --with-lua --with-override-system-vi

- 升级GUI版本的vim
> brew install macvim --with-lua --with-override-system-vim

## brew install 下载慢
用`brew install`发现下载vim8.0很慢， 解决方案是先去浏览器或用`wget`等其它方式下载好要安装的包，然后替换掉`brew cache`下的包即可。具体操作：

- 找`brew cache` 目录
> brew cache 
/Users/lihong/Library/Cache/Homebrew

可以看到上述目录中已经有一个`vim-8.00041.tar.gz.incomplete` 文件了， 将自己下载好的安装包也修改为和这个未完成文件的文件名一样，如修改为`vim-8.00041.tar.gz`. 然后,

> brew install vim --with-lua --with-override-system-vi


- mac vim8.0 具体安装信息如下: 
	- install 

		```bash 
		
		➜  ~ brew install vim --with-lua --with-override-system-vi
		==> Using the sandbox
		==> Downloading https://github.com/vim/vim/archive/v8.0.0041.tar.gz
		==> Downloading from https://codeload.github.com/vim/vim/tar.gz/v8.0.0041
		######################################################################## 100.0%
		==> ./configure --prefix=/usr/local --mandir=/usr/local/Cellar/vim/8.0.0041/share/man --enable-multibyte --with-tlib=ncurses --enable-cscope --with-compiledby=Homebrew --enable-luainterp --enable-perlinterp --enable-pythoninterp --enable-
		==> make
		==> make install prefix=/usr/local/Cellar/vim/8.0.0041 STRIP=/usr/bin/true
		🍺  /usr/local/Cellar/vim/8.0.0041: 1,706 files, 23.3M, built in 5 minutes 16 seconds
		
		```
	- :version

		```bash
		:version
		VIM - Vi IMproved 8.0 (2016 Sep 12, compiled Oct 16 2016 23:10:47)
		MacOS X (unix) version
		Included patches: 1-41
		Compiled by Homebrew
		Huge version without GUI.  Features included (+) or not (-):
		+acl             -clientserver    +cursorbind      +ex_extra        -gettext         +libcall         +mouse           +mouse_xterm     +persistent_undo +ruby            +tag_old_static  -toolbar         +wildmenu        -xterm_save
		+arabic          +clipboard       +cursorshape     +extra_search    -hangul_input    +linebreak       -mouseshape      +multi_byte      +postscript      +scrollbind      -tag_any_white   +user_commands   +windows
		+autocmd         +cmdline_compl   +dialog_con      +farsi           +iconv           +lispindent      +mouse_dec       +multi_lang      +printer         +signs           -tcl             +vertsplit       +writebackup
		-balloon_eval    +cmdline_hist    +diff            +file_in_path    +insert_expand   +listcmds        -mouse_gpm       -mzscheme        +profile         +smartindent     +termguicolors   +virtualedit     -X11
		-browse          +cmdline_info    +digraphs        +find_in_path    +job             +localmap        -mouse_jsbterm   +netbeans_intg   +python          +startuptime     +terminfo        +visual          -xfontset
		++builtin_terms  +comments        -dnd             +float           +jumplist        +lua             +mouse_netterm   +num64           -python3         +statusline      +termresponse    +visualextra     -xim
		+byte_offset     +conceal         -ebcdic          +folding         +keymap          +menu            +mouse_sgr       +packages        +quickfix        -sun_workshop    +textobjects     +viminfo         -xpm
		+channel         +cryptv          +emacs_tags      -footer          +lambda          +mksession       -mouse_sysmouse  +path_extra      +reltime         +syntax          +timers          +vreplace        -xsmp
		+cindent         +cscope          +eval            +fork()          +langmap         +modify_fname    +mouse_urxvt     +perl            +rightleft       +tag_binary      +title           +wildignore      -xterm_clipboard
		```
