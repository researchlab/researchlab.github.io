---
title: Switching between JDK 8 and 11 using SDKMAN! 
date: 2019-09-07 10:19:46
categories: [DevOps]
tags: [java]
description:
---
Mac os upgrade and use Multi-java version solution : Switching between JDK 8 and 11 using SDKMAN!
<!--more-->

> This article is transferred from https://wimdeblauwe.wordpress.com/2018/09/26/switching-between-jdk-8-and-11-using-sdkman/

> I have written about switching JDK versions on your mac before. With JDK 11 now being out, it is time to give an updated version.

## sdkman install 

You can make switching between the Oracle JDK 8 and the OpenJDK 11 very easy if you use SDKMAN!. Just follow the installation instructions at https://sdkman.io/install to get started.

## usage

After that, run `sdk list java`. This will show something like this:

```shell
curl -s "https://get.sdkman.io" | bash

                                -+syyyyyyys:
                            `/yho:`       -yd.
                         `/yh/`             +m.
                       .oho.                 hy                          .`
                     .sh/`                   :N`                `-/o`  `+dyyo:.
                   .yh:`                     `M-          `-/osysoym  :hs` `-+sys:      hhyssssssssy+
                 .sh:`                       `N:          ms/-``  yy.yh-      -hy.    `.N-````````+N.
               `od/`                         `N-       -/oM-      ddd+`     `sd:     hNNm        -N:
              :do`                           .M.       dMMM-     `ms.      /d+`     `NMMs       `do
            .yy-                             :N`    ```mMMM.      -      -hy.       /MMM:       yh
          `+d+`           `:/oo/`       `-/osyh/ossssssdNMM`           .sh:         yMMN`      /m.
         -dh-           :ymNMMMMy  `-/shmNm-`:N/-.``   `.sN            /N-         `NMMy      .m/
       `oNs`          -hysosmMMMMydmNmds+-.:ohm           :             sd`        :MMM/      yy
      .hN+           /d:    -MMMmhs/-.`   .MMMh   .ss+-                 `yy`       sMMN`     :N.
     :mN/           `N/     `o/-`         :MMMo   +MMMN-         .`      `ds       mMMh      do
    /NN/            `N+....--:/+oooosooo+:sMMM:   hMMMM:        `my       .m+     -MMM+     :N.
   /NMo              -+ooooo+/:-....`...:+hNMN.  `NMMMd`        .MM/       -m:    oMMN.     hs
  -NMd`                                    :mm   -MMMm- .s/     -MMm.       /m-   mMMd     -N.
 `mMM/                                      .-   /MMh. -dMo     -MMMy        od. .MMMs..---yh
 +MMM.                                           sNo`.sNMM+     :MMMM/        sh`+MMMNmNm+++-
 mMMM-                                           /--ohmMMM+     :MMMMm.       `hyymmmdddo
 MMMMh.                  ````                  `-+yy/`yMMM/     :MMMMMy       -sm:.``..-:-.`
 dMMMMmo-.``````..-:/osyhddddho.           `+shdh+.   hMMM:     :MmMMMM/   ./yy/` `:sys+/+sh/
 .dMMMMMMmdddddmmNMMMNNNNNMMMMMs           sNdo-      dMMM-  `-/yd/MMMMm-:sy+.   :hs-      /N`
  `/ymNNNNNNNmmdys+/::----/dMMm:          +m-         mMMM+ohmo/.` sMMMMdo-    .om:       `sh
     `.-----+/.`       `.-+hh/`         `od.          NMMNmds/     `mmy:`     +mMy      `:yy.
           /moyso+//+ossso:.           .yy`          `dy+:`         ..       :MMMN+---/oys:
         /+m:  `.-:::-`               /d+                                    +MMMMMMMNh:`
        +MN/                        -yh.                                     `+hddhy+.
       /MM+                       .sh:
      :NMo                      -sh/
     -NMs                    `/yy:
    .NMy                  `:sh+.
   `mMm`               ./yds-
  `dMMMmyo:-.````.-:oymNy:`
  +NMMMMMMMMMMMMMMMMms:`
    -+shmNMMMNmdy+:`


                                                                 Now attempting installation...


Looking for a previous installation of SDKMAN...
Looking for unzip...
Looking for zip...
Looking for curl...
Looking for sed...
Installing SDKMAN scripts...
Create distribution directories...
Getting available candidates...
Prime the config file...
Download script archive...
######################################################################## 100.0%
Extract script archive...
Install scripts...
Set version to 5.7.3+337 ...
Attempt update of login bash profile on OSX...
Added sdkman init snippet to /Users/lihong/.bash_profile
Attempt update of zsh profile...
Updated existing /Users/lihong/.zshrc



All done!


Please open a new terminal, or run the following in the existing one:

    source "/Users/lihong/.sdkman/bin/sdkman-init.sh"

Then issue the following command:

    sdk help

Enjoy!!!

➜  source ~/.sdkman/bin/sdkman-init.sh
➜  sdk version
==== BROADCAST =================================================================
* 2019-09-06: Springboot 2.1.8.RELEASE released on SDKMAN! #springboot
* 2019-09-05: Micronaut 1.2.1 released on SDKMAN! #micronautfw
* 2019-09-05: Gradle 5.6.2 released on SDKMAN! #gradle
================================================================================

SDKMAN 5.7.3+337

➜  sdk list java
================================================================================
Available Java Versions
================================================================================
 Vendor        | Use | Version      | Dist    | Status     | Identifier
--------------------------------------------------------------------------------
 AdoptOpenJDK  |     | 12.0.1.j9    | adpt    |            | 12.0.1.j9-adpt
               |     | 12.0.1.hs    | adpt    |            | 12.0.1.hs-adpt
               |     | 11.0.4.j9    | adpt    |            | 11.0.4.j9-adpt
               |     | 11.0.4.hs    | adpt    |            | 11.0.4.hs-adpt
               |     | 8.0.222.j9   | adpt    |            | 8.0.222.j9-adpt
               |     | 8.0.222.hs   | adpt    |            | 8.0.222.hs-adpt
 Amazon        |     | 11.0.4       | amzn    |            | 11.0.4-amzn
               |     | 8.0.222      | amzn    |            | 8.0.222-amzn
               |     | 8.0.202      | amzn    |            | 8.0.202-amzn
 Azul Zulu     |     | 12.0.2       | zulu    |            | 12.0.2-zulu
               |     | 11.0.4       | zulu    |            | 11.0.4-zulu
               |     | 10.0.2       | zulu    |            | 10.0.2-zulu
               |     | 9.0.7        | zulu    |            | 9.0.7-zulu
               |     | 8.0.222      | zulu    |            | 8.0.222-zulu
               |     | 8.0.202      | zulu    |            | 8.0.202-zulu
               |     | 7.0.232      | zulu    |            | 7.0.232-zulu
               |     | 7.0.181      | zulu    |            | 7.0.181-zulu
 Azul ZuluFX   |     | 11.0.2       | zulufx  |            | 11.0.2-zulufx
               |     | 8.0.202      | zulufx  |            | 8.0.202-zulufx
 BellSoft      |     | 12.0.2       | librca  |            | 12.0.2-librca
               |     | 11.0.4       | librca  |            | 11.0.4-librca
               |     | 8.0.222      | librca  |            | 8.0.222-librca
 GraalVM       |     | 19.2.0       | grl     |            | 19.2.0-grl
               |     | 19.1.1       | grl     |            | 19.1.1-grl
               |     | 19.0.2       | grl     |            | 19.0.2-grl
               |     | 1.0.0        | grl     |            | 1.0.0-rc-16-grl
 Java.net      |     | 14.ea.11     | open    |            | 14.ea.11-open
               |     | 13.ea.33     | open    |            | 13.ea.33-open
               |     | 12.0.2       | open    |            | 12.0.2-open
               |     | 11.0.2       | open    |            | 11.0.2-open
               |     | 10.0.2       | open    |            | 10.0.2-open
               |     | 9.0.4        | open    |            | 9.0.4-open
 SAP           |     | 12.0.2       | sapmchn |            | 12.0.2-sapmchn
               |     | 11.0.4       | sapmchn |            | 11.0.4-sapmchn
================================================================================
Use the Identifier for installation:

    $ sdk install java 11.0.3.hs-adpt
================================================================================
➜  sdk install java 11.0.2-open

Downloading: java 11.0.2-open

In progress...

######################################################################################################################################## 100.0%

Repackaging Java 11.0.2-open...

Done repackaging...
Cleaning up residual files...
basename: illegal option -- r
usage: basename string [suffix]
       basename [-a] [-s suffix] string [...]
mv: illegal option -- r
usage: mv [-f | -i | -n] [-v] source target
       mv [-f | -i | -n] [-v] source ... directory
basename: illegal option -- r
usage: basename string [suffix]
       basename [-a] [-s suffix] string [...]
mv: illegal option -- r
usage: mv [-f | -i | -n] [-v] source target
       mv [-f | -i | -n] [-v] source ... directory

Installing: java 11.0.2-open
basename: illegal option -- r
usage: basename string [suffix]
       basename [-a] [-s suffix] string [...]
mv: illegal option -- r
usage: mv [-f | -i | -n] [-v] source target
       mv [-f | -i | -n] [-v] source ... directory
mv: rename /Users/lihong/.sdkman/tmp/out to /Users/lihong/.Trash/out.2019-09-07_10_21_57: No such file or directory
Done installing!


Setting java 11.0.2-open as default.
➜ java --version
openjdk 11.0.2 2019-01-15
OpenJDK Runtime Environment 18.9 (build 11.0.2+9)
OpenJDK 64-Bit Server VM 18.9 (build 11.0.2+9, mixed mode)
================================================================================
```

We can now install Oracle JDK 8 with: `sdk install java 8.0.181-oracle`

And OpenJDK 11 after that with: `sdk install java 11.0.0-open`

During the installation, you can choose what version to make the default.

If you run sdk list java again, you will see what versions are installed and what version is the default one:

```shell
➜  sdk list java
================================================================================
Available Java Versions
================================================================================
 Vendor        | Use | Version      | Dist    | Status     | Identifier
--------------------------------------------------------------------------------
 AdoptOpenJDK  |     | 12.0.1.j9    | adpt    |            | 12.0.1.j9-adpt
               |     | 12.0.1.hs    | adpt    |            | 12.0.1.hs-adpt
               |     | 11.0.4.j9    | adpt    |            | 11.0.4.j9-adpt
               |     | 11.0.4.hs    | adpt    |            | 11.0.4.hs-adpt
               |     | 8.0.222.j9   | adpt    |            | 8.0.222.j9-adpt
               |     | 8.0.222.hs   | adpt    |            | 8.0.222.hs-adpt
 Amazon        |     | 11.0.4       | amzn    |            | 11.0.4-amzn
               |     | 8.0.222      | amzn    |            | 8.0.222-amzn
               |     | 8.0.202      | amzn    |            | 8.0.202-amzn
 Azul Zulu     |     | 12.0.2       | zulu    |            | 12.0.2-zulu
               |     | 11.0.4       | zulu    |            | 11.0.4-zulu
               |     | 10.0.2       | zulu    |            | 10.0.2-zulu
               |     | 9.0.7        | zulu    |            | 9.0.7-zulu
               |     | 8.0.222      | zulu    |            | 8.0.222-zulu
               |     | 8.0.202      | zulu    |            | 8.0.202-zulu
               |     | 7.0.232      | zulu    |            | 7.0.232-zulu
               |     | 7.0.181      | zulu    |            | 7.0.181-zulu
 Azul ZuluFX   |     | 11.0.2       | zulufx  |            | 11.0.2-zulufx
               |     | 8.0.202      | zulufx  |            | 8.0.202-zulufx
 BellSoft      |     | 12.0.2       | librca  |            | 12.0.2-librca
               |     | 11.0.4       | librca  |            | 11.0.4-librca
               |     | 8.0.222      | librca  |            | 8.0.222-librca
 GraalVM       |     | 19.2.0       | grl     |            | 19.2.0-grl
               |     | 19.1.1       | grl     |            | 19.1.1-grl
               |     | 19.0.2       | grl     |            | 19.0.2-grl
               |     | 1.0.0        | grl     |            | 1.0.0-rc-16-grl
 Java.net      |     | 14.ea.11     | open    |            | 14.ea.11-open
               |     | 13.ea.33     | open    |            | 13.ea.33-open
               |     | 12.0.2       | open    |            | 12.0.2-open
               | >>> | 11.0.2       | open    | installed  | 11.0.2-open
               |     | 10.0.2       | open    |            | 10.0.2-open
               |     | 9.0.4        | open    |            | 9.0.4-open
 SAP           |     | 12.0.2       | sapmchn |            | 12.0.2-sapmchn
               |     | 11.0.4       | sapmchn |            | 11.0.4-sapmchn
================================================================================
Use the Identifier for installation:

    $ sdk install java 11.0.3.hs-adpt
================================================================================
```

To temporarily switch to another version, use the sdk use command. For instance, if you made JDK 8 the default, then switch to JDK 11 in the current session by typing:

sdk use java 11.0.0-open
Result:
```shell
21:08 $ java -version
openjdk version "11" 2018-09-25
OpenJDK Runtime Environment 18.9 (build 11+28)
OpenJDK 64-Bit Server VM 18.9 (build 11+28, mixed mode)
```
To set a permanent default, use the sdk default command. For instance, to make JDK 11 the default, type: `sdk default java 11.0.0-open`
