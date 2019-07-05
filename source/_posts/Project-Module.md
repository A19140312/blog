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
* dao层：数据持久层，使用MB插件生成相关代码及xml
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
8、选择项目根目录,右键->New -> Module
![](Project-Module/8.png)
9、选择Maven，点击Next
![](Project-Module/9.png)
10、填写ArifactId，点击Next
![](Project-Module/10.png)
11、点击Finish
![](Project-Module/11.png)
12、同理添加其他子模块，最终项目目录结构如下图
![](Project-Module/12.png)

#### 模块间依赖关系

各个子模块的依赖关系：
* biz层：依赖dao层，common层
* dao层：不依赖
* common层：不依赖
* web层：依赖biz层，common层。

13、父pom文件中声明所有子模块依赖
```xml
    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>com.example.test</groupId>
                <artifactId>biz</artifactId>
                <version>${project.version}</version>
            </dependency>
            <dependency>
                <groupId>com.example.test</groupId>
                <artifactId>common</artifactId>
                <version>${project.version}</version>
            </dependency>
            <dependency>
                <groupId>com.example.test</groupId>
                <artifactId>dao</artifactId>
                <version>${project.version}</version>
            </dependency>
            <dependency>
                <groupId>com.example.test</groupId>
                <artifactId>web</artifactId>
                <version>${project.version}</version>
            </dependency>
        </dependencies>
    </dependencyManagement>
```
14、biz层pom文件中添加dao层，common层依赖
```xml
    <dependencies>
        <dependency>
            <groupId>com.example.test</groupId>
            <artifactId>dao</artifactId>
        </dependency>
        <dependency>
            <groupId>com.example.test</groupId>
            <artifactId>common</artifactId>
        </dependency>
    </dependencies>
```
15、web层pom文件中添加biz层，common层依赖
```xml
    <dependencies>
        <dependency>
            <groupId>com.example.test</groupId>
            <artifactId>biz</artifactId>
        </dependency>
        <dependency>
            <groupId>com.example.test</groupId>
            <artifactId>common</artifactId>
        </dependency>
    </dependencies>
```

#### 运行项目
16、在web层pom文件中添加spring-boot-starter-web
```xml
        <!-- spring-boot -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
```

17、在web层创建com.example.test.demo.web包并添加入口类AppServiceApplication.java，目录结构如下
![](Project-Module/17.png)
入口类代码如下：
```java

package com.example.test.demo.web;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class AppServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(AppServiceApplication.class, args);
    }
}

```
18、在com.example.test.demo.web包下创建controller目录添加test方法测试接口是否可以正常访问
```java
package com.example.test.demo.web.controller;


import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("demo")
public class DemoController {

    @RequestMapping("test")
    public String test() {
        return "Hello World!";
    }
}
```

19、运行AppServiceApplication中的main方法启动项目，默认端口为8080，访问http://localhost:8080/demo/test得到如下效果
![](Project-Module/19.png)

20、在biz层创建com.example.test.demo.biz包并创建DemoService接口类代码如下：
```java
package com.example.test.demo.biz;

public interface DemoService {
    String test();
}

```

21、在com.example.test.demo.biz包下创建impl目录并添加DemoServiceImpl类，代码如下：
```java
package com.example.test.demo.biz.impl;


import com.example.test.demo.biz.DemoService;
import org.springframework.stereotype.Service;


@Service
public class DemoServiceImpl implements DemoService {

    @Override
    public String test() {
        return "biz test";
    }
}
```

22、DemoController类通过@Autowired注解注入DemoService，修改DemoController的test方法，代码如下：
```java
package com.example.test.demo.web.controller;


import com.example.test.demo.biz.DemoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("demo")
public class DemoController {

    @Autowired
    private DemoService demoService;

    @RequestMapping("test")
    public String test() {
        return demoService.test();
    }
}
```

23、在入口类AppServiceApplication上添加@ComponentScan注解
```java
package com.example.test.demo.web;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

@SpringBootApplication
@ComponentScan(basePackages = {
        "com.example.test.demo.*"
})
public class AppServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(AppServiceApplication.class, args);
    }
}
```

24、更改完之后运行main方法，访问http://localhost:8080/demo/test得到如下效果
![](Project-Module/24.png)

25、其他层同理验证。

