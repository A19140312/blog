---
title: redis-sds动态字符串【学习笔记】
date: 2019-03-27 15:56:04
tags:
    - redis
    - 源码
categories: redis
copyright: true
comments: false
---
### SDS定义

```c
/*
 * 保存字符串对象的结构
 */
struct sdshdr {
    
    // buf 中已占用空间的长度
    int len;

    // buf 中剩余可用空间的长度
    int free;

    // 数据空间
    char buf[];
};

```

### SDS常用函数

```c
/*
 * 返回 sds 实际保存的字符串的长度
 *
 * T = O(1)
 */
static inline size_t sdslen(const sds s) {
    struct sdshdr *sh = (void*)(s-(sizeof(struct sdshdr)));
    return sh->len;
}

```