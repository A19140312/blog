---
title: 《自己动手写JAVA虚拟机》学习笔记二【搜索class文件】
date: 2019-02-12 16:14:04
tags:
    - JVM
    - JAVA
    - GO
    - 学习笔记
categories: JVM
author: Guyuqing
copyright: true
comments: false
---
```java
public class HelloWorld {
    public static void main(String[] args){
        System.out.println("Hello, world!");
    }
}
```
运行上面的java程序时，我们知道首先要启动java虚拟机，然后加载主类，最后调用主类的main方法。但是在加载HelloWorld类之前，首先要加载它的超类java.lang.Object，在调用main()函数之前，虚拟机要准备好参数数组，所以需要加载java.lang.String和java.lang.String[]类。把字符串打印到控制台还需要加载java.lang.System类，等等。。那么java虚拟机如何寻找这些类的呢？

## 类路径
类路径可以分为以下三种：
 * 启动类路径(bootstrap classpath)：启动类路径默认对应jre/lib目录，Java标准库位于该路径。
 * 扩展类路径(extention classpath)：扩展类路径默认对应jre/lib/ext目录，使用Java扩展机制的类位于该路径。
 * 用户类路径(user classpath)：我们自己实现的类，以及第三方类库则位于用户类路径。用户类路径的默认值是当前路径，也就是”.”，可以给java命令传递-classpath选项来指定。

### 准备工作

把ch01的目录结构复制一份改名ch02，在ch02的目录中创建一个classpath子目录。
```base
|-jvmgo
    |-ch01
    |-ch01
        |-classpath
        |-cmd.go
        |-main.go
```
修改cmd结构体，添加XjreOption字段
```go
type Cmd struct {
	helpFlag bool
	versionFlag bool
	cpOption string
	XjreOption string
	class string
	args []string
}
```
parseCmd()函数也对应添加Xjre
```go
//命令解析
func parseCmd() *Cmd {
    ...//其他代码不变
	flag.StringVar(&cmd.cpOption,"cp","","classpath")
	flag.StringVar(&cmd.XjreOption,"Xjre","","path to jre")
	//解析命令行参数到定义的flag
	flag.Parse()
	...//其他代码不变
}
```
### 实现类路径 

采用组合模式来实现类路径，把类路径当成一个大的整体，由启动类路径、扩展类路径和用户类路径三个小路径构成，三个小路径又分别由更小的路径构成。

首先定义一个Entry接口
```go
//获取系统分隔符，windows是;类UNIX系统是:号
const pathListSeparator = string(os.PathListSeparator)

type Entry interface {
	//寻找和加载class文件  参数：class文件相对路径，路径之间用/，文件名有.class后缀
	//例如读取java.lang.Object入参是java/lang/Object.class
	readClass(classname string) ([]byte, Entry, error)

	//toString
	String() string
}
```
Entry接口一共有四种实现，CompositeEntry，WildcardEntry，ZipEntry，DirEntry
#### DirEntry
DirEntry相对简单些，表示目录形式的类路径
```go
package classpath

import (
	"path/filepath"
	"io/ioutil"
)

type DirEntry struct {
	//存放目录的绝对路径
	absDir string
}

//相当于构造函数
func newDirEntry(path string) *DirEntry {
	//将参数转换成绝对路径
	absDir, err := filepath.Abs(path)
	if err != nil {
		panic(err)
	}
	return &DirEntry{absDir}
}
//读取class文件
func (self *DirEntry) readClass (className string) ([]byte, Entry, error) {
	//把目录和class名拼成完成路径
	fileName := filepath.Join(self.absDir,className)
	//读取class文件内容
	data, err := ioutil.ReadFile(fileName)
	return data,self,err
}

//直接返回目录
func (self *DirEntry) String() string{
	return self.absDir
}
```
#### ZipEntry
ZipEntry表示ZIP或者JAR文件形式的类路径
```go
package classpath

import (
	"path/filepath"
	"archive/zip"
	"io/ioutil"
	"errors"
)

type ZipEntry struct {
	//存放目录的绝对路径
	absPath string
}

//相当于构造函数
func newZipEntry(path string) *ZipEntry {
	//将参数转换成绝对路径
	absPath, err := filepath.Abs(path)
	if err != nil {
		panic(err)
	}
	return &ZipEntry{absPath}
}

//读取class文件
func (self *ZipEntry) readClass(classname string) ([]byte, Entry, error) {
	//打开zip文件
	r, err := zip.OpenReader(self.absPath)
	if err != nil {
		return nil,nil,err
	}
	defer r.Close()

	//遍历zip包里的文件
	for _, f := range r.File {
		//找到class文件
		if f.Name == classname {
			//打开class文件
			rc , err := f.Open()
			if err != nil {
				return nil,nil,err
			}
			defer rc.Close()
			//读取class文件内容
			data, err := ioutil.ReadAll(rc)
			if err != nil {
				return nil,nil,err
			}
			return data,self,err
		}
	}
	//未找到class文件
	return nil,nil,errors.New("class not found :" +classname)
}

//直接返回目录
func (self *ZipEntry) String() string {
	return self.absPath
}
```
#### CompositeEntry
CompositeEntry表示有分隔符的类路径，CompositeEntry由更小的Entry组成，可以表示成[]Entry，go语言中则使用便利的slice

```go
package classpath

import (
	"strings"
	"errors"
)

type CompositeEntry []Entry


//将每个小路径转换成具体的Entry
func newCompositeEntry(pathList string) CompositeEntry {
	var compositeEntry []Entry
	//将路径按照分隔符进行分割
	for _, path := range strings.Split(pathList,pathListSeparator){
		entry := newEntry(path)
		compositeEntry = append(compositeEntry,entry)
	}
	return compositeEntry
}

func (self CompositeEntry) readClass(classname string) ([]byte, Entry, error) {
	//遍历entry数据
	for _, entry := range self{
		//读取class文件，依次调用每一个子路径的readClass方法
		data, from, err := entry.readClass(classname)
		if err == nil{
			return data,from,err
		}
	}
	return nil,nil,errors.New("class not found :" +classname)
}
//调用每个子路径的String方法，用分隔符拼接起来
func (self CompositeEntry) String() string {
	strs := make([]string,len(self))
	for i, entry := range self{
		strs[i] = entry.String()
	}
	return strings.Join(strs,pathListSeparator)
}
```
#### WildcardEntry
WildcardEntry表示以*结尾的类路径，实际上也是CompositeEntry，因此就不再新定义类型类
```go
package classpath

import (
	"strings"
	"os"
	"path/filepath"
)

func newWildcardEntry(path string) CompositeEntry {
	//去掉尾部的*
	baseDir := path[:len(path)-1]
	var compositeEntry []Entry
	walkFn := func(path string, info os.FileInfo, err error) error{
		if err != nil{
			return err
		}
		//如果不是目录，返回跳过标识
		if info.IsDir() && path != baseDir {
			return filepath.SkipDir
		}
		//选出jar文件
		if strings.HasSuffix(path,".jar") || strings.HasSuffix(path,".JAR"){
			jarEntry := newZipEntry(path)
			compositeEntry = append(compositeEntry,jarEntry)
		}
		return nil
	}
	//遍历baseDir路径，创建zipEntry
	filepath.Walk(baseDir,walkFn)
	//fmt.Printf("compositeEntry : %s\n",compositeEntry)
	return compositeEntry
}
```
#### Entry
四种类路径都实现完之后，再来完善下Entry接口，添加Entry实例的构造方法。
````go
func newEntry(path string) Entry {
	//如果路径中含有分隔符
	if strings.Contains(path,pathListSeparator){
		return newCompositeEntry(path)
	}
	//如果路径末尾是*
	if strings.HasSuffix(path,"*"){
		return newWildcardEntry(path)
	}
	//如果路径以jar或者zip结尾
	if strings.HasSuffix(path,".jar") || strings.HasSuffix(path,".JAR")||
		strings.HasSuffix(path,".zip") || strings.HasSuffix(path,".ZIP"){
			return newZipEntry(path)
	}
	return newDirEntry(path)
}
````
#### 实现Classpath
```go
package classpath

import (
	"path/filepath"
	"os"
	"fmt"
)

type Classpath struct {
	bootClasspath Entry
	extClasspath Entry
	userClasspath Entry
}
//使用-Xjre选项解析启动类路径和扩展类路径，使用-classpath/-cp选项解析用户类路径
func Parse(jreOption,cpOption string) *Classpath  {
	cp := &Classpath{}
	//解析启动类路径和扩展类路径
	cp.parseBootAndExtClasspath(jreOption)

	//解析用户类路径
	cp.parseUserClasspath(cpOption)
	return cp
}

func getJreDir(jreOption string) string {
	//优先使用用户输入的-Xjre作为目录
	if jreOption != "" && exists(jreOption){
		return jreOption
	}
	//在当前目录下寻找jre目录
	if exists("./jre") {
		return "./jre"
	}
	//尝试使用JAVA_HOME环境变量
	if jh := os.Getenv("JAVA_HOME"); jh != ""{
		return filepath.Join(jh,"jre")
	}
	panic("Can not find jre folder")
}

//判断目录是否存在
func exists(path string) bool {
	if _, err := os.Stat(path); err != nil{
		if os.IsNotExist(err){
			return false
		}
	}
	return true
}

func (self *Classpath) parseBootAndExtClasspath(jreOption string) {
	// 获取jre目录
	jreDir := getJreDir(jreOption)
	//jre/lib/*
	jreLibPath := filepath.Join(jreDir,"lib","*")
	self.bootClasspath = newWildcardEntry(jreLibPath)
	//jre/lib/ext/*
	jreExtPath := filepath.Join(jreDir,"lib","ext","*")
	self.extClasspath = newWildcardEntry(jreExtPath)
}

//解析用户类路径
func (self *Classpath) parseUserClasspath(cpOption string) {
	// 如果用户没有提供-classpath/-cp选项，则使用当前目录作为用户类路径
	if cpOption == ""{
		cpOption = "."
	}
	self.userClasspath = newEntry(cpOption)
}

//寻找class方法
func (self *Classpath) ReadClass(classname string) ([]byte, Entry, error) {
	//访问ReadClass方法只需传递类名，不用包含".class"后缀
	classname = classname + ".class"
	// 从bootClasspath寻找class文件
	if data, entry, err := self.bootClasspath.readClass(classname); err == nil{
		return data, entry, err
	}
	// 从extClasspath寻找class文件
	if data, entry, err := self.extClasspath.readClass(classname); err == nil{
		return data, entry, err
	}
	// 从userClasspath寻找class文件
	return self.userClasspath.readClass(classname)
}

func (self *Classpath) String() string {
	return self.userClasspath.String()
}
```
### 测试代码

完善main.go中的startJVM
```go
//模拟启动jvm
func startJVM(cmd *Cmd)  {
	// 获取Classpath
	cp := classpath.Parse(cmd.XjreOption,cmd.cpOption)
	fmt.Printf("classpath:%s class:%s args:%v\n",cp,cmd.class,cmd.args)
	// 将.替换成/(java.lang.String -> java/lang/String)
	className := strings.Replace(cmd.class,".","/",-1)
	// 读取class
	classData, _, err := cp.ReadClass(className)
	if err != nil {
		fmt.Printf("Could not find or load main class %s\n",cmd.class)
		return
	}
	fmt.Printf("class data : %v\n",classData)
}
```

编译main.go，并测试-version
```bash
$ go install jvmgo/ch02 
$ ch02 java.lang.String
# 没有传递-Xjre，会去读取$JAVA_HOME，成功打印出String.class的内容
$ ch02 -Xjre /opt  java.lang.Object 
# 传递错误-Xjre会打印出Could not find or load main class java.lang.Object
```
