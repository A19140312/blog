---
title: 设置git忽略.idea文件
date: 2019-07-11 11:39:04
tags:
    - git
    - 教程
categories: 项目搭建
author: Guyuqing
copyright: true
comments: false
---
1.将.idea目录加入ignore：
```bash
$ echo '.idea' >> .gitignore
```

2.从git中删除idea：
```bash
$ git rm -r --cached .idea
```

3.将.gitignore文件加入git：
```bash
$ git add .gitignore
```

4.提交.gitignore文件，将.idea从代码仓库中忽略：
```bash
$ git commit -m '忽略.idea文件夹'
```

5、Push到Git服务器：

```bash
$ git push
```