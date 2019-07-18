---
title: Kafka-MacOs安装
date: 2019-06-10 11:38:04
tags:
    - Kafka
    - JAVA
    - 学习笔记
categories: Kafka
author: Guyuqing
copyright: true
comments: false
---
## 在MacOs上安装Kafka

```bash
~ » brew install kafka                                 
Updating Homebrew...
==> Installing dependencies for kafka: zookeeper
==> Installing kafka dependency: zookeeper
==> Downloading https://homebrew.bintray.com/bottles/zookeeper-3.4.13.mojave.bot
==> Downloading from https://akamai.bintray.com/d1/d1e4e7738cd147dceb3d91b32480c
######################################################################## 100.0%
==> Pouring zookeeper-3.4.13.mojave.bottle.tar.gz
==> Caveats
To have launchd start zookeeper now and restart at login:
  brew services start zookeeper
Or, if you don't want/need a background service you can just run:
  zkServer start
==> Summary
🍺  /usr/local/Cellar/zookeeper/3.4.13: 244 files, 33.4MB
==> Installing kafka
==> Downloading https://homebrew.bintray.com/bottles/kafka-2.2.1.mojave.bottle.t
==> Downloading from https://akamai.bintray.com/51/518f131edae4443dc664b4f4775ab
######################################################################## 100.0%
==> Pouring kafka-2.2.1.mojave.bottle.tar.gz
==> Caveats
To have launchd start kafka now and restart at login:
  brew services start kafka
Or, if you don't want/need a background service you can just run:
  zookeeper-server-start /usr/local/etc/kafka/zookeeper.properties & kafka-server-start /usr/local/etc/kafka/server.properties
==> Summary
🍺  /usr/local/Cellar/kafka/2.2.1: 163 files, 54.4MB
==> Caveats
==> zookeeper
To have launchd start zookeeper now and restart at login:
  brew services start zookeeper
Or, if you don't want/need a background service you can just run:
  zkServer start
==> kafka
To have launchd start kafka now and restart at login:
  brew services start kafka
Or, if you don't want/need a background service you can just run:
  zookeeper-server-start /usr/local/etc/kafka/zookeeper.properties & kafka-server-start /usr/local/etc/kafka/server.properties
------------------------------------------------------------
```

