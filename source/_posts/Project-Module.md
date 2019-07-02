---
title: Spring Boot + MyBatis 多模块项目搭建
date: 2019-06-02 15:30:04
tags:
    - MyBatis
    - 教程
    - Spring Boot
categories: blog
copyright: true
comments: false
---
### 准备
#### 开发工具及系统环境
* IDE：IntelliJ IDEA 2019.1
* 系统环境：mac OSX

#### 项目目录结构
* biz层：业务逻辑层
* dao层：数据持久层，使用MB插件生成相关代码及xml，依赖Domain层。
* domain层：数据实体层，维护数据库实体映射关系。
* common层：提供工程层面的基础工具类。
* web层：请求处理层

### 搭建步骤

#### 搭建父工程

1、 IDEA 工具栏选择菜单 File -> New -> Project...
![](Project-Module/1.png)
2、选择Spring Initializr，Initializr默认选择Default，点击Next
![](Project-Module/2.png)
3、填写项目资料,点击Next
![](Project-Module/3.png)
4、直接点击Next
![](Project-Module/4.png)
5、填写name，点击Finish
![](Project-Module/5.png)
6、项目结构如下
![](Project-Module/6.png)
7、删除多余目录，只留如下结构
![](Project-Module/7.png)

#### 创建子模块

