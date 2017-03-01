---
title: "http 缓存知识总结"
date: 2017-01-17 17:54:18
categories: [DevOps]
tags: [cache]
description:
---

## 前言

Http缓存机制作为web性能优化的重要手段, 本文对网络中，工作中使用的http缓存知识进行归纳总结。
<!--more-->

## 缓存分类 
缓存分为`服务端缓存`(server side，比如Nginx、Apache)和`客户端缓存`(client side，比如 web browser)。
- `服务端缓存`又分为`代理服务器缓存`和`反向代理服务器缓存`(也叫网关缓存，比如Nginx反向代理、Squid等)，其实广泛使用的CDN也是一种服务端缓存，目的都是让用户的请求走"捷径"(一般用CDN缓存图片、文件等静态资源)。
- `客户端缓存`一般指的是`浏览器缓存`，目的就是加速各种静态资源的访问，想想现在的大型网站，随便一个页面都是一两百个请求，每天pv都是亿级别，如果没有缓存，用户体验会急剧下降、同时服务器压力和网络带宽都面临严重的考验。

下文总结的http缓存主要指浏览器缓存和代理服务器缓存

<center>![cache](imgs/cache_where.png)</center>

上图中有三个角色，浏览器, Web代理和服务器，如图所示Http缓存存在于浏览器和Web代理中。
当然在服务器内部，也存在着各种缓存，但这已经不是本文要讨论的Http缓存了。
所谓的Http缓存控制，就是一种约定，通过设置不同的响应头Cache-Control来控制浏览器和Web代理对缓存的使用策略，通过设置请求头If-None-Match和响应头ETag，来对缓存的有效性进行验证。在开发Web服务时，只需要关注请求头If-None-Match、响应头ETag、响应头Cache-Control就足够了。

** 响应头ETag **

ETag全称Entity Tag，用来标识一个资源。在具体的实现中，ETag可以是资源的hash值，也可以是一个内部维护的版本号。但不管怎样，ETag应该能反映出资源内容的变化，这是Http缓存可以正常工作的基础。

<center>![ETag](imgs/etag.png)</center>

如上例中所展示的，服务器在返回响应时，通常会在Http头中包含一些关于响应的元数据信息，其中，ETag就是其中一个，本例中返回了值为`x1323ddx`的`ETag`。当资源/file的内容发生变化时，服务器应当返回不同的ETag。

> 为什么使用ETag呢? 主要是为了解决Last-Modified无法解决的一些问题。

>>1.某些服务器不能精确得到文件的最后修改时间, 这样就无法通过最后修改时间来判断文件是否更新了。
>>2.某些文件的修改非常频繁, 在秒以下的时间内进行修改, Last-Modified只能精确到秒。
>>3.一些文件的最后修改时间改变了, 但是内容并未改变, 我们不希望客户端认为这个文件修改了。

** 请求头If-None-Match **

对于同一个资源，比如上一例中的/file，在进行了一次请求之后，浏览器就已经有了/file的一个版本的内容，和这个版本的ETag，当下次用户再需要这个资源，浏览器再次向服务器请求的时候，可以利用请求头If-None-Match来告诉服务器自己已经有个ETag为x1323ddx的/file，这样，如果服务器上的/file没有变化，也就是说服务器上的/file的ETag也是x1323ddx的话，服务器就不会再返回/file的内容，而是返回一个304的响应，告诉浏览器该资源没有变化，缓存有效。

<center>![If-None-Match](imgs/if-none-match.png)</center>

如上例中所示，在使用了If-None-Match之后，服务器只需要很小的响应就可以达到相同的结果，从而优化了性能。

** 响应头Cache-Control **

每个资源都可以通过Http头Cache-Control来定义自己的缓存策略，Cache-Control控制谁在什么条件下可以缓存响应以及可以缓存多久。最快的请求是不必与服务器进行通信的请求:通过响应的本地副本, 我们可以避免所有的网络延迟以及数据传输的数据成本。为此，HTTP规范允许服务器返回一系列不同的`Cache-Control`指令，控制浏览器或者其他中继缓存如何缓存某个响应以及缓存多长时间。

> Cache-Control头在HTTP/1.1规范中定义，取代了之前用来定义响应缓存策略的头(例如 Expires)。当前的所有浏览器都支持Cache-Control，因此，使用它就够了。

其中Cache-Control的参数包括:
- ** max-age **  - 该指令指定从当前请求开始，允许获取的响应被重用的最长时间（单位为秒。例如：Cache-Control:max-age=60表示响应可以再缓存和重用 60 秒。需要注意的是，在max-age指定的时间之内，浏览器不会向服务器发送任何请求，包括验证缓存是否有效的请求，也就是说，如果在这段时间之内，服务器上的资源发生了变化，那么浏览器将不能得到通知，而使用老版本的资源。所以在设置缓存时间的长度时，需要慎重。)，它在最大生存期后必须在源服务器处被验证或被重新下载。在现代浏览器中这个选项大体上取代了Expires头部，浏览器也将其作为决定内容的新鲜度的基础。最大可以表示一年的新鲜期（31536000秒）。但是这个参数定义的是时间大小(比如: 60)而不是确定的时间点, 单位是[秒seconds] 
- ** s-maxage **  - 类似于max-age, 但是它只用于公享缓存(e.g., proxy), 这个选项非常类似于max-age，它指明了内容能够被缓存的时间。区别是这个选项只在中间节点的缓存中有效。结合这两个选项可以构建更加灵活的缓存策略。
- ** public ** - 设置了public，表示该响应可以再浏览器或者任何中继的Web代理中缓存，public是默认值，即Cache-Control:max-age=60等同于Cache-Control:public, max-age=60。
- ** private ** - 在服务器设置了private比如Cache-Control:private, max-age=60的情况下，表示只有用户的浏览器可以缓存private响应，不允许任何中继Web代理对其进行缓存 - 例如，用户浏览器可以缓存包含用户私人信息的HTML网页，但是CDN不能缓存。
- ** no-cache ** - 如果服务器在响应中设置了no-cache即Cache-Control:no-cache，那么浏览器在使用缓存的资源之前，必须先与服务器确认返回的响应是否被更改，如果资源未被更改，可以避免下载。这个验证之前的响应是否被修改，就是通过上面介绍的请求头If-None-match和响应头ETag来实现的。<font color=red>(注意: no-cache这个名字有一点误导。设置了no-cache之后，并不是说浏览器就不再缓存数据，只是浏览器在使用缓存数据时，需要先确认一下数据是否还跟服务器保持一致。如果设置了no-cache，而ETag的实现没有反应出资源的变化，那就会导致浏览器的缓存数据一直得不到更新的情况。)</font> 
- ** no-store ** - 如果服务器在响应中设置了no-store即Cache-Control:no-store，那么浏览器和任何中继的Web代理，都不会存储这次相应的数据。当下次请求该资源时，浏览器只能重新请求服务器，重新从服务器读取资源。
- ** must-revalidate ** - 响应在特定条件下会被重用, 以满足接下来的请求, 但是它必须到服务器端去验证它是不是仍然是最新的,它指明了由max-age、s-maxage或Expires头部指明的新鲜度信息必须被严格的遵守。它避免了缓存的数据在网络中断等类似的场景中被使用。
- ** proxy-revalidate ** - 类似于must-revalidate, 但不适用于代理缓存, 它和上面的选项有着一样的作用，但只应用于中间的代理节点。在这种情况下，用户的浏览器可以在网络中断时使用过期内容，但中间缓存内容不能用于此目的。
- ** no-transform ** - 这个选项告诉缓存在任何情况下都不能因为性能的原因修改接收到的内容。这意味着，缓存不允许压缩接收到的内容（没有从原始服务器处接收过压缩版本的该内容）并发送。

>如果no-store和no-cache都被设置，那么no-store会取代no-cache。

>cache-control默认为private, 其作用根据不同的重新浏览方式分为以下几种情况:

>>1.打开新窗口 值为private、no-cache、must-revalidate，那么打开新窗口访问时都会重新访问服务器。而如果指定了max-age值，那么在此值内的时间里就不会重新访问服务器，例如: Cache-control:max-age=5(表示当访问此网页后的5秒内再次访问不会去服务器) 
>>2.在地址栏回车 值为private或must-revalidate则只有第一次访问时会访问服务器，以后就不再访问。 值为no-cache，那么每次都会访问。 值为max-age，则在过期之前不会重复访问。
>>3.按后退按扭 值为private、must-revalidate、max-age，则不会重访问，值为no-cache，则每次都重复访问 
>>4.按刷新按扭 无论为何值，都会重复访问 Cache-control值为"no-cache"时，访问此页面不会在Internet临时文件夹留下页面备份。

Cache-Control 有这么多字段可用来控制缓存策略， 那到底是怎么用的? ， 下面通过一张图来表述一个资源的Cache-Control策略,

<center>![cache-control-work-flow](imgs/cache_control_workflow.png)</center>

## 缓存新鲜度

Web服务器通过2种方式来判断浏览器缓存是否是最新的。

** 第一种, 浏览器把缓存文件的`最后修改时间`通过header字段"If-Modified-Since"来告诉Web服务器。**
** 第二种, 浏览器把缓存文件的`ETag`, 通过header字段"If-None-Match", 来告诉Web服务器。**

** 第一种: ** 通过最后修改时间, 来判断缓存新鲜度 

1.浏览器客户端想请求一个文档, 首先检查本地缓存, 发现存在这个文档的缓存, 获取缓存中文档的最后修改时间, 通过:If-Modified-Since， 发送Request给Web服务器。
2.Web服务器收到Request, 将服务器的文档修改时间(Last-Modified):跟request header中的, If-Modified-Since相比较, 如果时间是一样的, 说明缓存还是最新的, Web服务器将发送`304 Not Modified`给浏览器客户端, 告诉客户端直接使用缓存里的版本。如下图。

<center>![cache 304](imgs/cache_304.png)</center>

3.假如该文档已经被更新了。Web服务器将发送该文档的最新版本给浏览器客户端， 如下图。

<center>![cache 200](imgs/cache_200.png)</center>

** 第二种: ** 服务器通过比对客户端请求发来的"If-None-Match"带上的Etag值, 如果一致则表示可以使用本地缓存，如果不一致表示服务器内容有更新，此时会重新发一份新的给客户端。

至此，浏览器端http cache 的大致流程可总结如图，

<center>![cache workflow](imgs/cache_workflow.png)</center>

** <font color=red>Etag/If-None-Match:</font>Etag/If-None-Match要配合Cache-Control使用。**

>Etag: web服务器响应请求时，告诉浏览器当前资源在服务器的唯一标识(生成规则由服务器决定)。Apache中，ETag的值，默认是对文件的索引节(INode)，大小(Size)和最后修改时间(MTime)进行Hash后得到的。
>If-None-Match: 当资源过期时(使用Cache-Control标识的max-age)，发现资源具有Etage声明，则再次向web服务器请求时带上头If-None-Match(Etag的值)。web服务器收到请求后发现有头If-None-Match则与被请求资源的相应校验串进行比对，决定返回200或304。

** <font color=red>Last-Modified/If-Modified-Since:</font>Last-Modified/If-Modified-Since也要配合Cache-Control使用。 **

> Last-Modified:标示这个响应资源的最后修改时间。web服务器在响应请求时，告诉浏览器资源的最后修改时间。
> If-Modified-Since:当资源过期时(使用Cache-Control标识的max-age)，发现资源具有Last-Modified声明，则再次向web服务器请求时带上头If-Modified-Since，表示请求时间。web服务器收到请求后发现有头If-Modified-Since 则与被请求资源的最后修改时间进行比对。若最后修改时间较新，说明资源又被改动过，则响应整片资源内容（写在响应消息包体内），HTTP 200；若最后修改时间较旧，说明资源无新修改，则响应HTTP 304 (无需包体，节省浏览)，告知浏览器继续使用所保存的cache。

<font color=red>既生Last-Modified何生Etag? </font>
你可能会觉得使用Last-Modified已经足以让浏览器知道本地的缓存副本是否足够新，为什么还需要Etag(实体标识)呢? HTTP1.1中Etag的出现主要是为了解决几个Last-Modified比较难解决的问题,

>Last-Modified标注的最后修改只能精确到秒级，如果某些文件在1秒钟以内，被修改多次的话，它将不能准确标注文件的修改时间, 如果某些文件会被定期生成，当有时内容并没有任何变化，但Last-Modified却改变了，导致文件没法使用缓存,有可能存在服务器没有准确获取文件修改时间，或者与代理服务器时间不一致等情形

>Etag是服务器自动生成或者由开发者生成的对应资源在服务器端的唯一标识符, 能够更加准确的控制缓存。Last-Modified与ETag一起使用时, 服务器会优先验证ETag。

** 注: <font color=red>yahoo的Yslow法则中则提示谨慎设置Etag,</font> ** 需要注意的是分布式系统里多台机器间文件的last-modified必须保持一致，以免负载均衡到不同机器导致比对失败，Yahoo建议分布式系统尽量关闭掉Etag(每台机器生成的etag都会不一样，因为除了last-modified、inode也很难保持一致)。

此外浏览器缓存行为还与用户的操作行为有关, 归纳总结如下,

| 用户操作                            | Expires/Cache-Control                         | Last-Modified/Etag                             |
|:------------------------------------|-----------------------------------------------|------------------------------------------------|
| 地址栏回车                          | 有效                                          | 有效                                           |
| 页面链接跳转                        | 有效                                          | 有效                                           |
| 新开窗口                            | 有效                                          | 有效                                           |
| 前进、后退                          | 有效                                          | 有效                                           |
| <font color=red>F5/按钮刷新 </font> | <font color=red> 无效(BR重置max-age=0)</font> | <font color=red> 有效     </font>              |
| <font color=red>Ctrl+F5刷新 </font> | <font color=red> 无效(重置CC=no-cache)</font> | <font color=red> 无效(请求头丢弃该选项)</font> |

## 案例分析
案例, page.html内容如下:
```html
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<!--<meta http-equiv="cache-control" content="no-cache">-->
	<meta http-equiv="cache-control" content="private">
    <title>page页</title>
</head>
<body>
    <img src="images/head.png" />
    <a href="page.html">重新访问page页</a>
</body>
</html>
```

首次访问该页面，页面中head.png响应头信息如下:
```html
HTTP/1.1 200 OK
Cache-Control: no-cache
Content-Type: image/png
Last-Modified: Tue, 08 Nov 2016 06:59:00 GMT
Accept-Ranges: bytes
Date: Thu, 10 Nov 2016 02:48:50 GMT
Content-Length: 3534
```

** <font color="red"> 问题1: 请问当点击"重新访问page页"链接重新加载该页面后, head.png 如何二次加载? </font> ** 

** <font color="red"> 问题2: 如果将上述信息中的 Cache-Control 设置为 private，那么结果又会如何呢? </font> **

下面从系统体系化角度来讲讲`Http缓存头`是如何协同工作的

** HTTP缓存体系 **

首先我将 Http 缓存体系分为以下三个部分:

<center>![cache](imgs/cache_sys.png)</center>

** 1.缓存存储策略 **

这个策略的作用只有一个, 用于确定Http响应内容是否可以被客户端缓存, 以及可以被哪些客户端缓存

对于Cache-Control头里的Public, Private, no-cache, max-age, no-store他们都是用来指明响应内容是否可以被客户端存储的，其中前4个都会缓存文件数据(关于no-cache应理解为"不建议使用本地缓存", 其仍然会缓存数据到本地), 后者no-store则不会在客户端缓存任何响应数据。


通过Cache-Control:Public设置我们可以将Http响应数据存储到本地，但此时并不意味着后续浏览器会直接从缓存中读取数据并使用, 为啥? 因为它无法确定本地缓存的数据是否可用(可能已经失效), 还必须借助一套鉴别机制来确认才行, 这就是我们下面要讲到的"缓存过期策略"。

** 2.缓存过期策略 **

客户端用来确认存储在本地的缓存数据是否已过期, 进而决定是否要发请求到服务端获取数据
这个策略的作用也只有一个, 那就是决定客户端是否可直接从本地缓存数据中加载数据并展示(否则就发请求到服务端获取)
刚上面我们已经阐述了数据缓存到了本地后还需要经过判断才能使用, 那么浏览器通过什么条件来判断呢? 答案是:Expires，Expires指明了缓存数据有效的绝对时间, 告诉客户端到了这个时间点(比照客户端时间点)后本地缓存就作废了, 在这个时间点内客户端可以认为缓存数据有效, 可直接从缓存中加载展示。

不过Http缓存头设计并没有想象的那么规矩, 像上面提到的Cache-Control(这个头是在Http1.1里加进来的)头里的no-cache和max-age就是特例, 它们既包含缓存存储策略也包含缓存过期策略, 以max-age为例, 它实际上相当于: Cache-Control:public/private(这里不太确定具体哪个)

Expires: 当前客户端时间 + maxAge。
而Cache-Control: no-cache 和 Cache-Control: max-age=0(单位是秒)相当

这里需要注意的是:
<font color=red>Cache-Control中指定的缓存过期策略优先级高于Expires, 当它们同时存在的时候, Expires将被忽略不起作用。</font>
缓存数据标记为已过期只是告诉客户端不能再直接从本地读取缓存了, 需要再发一次请求到服务器去确认, 并不等同于本地缓存数据从此就没用了, 有些情况下即使过期了还是会被再次用到，具体下面会讲到。

> Expires是Web服务器响应消息头字段，在响应http请求时告诉浏览器在过期时间前浏览器可以直接从浏览器缓存取数据，而无需再次请求。不过Expires 是HTTP 1.0的东西，现在默认浏览器均默认使用HTTP 1.1，所以它的作用基本忽略。Expires 的一个缺点就是，返回的到期时间是服务器端的时间，这样存在一个问题，如果客户端的时间与服务器的时间相差很大（比如时钟不同步，或者跨时区），那么误差就很大，所以在HTTP 1.1版开始，使用Cache-Control: max-age=秒替代。

** 3.缓存对比策略 **

将缓存在客户端的数据标识发往服务端, 服务端通过标识来判断客户端缓存数据是否仍有效, 进而决定是否要重发数据。
客户端检测到数据过期或浏览器刷新后, 往往会重新发起一个http请求到服务器, 服务器此时并不急于返回数据, 而是看请求头有没有带标识(If-Modified-Since, If-None-Match)过来, 如果判断标识仍然有效, 则返回304告诉客户端取本地缓存数据来用即可(这里要注意的是你必须要在首次响应时输出相应的头信息(Last-Modified, ETags)到客户端)。至此我们就明白了上面所说的本地缓存数据即使被认为过期，并不等于数据从此就没用了的道理了。

关于Last-Modified，这个响应头使用要注意，可能会影响到缓存过期策略，具体原因，后面我会通过解答开篇提到的2道题来作说明。

以上就是我所认识的缓存策略，下面我将缓存策略三要素和常用的几个缓存头(项)结合一起，让大家更清晰的认识到它们之间的关系:

<center>![cache sys relation](imgs/cache_sys_relation.png)</center>

通过上图可以清晰的看到各缓存项分别属于哪个缓存策略范畴，这其中有部分重叠，它表明这些缓存项具有多重缓存策略，所以实际在分析缓存头的时候，除了常规的头外，我们还需要将这些具有双重缓存策略的项分解开来。
现在回到最开始提到的2道题目,

** 第一道题: **
```bash
HTTP/1.1 200 OK
Cache-Control: no-cache
Content-Type: image/png
Last-Modified: Tue, 08 Nov 2016 06:59:00 GMT
Accept-Ranges: bytes
Date: Thu, 10 Nov 2016 02:48:50 GMT
Content-Length: 3534
```

分析上述Http响应头发现有以下两项与缓存相关:
```bash
Cache-Control: no-cache 
Last-Modified: Tue, 08 Nov 2016 06:59:00 GMT
```

我们上面讲到了Cache-Control:no-cache 相当于Cache-Control:max-age=0，且他们都是多重策略头, 我们需将其分解:

Cache-Control:no-cache 等于 Cache-Control:max-age=0， 

接着Cache-Control:max-age=0 又可分解成:
```bash
Cache-Control: public/private （不确定是二者中的哪一个）
Expires: 当前时间
```

** 最终我们得到了以下完整的缓存策略三要素: **

| 缓存策略类型 | 缓存策略值                                  | 结果                                                                                                     | 备注                             |
|:------------:|:--------------------------------------------|:---------------------------------------------------------------------------------------------------------|:---------------------------------|
| 缓存存储策略 | cache-control:public/private                | 响应数据会被缓存到客户端                                                                                 | 由cache-control:no-cache拆解而来 |
| 缓存过期策略 | Expires:当前时间                            | 立马过期, 二次资源访问浏览器会重新发起http请求                                                           | 由cache-control:no-cache拆解而来 |
| 缓存对比策略 | Last-Modifed: Tue, 08 Nov 2016 06:59:00 GMT | 浏览器会携带该值去服务端比对，比对成功则返回304, 服务端提示浏览器从本地加载数据，否在返回200并响应数据。 |                                  |


所以最终结果是:浏览器会再次请求服务端, 并携带上Last-Modified指定的时间去服务器对比:

a)对比失败: 服务器返回200并重发数据, 客户端接收到数据后展示, 并刷新本地缓存。
b)对比成功: 服务器返回304且不重发数据, 客户端收到304状态码后从本地读取缓存数据。

<center>![cache_data](imgs/cache_data1.jpg)</center>

这道题本身不难, 但若认为no-cache不会缓存数据到本地, 那么你理解起来就会很矛盾, 因为如果文件数据没有被本地缓存, 服务器返回304后将会无法展示出图片内容, 但实际上它是能正常展示的。这道题很好的证明了no-cache也会缓存数据到本地这一说法。

** 第二道题: **
```bash
HTTP/1.1 200 OK
Cache-Control: private
Content-Type: image/png
Last-Modified: Tue, 08 Nov 2016 06:59:00 GMT
Accept-Ranges: bytes
Date: Thu, 10 Nov 2016 02:48:50 GMT
Content-Length: 3534
```

解题思路和上题一样，首先先找到缓存相关项:
```bash
Cache-Control: private     
Last-Modified: Tue, 08 Nov 2016 06:59:00 GMT
```
`private`: 指对于单个用户的整个或部分响应消息进行缓存，不能被共享缓存处理。这允许服务器仅仅描述当用户的部分响应消息，此响应消息对于其他用户的请求无效,这里可以看到没有提供任何缓存过期策略

在没有提供任何浏览器缓存过期策略的情况下，浏览器遵循一个启发式缓存过期策略, ** 根据响应头中2个时间字段Date和Last-Modified之间的时间差值，取其值的10%作为缓存时间周期。** 下面是官方解释,

```html 
HTTP/1.1 Cache-Control Header is present: private
HTTP Last-Modified Header is present: Tue, 08 Nov 2016 06:59:00 GMT
No explicit HTTP Cache Lifetime information was provided.
Heuristic expiration policies suggest defaulting to: 10% of the delta between Last-Modified and Date.
That's '05:15:02' so this response will heuristically expire 2016/11/11 0:46:01.
```

最终我们得到了以下完整的缓存策略三要素:

| 缓存策略类型 | 缓存策略值                                      | 结果                                                                                                     | 备注                                                                                                                                           |
|:------------:|:------------------------------------------------|:---------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------|
| 缓存存储策略 | cache-control:private                           | 响应数据会被缓存到客户端                                                                                 |                                                                                                                                                |
| 缓存过期策略 | Expires: 当前时间 + (date - Last-Modified) * 10% | 根据计算公式得到一个缓存过期时间                                                                         | 在没有提供任何浏览器缓存过期策略的情况下，客户端计算响应头中2个时间字段Date和Last-Modified之间的时间差值(单位:秒), 取该值的10%作为缓存过期周期 |
| 缓存对比策略 | Last-Modifed: Tue, 08 Nov 2016 06:59:00 GMT     | 浏览器会携带该值去服务端比对，比对成功则返回304, 服务端提示浏览器从本地加载数据，否在返回200并响应数据。 |                                                                                                                                                |

即: 浏览器会根据`Date`和`Last-Modified`之间的时间差值缓存一段时间，这段时间内会直接使用本地缓存数据而不会再去请求服务器(强制请求除外)，缓存过期后，会再次请求服务端，并携带上`Last-Modified`指定的时间去服务器对比并根据服务端的响应状态决定是否要从本地加载缓存数据。



## reference 

[1] 浏览器缓存机制

http://www.cnblogs.com/skynet/archive/2012/11/28/2792503.html

[2] Web 开发人员需知的 Web 缓存知识

http://www.oschina.net/news/41397/web-cache-knowledge

[3] 浏览器缓存详解:expires,cache-control,last-modified,etag详细说明

http://blog.csdn.net/eroswang/article/details/8302191

[4] 在浏览器地址栏按回车、F5、Ctrl+F5刷新网页的区别

http://cloudbbs.org/forum.php?mod=viewthread&tid=15790

http://blog.csdn.net/yui/article/details/6584401

[5] Cache Control 與 ETag

https://blog.othree.net/log/2012/12/22/cache-control-and-etag/

[6] 缓存的故事

http://segmentfault.com/blog/animabear/1190000000375344

[7] Google的PageSpeed网站优化理论中提到使用Etag可以减少服务器负担

https://developers.google.com/speed/docs/pss/AddEtags

[8] yahoo的Yslow法则中则提示谨慎设置Etag

http://developer.yahoo.com/performance/rules.html#etags

[9] H5 缓存机制浅析 移动端 Web 加载性能优化

http://segmentfault.com/a/1190000004132566

[10] 网页性能： 缓存效率实践

http://www.w3ctech.com/topic/1648

[11] 透过浏览器看HTTP缓存

http://www.cnblogs.com/skylar/p/browser-http-caching.html

[12] 浏览器缓存知识小结及应用

http://web.jobbole.com/84888/

[13] 大公司里怎样开发和部署前端代码？

http://zhihu.com/question/20790576/answer/32602154?utm_campaign=webshare&utm_source=weibo&utm_medium=zhihu

[14] 浏览器缓存机制详解

https://mangguo.org/browser-cache-mechanism-detailed/

[15] 关于缓存和 Chrome 的“新版刷新”

http://www.cnblogs.com/ziyunfei/p/6308652.html

[16] HTTP缓存控制小结

http://www.kuqin.com/shuoit/20160801/352684.html?url_type=39&object_type=webpage&pos=1

