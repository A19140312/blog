---
title: Kafka-MacOs安装
date: 2019-06-05 21:38:04
tags:
    - Kafka
    - JAVA
    - 学习笔记
categories: Kafka
author: Guyuqing
copyright: true
comments: false
---
### MacOS Docker 安装

安装和镜像加速参考<a href="https://www.runoob.com/docker/macos-docker-install.html">docker安装教程</a>

### Docker 下载Zookeeper 和 kafka 镜像
```bash
~ » docker pull zookeeper:latest
~ » docker pull wurstmeister/kafka:latest
~ » docker pull sheepkiller/kafka-manager
```
### 启动容器
1、创建网络：由于要涉及到zookeeper和kafka之间的通信，所以我们运用docker内部容器通信机制先新建一个网络。
```bash
~ » docker network create app

d481270a05236007178e6ed0ce4b775c9d2aebb6c13bc050bb852bc46ca0b874
```
运行 docker network ls查看新建的网络
```bash
~ » docker network ls                  

NETWORK ID          NAME                DRIVER              SCOPE
d481270a0523        app                 bridge              local
0ab6b1467267        bridge              bridge              local
cd08298f526b        host                host                local
86a734066770        none                null                local
```
运行docker network inspect app查看网络详细信息
```bash
~ » docker network inspect app                        
[
    {
        "Name": "app",
        "Id": "d481270a05236007178e6ed0ce4b775c9d2aebb6c13bc050bb852bc46ca0b874",
        "Created": "2019-07-19T06:57:10.768655482Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.18.0.0/16",
                    "Gateway": "172.18.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {},
        "Options": {},
        "Labels": {}
    }
]
```
可以看到其连接的containers为空，说明还没有容器连接进来
2、创建Zookeeper容器
```bash
~ » docker run --net=app --name zookeeper -p 2181 -t zookeeper
```

遇到了如下问题
```bash
docker: Error response from daemon: Conflict. The container name "/zookeeper" is already in use by container "26ffbd391e8c6e5e90b8f593e354f80768f179741e1de35640efacc6303fdad0". You have to remove (or rename) that container to be able to reuse that name.
See 'docker run --help'.
```
docker ps -l 查看发现已经创建的zookeeper 可以使用docker rm 删除
```bash
~ » docker ps -l                                       
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
26ffbd391e8c        zookeeper           "/docker-entrypoint.…"   8 minutes ago       Created                                 zookeeper

~ » docker rm 26ffbd391e8c
```
重新执行创建命令

{% note info %}
run，创建新容器，并为容器配置一些参数。

-t，在容器内部创建一个tty或者伪终端。

-i，允许主机终端按照容器内部的标准与其交互。

-d，后台运行容器并打印容器名称。

--name，容器名称。

-p，端口映射，参数格式为：主机物理端口:容器内部端口。

最后跟上的就是我们已经下载的镜像
{% endnote %}

3、创建Kafka容器
```bash
~ » docker run --net=app --name kafka -p 9092 \
--env HOST_IP=127.0.0.1 \
--env KAFKA_ADVERTISED_HOST_NAME=localhost  \
--env KAFKA_ADVERTISED_PORT=9092 \
--env KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
--link zookeeper \
wurstmeister/kafka:latest
```
{% note info %}

-e，配置容器环境变量。

--link，链接到另一个容器，参数格式为：目标容器名称:在本容器内的别名。

这里的环境变量设置，其实是就是对即将创建的Kafka配置文件server.properties进行初始化。

{% endnote %}

4、创建kafka-manager
```bash
~ » docker run --net=app \
--name kafka-manager \
-p 9000:9000 \
-e ZK_HOSTS=zookeeper:2181 \
sheepkiller/kafka-manager
```
访问ip:9090即可

5、测试Kafka
进入kafka容器
```bash
~ » docker exec -it kafka /bin/bash
```
发送消息
```bash
bash-4.4# kafka-console-producer.sh --broker-list localhost:9092 --topic test
>hello
>AAAA
>BBBB
>hey
```
读取消息(需要打开另一个终端)
```bash                             
bash-4.4# kafka-console-consumer.sh \
> --bootstrap-server localhost:9092 \
> --topic test --from-beginning
hello
AAAA
BBBB
hey
```
测试成功！(＾－＾)V

> 参考https://cloud.tencent.com/developer/news/371290