## [www.grdtechs.com](http://www.grdtechs.com)

[![Build Status](https://travis-ci.org/researchlab/researchlab.github.io.svg?branch=blog)](https://travis-ci.org/researchlab/researchlab.github.io)

Technologies from my work and learning. And you can just take it as my HomePage.

If there any questions, please feel free to tell me. `E-mail Address` can be find at my github HomePage.

## Problems 

hexo g 生成空文件

是因为hexo 与 node 版本不匹配导致生成空文件;

经查hexo 是 3.7.1 只能匹配node 13 或12，而当前机器node 是14版本， 所以需要 hexo 4以上;

默认 npm install hexo 会安装hexo 3.7.1 所以安装时需要制定hexo 版本 

npm i hexo@5.4.0

重新安装之后 问题解决

```
(base) ➜  blog git:(blog) ✗ hexo -v
hexo: 5.4.0 
hexo-cli: 4.3.0
os: darwin 20.3.0 11.2

node: 14.17.6
v8: 8.4.371.23-node.76
uv: 1.41.0
zlib: 1.2.11
brotli: 1.0.9
ares: 1.17.2
modules: 83
nghttp2: 1.42.0
napi: 8
llhttp: 2.1.3
openssl: 1.1.1l
cldr: 39.0
icu: 69.1
tz: 2021a
unicode: 13.0
```
