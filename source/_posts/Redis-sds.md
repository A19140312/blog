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
## SDS定义

```c
/*
 * 类型别名，用于指向 sdshdr 的 buf 属性
 */
typedef char *sds;

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

## SDS常用函数

### sdslen-sds长度
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
s 实际上存的是buf首个char数据的地址，也就是向前移动8个字节，就能到sdshdr的len的首地址
char buf[]这个数组没有大小，是所谓的柔性数组，是不占据内存大小的，所以sizeof(struct sdshdr)为8。
具体结构如下图
![sdshdr](Redis-sds/sdshdr.png)
### sdsavail-sds可用free空间长度
```c
/*
 * 返回 sds 可用空间的长度
 *
 * T = O(1)
 */
static inline size_t sdsavail(const sds s) {
    struct sdshdr *sh = (void*)(s-(sizeof(struct sdshdr)));
    return sh->free;
}
```

### sdsnewlen-根据字符串长度创建sds
```c
/**
 * 根据给定的初始化字符串 init 和字符串长度 initlen,创建一个新的 sds
 * @param init 初始化字符串指针
 * @param initlen 初始化字符串的长度
 * @return 创建成功返回 sdshdr 相对应的 sds,创建失败返回 NULL
 * T = O(N)
 */
sds sdsnewlen(const void *init, size_t initlen) {

    struct sdshdr *sh;

    // 根据是否有初始化内容，选择适当的内存分配方式
    // T = O(N)
    if (init) {
        // zmalloc 不初始化所分配的内存
        sh = zmalloc(sizeof(struct sdshdr)+initlen+1);
    } else {
        // zcalloc 将分配的内存全部初始化为 0
        sh = zcalloc(sizeof(struct sdshdr)+initlen+1);
    }

    // 内存分配失败，返回
    if (sh == NULL) return NULL;

    // 设置初始化长度
    sh->len = initlen;
    // 新 sds 不预留任何空间
    sh->free = 0;
    // 如果有指定初始化内容，将它们复制到 sdshdr 的 buf 中
    // T = O(N)
    if (initlen && init)
        memcpy(sh->buf, init, initlen);
    // 以 \0 结尾
    sh->buf[initlen] = '\0';

    // 返回 buf 部分，而不是整个 sdshdr
    return (char*)sh->buf;
}
```
### sdsnew-创建sds
```c
/**
 * 根据给定字符串 init ，创建一个包含同样字符串的 sds
 * @param init 如果输入为 NULL ，那么创建一个空白 sds
 * @return 创建成功返回 sdshdr 相对应的 sds，创建失败返回 NULL
 * T = O(N)
 */
sds sdsnew(const char *init) {
    size_t initlen = (init == NULL) ? 0 : strlen(init);
    return sdsnewlen(init, initlen);
}
```
### sdsempty-创建空sds
```c
/**
 * 创建并返回一个只保存了空字符串 "" 的 sds
 * @return 创建成功返回 sdshdr 相对应的 sds,创建失败返回 NULL
 * T = O(1)
 */
sds sdsempty(void) {
    return sdsnewlen("",0);
}
```
### sdsdup-复制sds创建副本
```c
/**
 * 复制给定 sds 创建副本
 * @param s sds
 * @return 创建成功返回输入 sds 的副本
 *  T = O(N)
 */
sds sdsdup(const sds s) {
    return sdsnewlen(s, sdslen(s));
}
```
### sdsfree-释放sds
```c
/**
 * 释放给定的 sds
 * @param s 
 * T = O(N)
 */
void sdsfree(sds s) {
    if (s == NULL) return;
    zfree(s-sizeof(struct sdshdr));
}
```
### sdsgrowzero-扩充sds未使用空间补0
```c
/**
 * 将 sds 扩充至指定长度，未使用的空间以 0 字节填充。
 * @param s
 * @param len 指定长度
 * @return 扩充成功返回新 sds ，失败返回 NULL
 * T = O(N)
 */
sds sdsgrowzero(sds s, size_t len) {
    struct sdshdr *sh = (void*)(s-(sizeof(struct sdshdr)));
    size_t totlen, curlen = sh->len;

    // 如果 len 比字符串的现有长度小，
    // 那么直接返回，不做动作
    if (len <= curlen) return s;

    // 扩展 sds
    // T = O(N)
    s = sdsMakeRoomFor(s,len-curlen);
    // 如果内存不足，直接返回
    if (s == NULL) return NULL;

    // 将新分配的空间用 0 填充，防止出现垃圾内容
    // T = O(N)
    sh = (void*)(s-(sizeof(struct sdshdr)));
    memset(s+curlen,0,(len-curlen+1));

    // 更新属性
    totlen = sh->len+sh->free;
    sh->len = len;
    sh->free = totlen-sh->len;

    // 返回新的 sds
    return s;
}

/**
 * 对 sds 中 buf 的长度进行扩展，确保在函数执行之后，
 * buf 至少会有 addlen + 1 长度的空余空间（额外的 1 字节是为 \0 准备的）
 * @param s 
 * @param addlen 
 * @return 扩展成功返回扩展后的 sds，扩展失败返回 NULL
 * T = O(N)
 */
sds sdsMakeRoomFor(sds s, size_t addlen) {

    struct sdshdr *sh, *newsh;

    // 获取 s 目前的空余空间长度
    size_t free = sdsavail(s);

    size_t len, newlen;

    // s 目前的空余空间已经足够，无须再进行扩展，直接返回
    if (free >= addlen) return s;

    // 获取 s 目前已占用空间的长度
    len = sdslen(s);
    sh = (void*) (s-(sizeof(struct sdshdr)));

    // s 最少需要的长度
    newlen = (len+addlen);

    // 根据新长度，为 s 分配新空间所需的大小
    if (newlen < SDS_MAX_PREALLOC)
        // 如果新长度小于 SDS_MAX_PREALLOC 
        // 那么为它分配两倍于所需长度的空间
        newlen *= 2;
    else
        // 否则，分配长度为目前长度加上 SDS_MAX_PREALLOC
        newlen += SDS_MAX_PREALLOC;
    // T = O(N)
    newsh = zrealloc(sh, sizeof(struct sdshdr)+newlen+1);

    // 内存不足，分配失败，返回
    if (newsh == NULL) return NULL;

    // 更新 sds 的空余长度
    newsh->free = newlen - len;

    // 返回 sds
    return newsh->buf;
}

/*
 * 最大预分配长度
 */
#define SDS_MAX_PREALLOC (1024*1024)
```

### sdscatlen-根据字符串长度将字符串追加到sds末尾
```c
/**
 *  将长度为 len 的字符串 t 追加到 sds 的字符串末尾
 * @param s
 * @param t 字符串t
 * @param len t的长度
 * @return 追加成功返回新 sds ，失败返回 NULL
 * T = O(N)
 */
sds sdscatlen(sds s, const void *t, size_t len) {
    
    struct sdshdr *sh;
    
    // 原有字符串长度
    size_t curlen = sdslen(s);

    // 扩展 sds 空间
    // T = O(N)
    s = sdsMakeRoomFor(s,len);

    // 内存不足？直接返回
    if (s == NULL) return NULL;

    // 复制 t 中的内容到字符串后部
    // T = O(N)
    sh = (void*) (s-(sizeof(struct sdshdr)));
    memcpy(s+curlen, t, len);

    // 更新属性
    sh->len = curlen+len;
    sh->free = sh->free-len;

    // 添加新结尾符号
    s[curlen+len] = '\0';

    // 返回新 sds
    return s;
}
```
### sdscat-将字符串追加到sds末尾
```c
/**
 * 将给定字符串 t 追加到 sds 的末尾
 * @return 追加成功返回新 sds ，失败返回 NULL
 *  T = O(N)
 */
sds sdscat(sds s, const char *t) {
    return sdscatlen(s, t, strlen(t));
}
```

### sdscatsds-将sds追加到另一个sds末尾
```c
/**
 * 将另一个 sds 追加到一个 sds 的末尾
 * @return 追加成功返回新 sds ，失败返回 NULL
 * T = O(N)
 */
sds sdscatsds(sds s, const sds t) {
    return sdscatlen(s, t, sdslen(t));
}
```
### sdscpylen-将字符串前len复制到sds
```c
/**
 * 将字符串 t 的前 len 个字符复制到 sds s 当中,覆盖原有的字符
 * 如果 sds 的长度少于 len 个字符，那么扩展 sds
 * @return 复制成功返回新的 sds ，否则返回 NULL
 * T = O(N)
 */
sds sdscpylen(sds s, const char *t, size_t len) {

    struct sdshdr *sh = (void*) (s-(sizeof(struct sdshdr)));

    // sds 现有 buf 的长度
    size_t totlen = sh->free+sh->len;

    // 如果 s 的 buf 长度不满足 len ，那么扩展它
    if (totlen < len) {
        // T = O(N)
        s = sdsMakeRoomFor(s,len-sh->len);
        if (s == NULL) return NULL;
        sh = (void*) (s-(sizeof(struct sdshdr)));
        totlen = sh->free+sh->len;
    }

    // 复制内容
    // T = O(N)
    memcpy(s, t, len);

    // 添加终结符号
    s[len] = '\0';

    // 更新属性
    sh->len = len;
    sh->free = totlen-len;

    // 返回新的 sds
    return s;
}
```
### sdscpy-将字符串复制到 sds 当中
```c
/**
 * 将字符串复制到 sds 当中,覆盖原有的字符
 * @return 复制成功返回新的 sds ，否则返回 NULL
 * T = O(N)
 */
sds sdscpy(sds s, const char *t) {
    return sdscpylen(s, t, strlen(t));
}
```