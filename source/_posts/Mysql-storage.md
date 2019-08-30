title: Mysql-存储程序
tags:
  - MySql
categories:
  - Mysql
author: Guyuqing
copyright: true
comments: false
date: 2019-08-28 16:32:00
---
MySQL中的存储程序本质上封装了一些可执行的语句，然后给用户提供一种简单的调用方式来执行这些语句，根据调用方式的不同，我们可以把`存储程序`分为`存储例程`、`触发器`和`事件`这几种类型。其中，`存储例程`又可以被细分为`存储函数`和`存储过程`。
<!-- more -->
![存储程序](Mysql-storage/640.png)

# 自定义变量

MySQL中对我们自定义的变量的命名有个要求，那就是变量名称前必须加一个`@符号`。我们自定义变量的值的类型可以是任意MySQL支持的类型，例如我们自定义一个变量<font color='red'>a</font>：
```sql
mysql> SET @a = 1;
Query OK, 0 rows affected (0.00 sec)
```

如果我们想查看这个变量的值的话，使用<font color='Orange'>SELECT</font>语句就好了，不过仍然需要在变量名称加一个@符号：
```sql
mysql> SELECT @a;
+------+
| @a   |
+------+
|    1 |
+------+
1 row in set (0.00 sec)
```

同一个变量也可以存储存储不同类型的值，比方说我们再把一个字符串值赋值给变量<font color='red'>a</font>：
```sql
mysql> SET @a = '啦';
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT @a;
+------+
| @a   |
+------+
| 啦   |
+------+
1 row in set (0.00 sec)
```

除了把一个常量赋值给一个变量以外，我们还可以把一个变量赋值给另一个变量：
```sql
mysql> SET @b = @a;
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT @b;
+------+
| @b   |
+------+
| 啦   |
+------+
1 row in set (0.00 sec)
```

我们还可以将某个查询的结果赋值给一个变量，前提是这个<font color='red'>查询的结果只有一个值</font>：
```sql
mysql> SET @a = (SELECT first_column FROM first_table LIMIT 1);
Query OK, 0 rows affected (0.00 sec)

```

还可以用另一种形式的语句来将查询的结果赋值给一个变量：
```sql
mysql> SELECT first_column FROM first_table LIMIT 1 INTO @b;
Query OK, 1 row affected (0.00 sec)

```

我们查看一下这两个变量的值：
```sql
mysql> SELECT @a, @b;
+------+------+
| @a   | @b   |
+------+------+
|    1 |    1 |
+------+------+
1 row in set (0.00 sec)
```
如果我们的查询结果是一条记录，该记录中有多个列的值的话，我们想把这几个值分别赋值到不同的变量中，只能使用`INTO`语句了：
```sql
mysql> SELECT first_column, second_column FROM first_table LIMIT 1 INTO @a, @b;
Query OK, 1 row affected (0.00 sec)

mysql> SELECT @a, @b;                                                           
+------+------+
| @a   | @b   |
+------+------+
|    1 | aaa  |
+------+------+
1 row in set (0.00 sec)
```

# 复合语句

在MySQL客户端的交互界面处，当我们完成键盘输入并按下回车键时，MySQL客户端会检测我们输入的内容中是否包含`;`、`\g`或者`\G`这三个符号之一，如果有的话，会把我们输入的内容发送到服务器。这样一来，如果我们想给服务器发送复合语句（也就是由一条或多条语句组成的语句）的话，就需要把这些语句写到一行中，比如这样：
```sql
mysql> SELECT first_column FROM first_table ;SELECT second_column FROM first_table;
+--------------+
| first_column |
+--------------+
|            1 |
|            2 |
|         NULL |
+--------------+
3 rows in set (0.00 sec)

+---------------+
| second_column |
+---------------+
| aaa           |
| NULL          |
| ccc           |
+---------------+
3 rows in set (0.00 sec)

```

我们也可以用`delimiter`命令来自定义MySQL的检测输入结束的符号，如下：
```sql
mysql> delimiter $
mysql> SELECT first_column FROM first_table ;
    -> SELECT second_column FROM first_table;
    -> $
+--------------+
| first_column |
+--------------+
|            1 |
|            2 |
|         NULL |
+--------------+
3 rows in set (0.00 sec)

+---------------+
| second_column |
+---------------+
| aaa           |
| NULL          |
| ccc           |
+---------------+
3 rows in set (0.00 sec)

```

`delimiter $`命令意味着修改MySQL客户端检测输入结束的符号为`$`,也可以使用任何符号来作为MySQL客户端检测输入结束的符号，也包括多个字符，如下：
```sql
mysql> delimiter 666
mysql> SELECT first_column FROM first_table;
    -> SELECT second_column FROM first_table;
    -> 666
+--------------+
| first_column |
+--------------+
|            1 |
|            2 |
|         NULL |
+--------------+
3 rows in set (0.00 sec)

+---------------+
| second_column |
+---------------+
| aaa           |
| NULL          |
| ccc           |
+---------------+
3 rows in set (0.00 sec)
```

# 存储函数

## 创建存储函数
`存储函数`其实就是一种`函数`，只不过在这个函数里可以执行命令语句而已。
MySQL中定义存储函数的语句如下：
```sql
CREATE FUNCTION 存储函数名称([参数列表])
RETURNS 返回值类型
BEGIN
    函数体内容
END
```

举个🌰：
```sql
mysql> delimiter $
mysql> CREATE FUNCTION second_column(a INT)
    -> RETURNS VARCHAR(100)
    -> BEGIN
    -> RETURN (SELECT second_column FROM first_table WHERE first_column = a);
    -> END $
Query OK, 0 rows affected (0.00 sec)

mysql> delimiter ;
```

## 存储函数的调用
我们自定义的函数和系统内置函数的使用方式是一样的，都是在函数名后加小括号`()`表示函数调用
```sql
mysql> SELECT second_column(1);
+------------------+
| second_column(1) |
+------------------+
| aaa              |
+------------------+
1 row in set (0.00 sec)
```

## 查看和删除存储函数
查看定义了多少个存储函数:
```sql
SHOW FUNCTION STATUS [LIKE 需要匹配的函数名]
```

查看某个函数的具体定义:
```sql
SHOW CREATE FUNCTION 函数名
```

删除某个存储函数
```sql
DROP FUNCTION 函数名
```

## 在函数体中定义变量

在函数体中使用变量前必须先声明这个变量，函数体中的变量名`不允许加@`前缀,声明方式如下：
```sql
DECLARE 变量名 数据类型 [DEFAULT 默认值];   

mysql> delimiter $
mysql> CREATE FUNCTION var_demo(a INT)
    -> RETURNS INT
    -> BEGIN
    -> DECLARE b INT;
    -> SET b = 5;
    -> RETURN b+a;
    -> END $
Query OK, 0 rows affected (0.01 sec)

mysql> delimiter ;
```
我们调用一下这个函数：
```sql
mysql> SELECT var_demo(2);
+-------------+
| var_demo(2) |
+-------------+
|           7 |
+-------------+
1 row in set (0.00 sec)
```
如果不对声明的变量赋值，它的默认值就是NULL，也可以通过`DEFAULT`子句来显式的指定变量的默认值.
```sql
mysql> delimiter $
mysql> CREATE FUNCTION var_default_demo()
-> RETURNS INT
-> BEGIN
->     DECLARE c INT DEFAULT 1;
->     RETURN c;
-> END $
Query OK, 0 rows affected (0.00 sec)

mysql> delimiter ;

mysql> SELECT var_default_demo();
+--------------------+
| var_default_demo() |
+--------------------+
|                  1 |
+--------------------+
1 row in set (0.00 sec)

```

## 参数定义

比如我们上边编写的这个second_column函数：

```sql
mysql> CREATE FUNCTION second_column(a INT)
    -> RETURNS VARCHAR(100)
    -> BEGIN
    -> RETURN (SELECT second_column FROM first_table WHERE first_column = a);
    -> END $
```
需要注意的是，参数名不要和函数体语句中其他的变量名、命令语句的标识符冲突。并且函数参数不可以指定默认值，我们在调用函数的时候，必须显式的指定所有的参数，参数类型也一定要匹配



## 判断语句

语法格式如下：
```sql
IF 布尔表达式 THEN 
    处理语句
[ELSEIF 布尔表达式 THEN
    处理语句]
[ELSE 
    处理语句]    
END IF;
```

举个🌰：
```sql
mysql> delimiter $
mysql> CREATE FUNCTION condition_demo(i INT)
    -> RETURNS VARCHAR(10)
    -> BEGIN
    -> DECLARE result VARCHAR(10);
    -> IF i = 1 THEN
    -> SET result = '结果是1';
    -> ELSEIF i = 2 THEN
    ->  SET result = '结果是2';
    -> ELSEIF i = 3 THEN
    -> SET result = '结果是3';
    -> ELSE
    -> SET result = '非法参数';
    -> END IF;
    -> RETURN result;
    -> END $
Query OK, 0 rows affected (0.01 sec)

mysql> delimiter;


mysql> SELECT condition_demo(2);
+-------------------+
| condition_demo(2) |
+-------------------+
| 结果是2           |
+-------------------+
1 row in set (0.00 sec)

```

## 循环语句
`while`循环语法格式如下：
```sql
WHILE 布尔表达式 DO
    循环语句
END WHILE;
```

举个🌰：
```sql
mysql> delimiter $
mysql> CREATE FUNCTION sum_all(n INT UNSIGNED)
    -> RETURNS INT
    -> BEGIN
    -> DECLARE result INT DEFAULT 0;
    -> DECLARE i INT DEFAULT 1;
    -> WHILE i <= n DO
    -> SET result = result + i;
    -> SET i = i + 1;
    -> END WHILE;
    -> RETURN result;
    -> END $
Query OK, 0 rows affected (0.00 sec)

mysql> delimiter;

mysql> select sum_all(10);
+-------------+
| sum_all(10) |
+-------------+
|          55 |
+-------------+
1 row in set (0.00 sec)
```

`REPEAT`循环语法格式如下：
```sql
REPEAT
    循环语句
UNTIL 布尔表达式 END REPEAT;
```
举个🌰：
```sql
mysql> CREATE FUNCTION sum_repeat(n INT UNSIGNED)
    -> RETURNS INT
    -> BEGIN
    -> DECLARE result INT DEFAULT 0;
    -> DECLARE i INT DEFAULT 1;
    -> REPEAT
    -> -- 循环开始
    -> SET result = result + i;
    -> SET i = i + 1;
    -> UNTIL i > n END REPEAT;
    -> RETURN result;
    -> END $
Query OK, 0 rows affected (0.02 sec)

mysql> select sum_repeat(5);
+---------------+
| sum_repeat(5) |
+---------------+
|            15 |
+---------------+
1 row in set (0.01 sec)
```


`LOOP`循环语法格式如下：
```sql
循环标记:LOOP
    循环语句
    LEAVE 循环标记;
END LOOP 循环标记;
```
举个🌰：
```sql
mysql> CREATE FUNCTION sum_loop(n INT UNSIGNED)
    -> RETURNS INT
    -> BEGIN
    -> DECLARE result INT DEFAULT 0;
    -> DECLARE i INT DEFAULT 1;
    -> LOOP_NAME:LOOP -- 循环开始
    -> IF i > n THEN
    -> LEAVE LOOP_NAME;
    -> END IF;
    -> SET result = result + i;
    -> SET i = i + 1;
    -> END LOOP LOOP_NAME;
    -> RETURN result;
    -> END $
    
mysql> select sum_loop(10);
+--------------+
| sum_loop(10) |
+--------------+
|           55 |
+--------------+
1 row in set (0.00 sec)
```











# 错误解决
在MySql中创建自定义函数报错信息如下：
```sql
ERROR 1418 (HY000): This function has none of DETERMINISTIC, NO SQL, or READS SQL DATA in its declaration and binary logging is enabled (you *might* want to use the less safe log_bin_trust_function_creators variable)
```
解决方法：
```sql
mysql> set global log_bin_trust_function_creators=1;
```

















