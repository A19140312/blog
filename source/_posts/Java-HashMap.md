---
title: JAVA-HashMap源码解析
date: 2020-03-05 15:07:00
tags:
    - JAVA
    - 源码
    - 学习笔记
categories: JAVA
author: Guyuqing
copyright: true
comments: false
---
# HashMap 的存储结构
HashMap是数组+链表+红黑树（JDK1.8增加了红黑树部分）实现的
```java
	static class Node<K,V> implements Map.Entry<K,V> {
		final int hash;// key的hash值
		final K key; // key
		V value; // value
		Node<K,V> next; //同一个hash值下的链表/红黑树

		Node(int hash, K key, V value, Node<K,V> next) {
			this.hash = hash;
			this.key = key;
			this.value = value;
			this.next = next;
		}

		public final K getKey()        { return key; }
		public final V getValue()      { return value; }
		public final String toString() { return key + "=" + value; }

		public final int hashCode() {
			return Objects.hashCode(key) ^ Objects.hashCode(value);
		}

		public final V setValue(V newValue) {
			V oldValue = value;
			value = newValue;
			return oldValue;
		}

		public final boolean equals(Object o) {
			if (o == this)
				return true;
			if (o instanceof Map.Entry) {
				Map.Entry<?,?> e = (Map.Entry<?,?>)o;
				if (Objects.equals(key, e.getKey()) &&
						Objects.equals(value, e.getValue()))
					return true;
			}
			return false;
		}
	}
```
TreeNode<K,V> 继承 LinkedHashMap.Entry<K,V>，用来实现红黑树相关的存储结构
```java
     static final class TreeNode<K,V> extends LinkedHashMap.Entry<K,V> {
         TreeNode<K,V> parent;  // 存储当前节点的父节点
         TreeNode<K,V> left;　// 存储当前节点的左孩子
         TreeNode<K,V> right;　// 存储当前节点的右孩子
         TreeNode<K,V> prev;    // prev则指向前一个节点（原链表中的前一个节点）
         boolean red;　// 存储当前节点的颜色（红、黑）
         TreeNode(int hash, K key, V val, Node<K,V> next) {
             super(hash, key, val, next);
         }
 
         final TreeNode<K,V> root() {
         }
 
         static <K,V> void moveRootToFront(Node<K,V>[] tab, TreeNode<K,V> root) {
         }
 
         final TreeNode<K,V> find(int h, Object k, Class<?> kc) {
         }
 
         final void treeify(Node<K,V>[] tab) {
         }
 
         final Node<K,V> untreeify(HashMap<K,V> map) {
         }
 
         final TreeNode<K,V> putTreeVal(HashMap<K,V> map, Node<K,V>[] tab,
                                        int h, K k, V v) {
         }
 
         final void removeTreeNode(HashMap<K,V> map, Node<K,V>[] tab,
                                   boolean movable) {
         }
 
         final void split(HashMap<K,V> map, Node<K,V>[] tab, int index, int bit) {
         }
 
         /* ------------------------------------------------------------ */
         // Red-black tree methods, all adapted from CLR
         // 红黑树相关操作
         static <K,V> TreeNode<K,V> rotateLeft(TreeNode<K,V> root,
                                               TreeNode<K,V> p) {
         }
 
         static <K,V> TreeNode<K,V> rotateRight(TreeNode<K,V> root,
                                                TreeNode<K,V> p) {
         }
 
         static <K,V> TreeNode<K,V> balanceInsertion(TreeNode<K,V> root,
                                                     TreeNode<K,V> x) {
         }
 
         static <K,V> TreeNode<K,V> balanceDeletion(TreeNode<K,V> root,
                                                    TreeNode<K,V> x) {
         }       
 
         static <K,V> boolean checkInvariants(TreeNode<K,V> t) {
         }
 
     }
```

# 各常量、成员变量作用　　
```java
	/**
	 * 默认初始容量
	 */
	static final int DEFAULT_INITIAL_CAPACITY = 1 << 4; // aka 16

	/**
	 * 最大容量， 当传入容量过大时将被这个值替换
	 */
	static final int MAXIMUM_CAPACITY = 1 << 30;

	/**
	 * 默认负载因子
	 */
	static final float DEFAULT_LOAD_FACTOR = 0.75f;

	/**
	 * 当链表的长度超过8，有可能会转化成树
	 */
	static final int TREEIFY_THRESHOLD = 8;

	/**
	 * 当链表的长度小于6则会从红黑树转回链表
	 */
	static final int UNTREEIFY_THRESHOLD = 6;

	/**
	 * 在转变成树之前，还会有一次判断，只有键值对数量大于 64 才会发生转换。
	 * 这是为了避免在哈希表建立初期，多个键值对恰好被放入了同一个链表中而导致不必要的转化。
	 */
	static final int MIN_TREEIFY_CAPACITY = 64;

	/**
	 * 用来存储 key-value 的节点对象。在 HashMap 中它有个专业的叫法 buckets ，中文叫作桶。
	 */
	transient Node<K,V>[] table;

	/**
	 * 同时封装了 keySet 和 values 的视图
	 */
	transient Set<Map.Entry<K,V>> entrySet;

	/**
	 * 容器中实际存放 Node 的大小
	 */
	transient int size;

	/**
	 * HashMap 在结构上被修改的次数，结构修改是指改变HashMap中映射的次数，或者以其他方式修改其内部结构(例如，rehash)。
	 */
	transient int modCount;

	/**
	 * HashMap的扩容阈值(=负载因子*table的容量)
	 * 在HashMap中存储的Node键值对超过这个数量时，自动扩容容量为原来的二倍
	 * @serial
	 */
	int threshold;

	/**
	 * 负载因子
	 * @serial
	 */
	final float loadFactor;
```
# 构造方法
```java
	/**
	 * Constructs an empty <tt>HashMap</tt> with the specified initial
	 * capacity and load factor.
	 *
	 * @param  initialCapacity 初始容量
	 * @param  loadFactor      负载因子
	 * @throws IllegalArgumentException 如果初始容量为负或者负载因子非正数抛出该异常
	 */
	public HashMap(int initialCapacity, float loadFactor) {
		// 当初始容量为负
		if (initialCapacity < 0)
			throw new IllegalArgumentException("Illegal initial capacity: " +
					initialCapacity);
		// 当初始容量大于最大容量 2^30 ，初始容量= 2^30
		if (initialCapacity > MAXIMUM_CAPACITY)
			initialCapacity = MAXIMUM_CAPACITY;
		// 当负载因子非正数 或 负载因子是NaN(Not a Number，0.0f/0.0f的值就是NaN)
		if (loadFactor <= 0 || Float.isNaN(loadFactor))
			throw new IllegalArgumentException("Illegal load factor: " +
					loadFactor);
		// 赋值
		this.loadFactor = loadFactor;
		this.threshold = tableSizeFor(initialCapacity);
	}

	/**
	 * 获取比传入参数大的最小的2的N次幂。
	 */
	static final int tableSizeFor(int cap) {
		int n = cap - 1;
		n |= n >>> 1;
		n |= n >>> 2;
		n |= n >>> 4;
		n |= n >>> 8;
		n |= n >>> 16;
		return (n < 0) ? 1 : (n >= MAXIMUM_CAPACITY) ? MAXIMUM_CAPACITY : n + 1;
	}
```

# put方法
put方法主要是调用putVal方法
```java
	/**
	 * 使 key 和 value 产生关联，但如果有相同的 key 则新的会替换掉旧的。
	 */
	public V put(K key, V value) {
		return putVal(hash(key), key, value, false, true);
	}

	/**
	 * h >>> 16:无符号右移动16位，意味着取高16位二进制
	 * 低16位与高16位进行异或
	 */
	static final int hash(Object key) {
		int h;
		// 如果为 null 则返回的就是 0，否则就是 hashCode 异或上 hashCode 无符号右移 16 位
		return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
	}
```

# putVal方法
```java
	/**
	 * Implements Map.put and related methods
	 *
	 * @param hash key的hash值
	 * @param key the key
	 * @param value the value to put
	 * @param onlyIfAbsent 如果true代表不更改现有的值
	 * @param evict 如果为false表示table为创建状态
	 * @return previous value, or null if none
	 */
	final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
				   boolean evict) {
		Node<K,V>[] tab; Node<K,V> p; int n, i;
		/**
		 * 判断table是否等于空或者table的长度等于0，如果是就进行初始化
		 * 此时通过resize()方法得到初始化的table
		 */
		if ((tab = table) == null || (n = tab.length) == 0)
			n = (tab = resize()).length;
		/**
		 * 对hash码进行散列 ，对值的位置进行确认
		 * 如果tab[i] 为null 表示没有hash冲突，就新增一个元素
		 */
		if ((p = tab[i = (n - 1) & hash]) == null)
			tab[i] = newNode(hash, key, value, null);
		else {
			// 如果tab[i] 不为null，表示该位置有值了。
			Node<K,V> e; K k;
			//HashMap中判断key相同的条件是key的hash相同，并且符合equals方法。这里判断了p.key是否和插入的key相等，如果相等，则将p的引用赋给e
			//这里为什么要把p赋值给e，而不是直接覆盖原值呢？答案很简单，现在我们只判断了第一个节点，后面还可能出现key相同，所以需要在最后一并处理
			if (p.hash == hash &&
					((k = p.key) == key || (key != null && key.equals(k))))
				e = p;
			/**
			 * 判断是否是红黑树
			 * p是红黑树节点，那么肯定插入后仍然是红黑树节点，所以我们直接强制转型p后调用TreeNode.putTreeVal方法，返回的引用赋给e
			 */
			else if (p instanceof TreeNode)
				e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
			// 否则就是链表
			else {
				// 如果是链表，要遍历到最后一个节点进行插入
				for (int binCount = 0; ; ++binCount) {
					if ((e = p.next) == null) {
						// 插入到链尾
						p.next = newNode(hash, key, value, null);
						// 判断节点的长度是否大于TREEIFY_THRESHOLD红黑树的阈值，是就进行转换
						if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
							treeifyBin(tab, hash);
						break;
					}
					// 对链表中的相同 hash 值且 key 相同的进一步作检查
					if (e.hash == hash &&
							((k = e.key) == key || (key != null && key.equals(k))))
						break;
					p = e;
				}
			}
			/**
			 * 插入
			 */
			if (e != null) { // existing mapping for key
				// 取出旧值，onlyIfAbsent此时为 false，所以不管 oldValue 有与否，都拿新值来替换
				V oldValue = e.value;
				if (!onlyIfAbsent || oldValue == null)
					e.value = value;
				afterNodeAccess(e);
				return oldValue;
			}
		}
		// 记录修改次数
		++modCount;
		// 超过阈值 threshold = capacity * factor，调用 resize() 进行扩容
		if (++size > threshold)
			resize();
		afterNodeInsertion(evict);
		return null;
	}
```

# resize 扩容兼初始化
```java
	/**
	 * Initializes or doubles table size.  If null, allocates in
	 * accord with initial capacity target held in field threshold.
	 * Otherwise, because we are using power-of-two expansion, the
	 * elements from each bin must either stay at same index, or move
	 * with a power of two offset in the new table.
	 * 扩容兼初始化
	 * @return the table
	 */
	final Node<K,V>[] resize() {
		//将原来的table指针保存
		Node<K,V>[] oldTab = table;
		//获取原来数组的长度，oldTab为null说明还没有进行初始化
		int oldCap = (oldTab == null) ? 0 : oldTab.length;
		//保存以前重构table的阈值
		int oldThr = threshold;
		int newCap, newThr = 0;
		//oldCap > 0表示已经初始化过了
		if (oldCap > 0) {
			//当原来的容量已经达到最大容量的时候，将阈值设置为Integer.MAX_VALUE，这样就不会再发生重构的情况
			if (oldCap >= MAXIMUM_CAPACITY) {
				threshold = Integer.MAX_VALUE;
				return oldTab;
			}
			// 否则将旧的容量扩大两倍
			// 当它小于最大容量，并且旧的容量大于初始化最小容量的时候，
			// 将新的阈值设置为旧的阈值的两倍, 新的容量设置为旧容量的2倍
			else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY &&
					oldCap >= DEFAULT_INITIAL_CAPACITY)
				newThr = oldThr << 1; // double threshold
		}
		//虽然还没有初始化，但是设置过了阈值，将旧的阈值设置为新的容量
		else if (oldThr > 0) // initial capacity was placed in threshold
			newCap = oldThr;
		else {
			//没有初始化阈值的时候采用默认算法计算阈值
			newCap = DEFAULT_INITIAL_CAPACITY;
			newThr = (int)(DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY);
		}
		// 对应oldCap = 0 && oldThr > 0的情况
		if (newThr == 0) {
			//重新用默认负载因子计算 扩容阈值
			float ft = (float)newCap * loadFactor;
			// 如果新容量小于最大容量 && 新扩容阈值(ft) 小于最大容量
			// 新阈值 = ft 否则 新阈值 = int的最大范围
			newThr = (newCap < MAXIMUM_CAPACITY && ft < (float)MAXIMUM_CAPACITY ?
					(int)ft : Integer.MAX_VALUE);
		}
		// 把当前阈值设为新阈值
		threshold = newThr;
		// 根据新容量，创建新table
		@SuppressWarnings({"rawtypes","unchecked"})
		Node<K,V>[] newTab = (Node<K,V>[])new Node[newCap];
		// 将当前table 设置为新扩容的table
		table = newTab;
		// 如果已经被初始化过
		if (oldTab != null) {
			//将旧数组中的元素全部取出，重新映射到新数组中
			for (int j = 0; j < oldCap; ++j) {
				Node<K,V> e;
				if ((e = oldTab[j]) != null) {
					oldTab[j] = null;
					if (e.next == null)
						// 该节点没有next节点，表示没有链表，没有冲突，那重新计算下位置
						newTab[e.hash & (newCap - 1)] = e;
					else if (e instanceof TreeNode)
						// 冲突的是一棵树节点，分裂成 2 个树，或者如果树很小就转成链表
						((TreeNode<K,V>)e).split(this, newTab, j, oldCap);
					else {
						// 对原来的链表部分进行重构
						Node<K,V> loHead = null, loTail = null;
						Node<K,V> hiHead = null, hiTail = null;
						Node<K,V> next;
						do {
							next = e.next;
							// 索引不变
							if ((e.hash & oldCap) == 0) {
								if (loTail == null)
									loHead = e;
								else
									loTail.next = e;
								loTail = e;
							}
							// 原索引+oldCap
							else {
								if (hiTail == null)
									hiHead = e;
								else
									hiTail.next = e;
								hiTail = e;
							}
						} while ((e = next) != null);
						// 原索引放到 tables 里
						if (loTail != null) {
							loTail.next = null;
							newTab[j] = loHead;
						}
						// 原索引+oldCap放到  tables 里
						if (hiTail != null) {
							hiTail.next = null;
							newTab[j + oldCap] = hiHead;
						}
					}
				}
			}
		}
		// 返回扩容后的table
		return newTab;
	}
```
# split 扩容时重新划分树

```java
		/**
		 * 扩容时重新划分树
		 * @param map the map
		 * @param tab 扩容后的数组
		 * @param index 数组索引
		 * @param bit 原数组容量
		 */
		final void split(HashMap<K,V> map, Node<K,V>[] tab, int index, int bit) {
			//b设置为当前桶的头节点
			TreeNode<K,V> b = this;
			// Relink into lo and hi lists, preserving order
			//低位树链表头节点，尾结点
			TreeNode<K,V> loHead = null, loTail = null;
			//高位树链表头节点，尾结点
			TreeNode<K,V> hiHead = null, hiTail = null;
			//lc低位树链表中节点个数，hc高位树链表中节点个数
			int lc = 0, hc = 0;
			//e当前遍历节点
			for (TreeNode<K,V> e = b, next; e != null; e = next) {
				//当前遍历节点的后继节点
				next = (TreeNode<K,V>)e.next;
				//将当前遍历节点后继设为null
				e.next = null;
				if ((e.hash & bit) == 0) {
					//==0表示当前遍历节点应该存放在低位
					//如果低位中还没有节点
					//将当前遍历节点设为低位头节点
					if ((e.prev = loTail) == null)
						loHead = e;
					else
						//将当前遍历节点加入到链表的尾部
						loTail.next = e;
					//设置尾节点为当前遍历节点
					loTail = e;
					//低位链表中的节点数加1
					++lc;
				}
				//!=0表示当前遍历节点应该存放在高位
				else {
					if ((e.prev = hiTail) == null)
						hiHead = e;
					else
						hiTail.next = e;
					hiTail = e;
					++hc;
				}
			}
			//如果低位节点链表不为null
			if (loHead != null) {
				//低位节点链表中节点的个数小于6，此时需要将树结构转为链表结构
				if (lc <= UNTREEIFY_THRESHOLD)
					tab[index] = loHead.untreeify(map);
				else {//链表中节点的个数满足保持树型结构所需要的节点个数
					//低位桶的头节点设为链表的头节点
					tab[index] = loHead;
					// 高位节点链表不为null，说明有节点从原树结构中分离出去了
					// 原有树结构被破坏
					// 所以低位的节点链表需要重新构建树结构
					if (hiHead != null) // (else is already treeified)
						loHead.treeify(tab);
				}
			}
			// 同理
			if (hiHead != null) {
				if (hc <= UNTREEIFY_THRESHOLD)
					tab[index + bit] = hiHead.untreeify(map);
				else {
					tab[index + bit] = hiHead;
					if (loHead != null)
						hiHead.treeify(tab);
				}
			}
		}
```

# putTreeVal 在红黑树中添加节点
```java
		/**
		 *
		 * @param map 当前节点所在的HashMap对象
		 * @param tab 当前HashMap对象的元素数组
		 * @param h key的hash值
		 * @param k key
		 * @param v value
		 * @return 指定key所匹配到的节点对象，针对这个对象去修改V（返回空说明创建了一个新节点）
		 */
		final TreeNode<K,V> putTreeVal(HashMap<K,V> map, Node<K,V>[] tab,
									   int h, K k, V v) {
			// 定义k的Class对象
			Class<?> kc = null;
			// 标识是否已经遍历过一次树，未必是从根节点遍历的，但是遍历路径上一定已经包含了后续需要比对的所有节点。
			boolean searched = false;
			//父节点不为空那么查找根节点，为空那么自身就是根节点
			TreeNode<K,V> root = (parent != null) ? root() : this;
			// 从根节点开始遍历，没有终止条件，只能从内部退出
			for (TreeNode<K,V> p = root;;) {
				// 声明方向、当前节点hash值、当前节点的键对象
				int dir, ph; K pk;
				// 如果当前节点hash 大于 指定key的hash值,要添加的元素应该放置在当前节点的左侧
				if ((ph = p.hash) > h)
					dir = -1;
				// 如果当前节点hash 小于 指定key的hash值,要添加的元素应该放置在当前节点的右侧
				else if (ph < h)
					dir = 1;
				// 如果当前节点的键对象 和 指定key对象相同,那么就返回当前节点对象
				else if ((pk = p.key) == k || (k != null && k.equals(pk)))
					return p;
				// 走到这一步说明 当前节点的hash值  和 指定key的hash值  是相等的，但是equals不等
				else if ((kc == null &&
						(kc = comparableClassFor(k)) == null) ||
						(dir = compareComparables(kc, k, pk)) == 0) {
					// 走到这里说明：指定key没有实现comparable接口   或者   实现了comparable接口并且和当前节点的键对象比较之后相等（仅限第一次循环）
					/**
					 * searched 标识是否已经对比过当前节点的左右子节点了
					 * 如果还没有遍历过，那么就递归遍历对比，看是否能够得到那个键对象equals相等的的节点
					 * 如果得到了键的equals相等的的节点就返回
					 * 如果还是没有键的equals相等的节点，那说明应该创建一个新节点了
					 */
					if (!searched) {// 如果还没有比对过当前节点的所有子节点
						// 定义要返回的节点、和子节点
						TreeNode<K,V> q, ch;
						// 标识已经遍历过一次了
						searched = true;
						/**
						 * 红黑树也是二叉树，所以只要沿着左右两侧遍历寻找就可以了
						 * 这是个短路运算，如果先从左侧就已经找到了，右侧就不需要遍历了
						 * find 方法内部还会有递归调用
						 */
						if (((ch = p.left) != null &&
								(q = ch.find(h, k, kc)) != null) ||
								((ch = p.right) != null &&
										(q = ch.find(h, k, kc)) != null))
							// 找到了指定key键对应的
							return q;
					}
					// 走到这里就说明，遍历了所有子节点也没有找到和当前键equals相等的节点
					dir = tieBreakOrder(k, pk);// 再比较一下当前节点键和指定key键的大小
				}
				// 定义xp指向当前节点
				TreeNode<K,V> xp = p;
				/**
				 * 如果dir小于等于0，那么看当前节点的左节点是否为空，
				 * 如果为空，就可以把要添加的元素作为当前节点的左节点，如果不为空，还需要下一轮继续比较
				 *
				 * 如果dir大于等于0，那么看当前节点的右节点是否为空，
				 * 如果为空，就可以把要添加的元素作为当前节点的右节点，如果不为空，还需要下一轮继续比较
				 *
				 * 如果以上两条当中有一个子节点不为空，
				 * 这个if中还做了一件事，那就是把p已经指向了对应的不为空的子节点，开始下一轮的比较
				 */
				if ((p = (dir <= 0) ? p.left : p.right) == null) {
					// 如果恰好要添加的方向上的子节点为空，此时节点p已经指向了这个空的子节点
					// 获取当前节点的next节点
					Node<K,V> xpn = xp.next;
					// 创建一个新的树节点
					TreeNode<K,V> x = map.newTreeNode(h, k, v, xpn);
					if (dir <= 0)
						// 左孩子指向到这个新的树节点
						xp.left = x;
					else
						// 右孩子指向到这个新的树节点
						xp.right = x;
					// 链表中的next节点指向到这个新的树节点
					xp.next = x;
					// 这个新的树节点的父节点、前节点均设置为 当前的树节点
					x.parent = x.prev = xp;
					// 如果原来的next节点不为空
					if (xpn != null)
						// 那么原来的next节点的前节点指向到新的树节点
						((TreeNode<K,V>)xpn).prev = x;
					// 重新平衡，以及新的根节点置顶
					moveRootToFront(tab, balanceInsertion(root, x));
					// 返回空，意味着产生了一个新节点
					return null;
				}
			}
		}
```

# treeifyBin 链表转成红黑树
```java
	/**
	 * 将指定hash节点处的链表替换成红黑树
	 * 除非table太小了，将用resizes（）改变树的容量
	 * Replaces all linked nodes in bin at index for given hash unless
	 * table is too small, in which case resizes instead.
	 */
	final void treeifyBin(Node<K,V>[] tab, int hash) {
		int n, index; Node<K,V> e;
		// 如果 table 为null 或者
		// table的长度小于 MIN_TREEIFY_CAPACITY（默认64））不进行树化，调用resize进行扩容
		if (tab == null || (n = tab.length) < MIN_TREEIFY_CAPACITY)
			resize();
		// 如果 该hash值对应的 tab[index] 不为null，证明该位置有值
		else if ((e = tab[index = (n - 1) & hash]) != null) {
			TreeNode<K,V> hd = null, tl = null;
			// 遍历链表,将单项链表改为双向链表
			do {
				// node 节点转成 TreeNode节点
				TreeNode<K,V> p = replacementTreeNode(e, null);
				// 如果树为空
				if (tl == null)
					// 设置树的根
					hd = p;
				else {
					// 设置新节点p的上一个节点
					p.prev = tl;
					// 设置 上一节点的 next 指向当前节点
					tl.next = p;
				}
				//保存上一节点
				tl = p;
			} while ((e = e.next) != null);
			// 如果树的根节点不为null，调用treeify()进行树化
			if ((tab[index] = hd) != null)
				hd.treeify(tab);
		}
	}

		/**
		 * Forms tree of the nodes linked from this node.
		 * @return root of tree
		 */
		final void treeify(Node<K,V>[] tab) {
			// 树的根节点
			TreeNode<K,V> root = null;
			//x是当前节点，next是后继
			for (TreeNode<K,V> x = this, next; x != null; x = next) {
				// 后继节点
				next = (TreeNode<K,V>)x.next;
				// 左右儿子设为null
				x.left = x.right = null;
				// 如果根是 null
				if (root == null) {
					// 设置父节点为null
					x.parent = null;
					// 设置为黑色
					x.red = false;
					// 把当前节点设置为根节点
					root = x;
				}
				// 如果有根节点
				else {
					K k = x.key;
					int h = x.hash;
					Class<?> kc = null;
					// 遍历树，进行二叉搜索树的插入
					for (TreeNode<K,V> p = root;;) {
						// p指向遍历中的当前节点，
						// x为待插入节点，
						// k是x的key，
						// h是x的hash值，
						// ph是p的hash值，
						// pk是p的key，
						// dir用来指示x节点与p的比较，-1表示比p小，1表示比p大
						// 不存在相等情况，因为HashMap中是不存在两个key完全一致的情况。
						int dir, ph;
						K pk = p.key;
						// 待插入x的hash值小于当前点p的hash值
						if ((ph = p.hash) > h)
							dir = -1;
						else if (ph < h)
							dir = 1;
						// 如果hash值相等，那么判断k是否实现了comparable接口，
						// 如果实现了comparable接口就使用compareTo进行进行比较，
						// 如果仍旧相等或者没有实现comparable接口，则在tieBreakOrder中比较
						else if ((kc == null &&
								(kc = comparableClassFor(k)) == null) ||
								(dir = compareComparables(kc, k, pk)) == 0)
							dir = tieBreakOrder(k, pk);

						// 将当前节点赋值给XP
						TreeNode<K,V> xp = p;
						// 如果dir <= 0 ,p 等于 p的左儿子，否则p 等于 p的右儿子
						// 如果 p 等于 null，则插入x节点
						if ((p = (dir <= 0) ? p.left : p.right) == null) {
							// x的父节点指向 xp
							x.parent = xp;
							if (dir <= 0)
								xp.left = x;
							else
								xp.right = x;
							// 进行平衡处理，保证红黑树的性质
							root = balanceInsertion(root, x);
							break;
						}
					}
				}
			}
			//root节点移动到桶中的第一个元素，也就是链表的首节点
			moveRootToFront(tab, root);
		}
```


# untreeify 树变链表

```java
		/**
		 * 树变链表
		 * //重新创建链表节点，并形成链表结构
		 */
		final Node<K,V> untreeify(HashMap<K,V> map) {
			Node<K,V> hd = null, tl = null;
			for (Node<K,V> q = this; q != null; q = q.next) {
				Node<K,V> p = map.replacementNode(q, null);
				if (tl == null)
					hd = p;
				else
					tl.next = p;
				tl = p;
			}
			return hd;
		}
```

# balanceInsertion 红黑树插入平衡
```java
		/**
		 * 红黑树的插入平衡处理
		 * @param root 根节点
		 * @param x 新插入节点
		 * @return
		 */
		static <K,V> TreeNode<K,V> balanceInsertion(TreeNode<K,V> root,
													TreeNode<K,V> x) {
			//插入的节点默认为红色
			x.red = true;
			// xp：当前节点的父节点
			// xpp：爷爷节点
			// xppl：左叔叔节点
			// xppr：右叔叔节点
			for (TreeNode<K,V> xp, xpp, xppl, xppr;;) {
				// L1：如果父节点为空、说明当前节点就是根节点，那么把当前节点标为黑色，返回当前节点
				if ((xp = x.parent) == null) {
					x.red = false;
					return x;
				}
				// 父节点不为空
				// L2：如果 父节点为黑色 那么插入节点为红色不影响树的平衡
				// L3：或者 爷爷节点为空 即 父节点是根节点
				// 返回根节点
				else if (!xp.red || (xpp = xp.parent) == null)
					return root;
				// L4：父节点和祖父节点都存在，并且其父节点是祖父节点的左节点
				if (xp == (xppl = xpp.left)) {
					// L4.1 插入节点的叔叔节点是红色
					if ((xppr = xpp.right) != null && xppr.red) {
						// 将叔叔设置为黑色，父亲设为黑色，爷爷设为红色
						xppr.red = false;
						xp.red = false;
						xpp.red = true;
						// 将 爷爷 设为当前插入节点，自底向上，重新变色
						x = xpp;
					}
					//L4.2：插入节点的叔叔节点是黑色或不存在
					else {
						// L4.2.1 插入节点是其父节点的右孩子
						if (x == xp.right) {
							// x 设置为 父节点
							// 将 父节点 左旋
							// 旋转之后，原父子关系对调，因此，x还是子节点
							root = rotateLeft(root, x = xp);
							// 将xp 设为父节点，xpp设为爷爷节点
							xpp = (xp = x.parent) == null ? null : xp.parent;
						}
						// L4.2.1 插入节点是其父节点的左孩子
						if (xp != null) {
							// 父节点设为黑色
							xp.red = false;
							// 如果 有爷爷节点
							if (xpp != null) {
								// 爷爷节点设置为红色
								xpp.red = true;
								//  爷爷节点右旋
								root = rotateRight(root, xpp);
							}
						}
					}
				}
				// L5：插入的节点父节点和祖父节点都存在，并且其 父节点是祖父节点的右节点
				else {
					// L5.1：插入节点的叔叔节点是红色
					if (xppl != null && xppl.red) {
						// 将叔叔设置为黑色，父亲设为黑色，爷爷设为红色
						xppl.red = false;
						xp.red = false;
						xpp.red = true;
						// 将 爷爷 设为当前插入节点，自底向上，重新变色
						x = xpp;
					}
					//L5.2：插入节点的叔叔节点是黑色或不存在
					else {
						// L5.2.1 插入节点是其父节点的左孩子
						if (x == xp.left) {
							// x 设置为 父节点
							// 将 父节点 右旋
							// 旋转之后，原父子关系对调，因此，x还是子节点
							root = rotateRight(root, x = xp);
							xpp = (xp = x.parent) == null ? null : xp.parent;
						}
						// L5.2.2 插入节点是其父节点的右孩子
						if (xp != null) {
							// 父节点设为黑色
							xp.red = false;
							// 如果 有爷爷 节点
							if (xpp != null) {
								// 爷爷节点设置为红色
								xpp.red = true;
								//  爷爷节点右旋
								root = rotateLeft(root, xpp);
							}
						}
					}
				}
			}
		}
```

# get方法
```java
	public V get(Object key) {
		Node<K,V> e;
		return (e = getNode(hash(key), key)) == null ? null : e.value;
	}
```

# getNode
```java
	/**
	 * Implements Map.get and related methods
	 *
	 * @param hash key 的hash值
	 * @param key the key
	 * @return the node, or null if none
	 */
	final Node<K,V> getNode(int hash, Object key) {
		Node<K,V>[] tab; Node<K,V> first, e; int n; K k;
		// table 不为null && 不为空，并且 (n - 1) & hash 算出来的index位置有值
		if ((tab = table) != null && (n = tab.length) > 0 &&
				(first = tab[(n - 1) & hash]) != null) {
			// 判断第一个存在的节点的key 和 hash值是否与查询的key的相等，如果是直接返回
			if (first.hash == hash && // always check first node
					((k = first.key) == key || (key != null && key.equals(k))))
				return first;
			// 遍历该链表/红黑树直到next为null
			if ((e = first.next) != null) {
				// 如果该点是红黑树
				if (first instanceof TreeNode)
					// 在树上寻找对应的值
					return ((TreeNode<K,V>)first).getTreeNode(hash, key);
				do {
					// 遍历链表
					if (e.hash == hash &&
							((k = e.key) == key || (key != null && key.equals(k))))
						return e;
				} while ((e = e.next) != null);
			}
		}
		//否则不存在，返回null
		return null;
	}
```

# remove 及其相关方法
```java
	public V remove(Object key) {
		Node<K,V> e;
		return (e = removeNode(hash(key), key, null, false, true)) == null ?
				null : e.value;
	}
```
# removeNode 删除节点
```java
	/**
	 * Implements Map.remove and related methods
	 *
	 * @param hash key的hash值
	 * @param key the key
	 * @param value 传入匹配的value值，如果matchValue=false，直接忽略
	 * @param matchValue 为true时，会去进一步匹配value
	 * @param movable if false do not move other nodes while removing
	 * @return the node, or null if none
	 */
	final Node<K,V> removeNode(int hash, Object key, Object value,
							   boolean matchValue, boolean movable) {
		Node<K,V>[] tab; Node<K,V> p; int n, index;
		//确定table已经被初始化，并且其中有元素，并且对应的 hash值有元素
		if ((tab = table) != null && (n = tab.length) > 0 &&
				(p = tab[index = (n - 1) & hash]) != null) {
			Node<K,V> node = null, e; K k; V v;
			//判断当前这个找到的元素是不是目标元素，如果是的话赋值给node
			if (p.hash == hash &&
					((k = p.key) == key || (key != null && key.equals(k))))
				node = p;
			//不是的话，就从相同hash值的所有元素中去查找
			else if ((e = p.next) != null) {
				if (p instanceof TreeNode)
					//该列表已经转换成红黑树的情况
					node = ((TreeNode<K,V>)p).getTreeNode(hash, key);
				else {
					//在链表中查找的情况
					do {
						if (e.hash == hash &&
								((k = e.key) == key ||
										(key != null && key.equals(k)))) {
							node = e;
							break;
						}
						p = e;
					} while ((e = e.next) != null);
				}
			}
			//找到了目标节点
			if (node != null && (!matchValue || (v = node.value) == value ||
					(value != null && value.equals(v)))) {
				if (node instanceof TreeNode)
					//是红黑树节点的情况
					((TreeNode<K,V>)node).removeTreeNode(this, tab, movable);
				else if (node == p)
					//是一个链表开头元素的情况
					tab[index] = node.next;
				else
					//是一个链表中间元素的情况
					p.next = node.next;
				//结构改变，修改次数需要加一
				++modCount;
				//元素减少size减1
				--size;
				afterNodeRemoval(node);
				return node;
			}
		}
		return null;
	}
```
# removeTreeNode 红黑树中删除节点
```java
		final void removeTreeNode(HashMap<K,V> map, Node<K,V>[] tab,
								  boolean movable) {
			int n;
			// 如果 table为空 或者为0 则无法删除，返回
			if (tab == null || (n = tab.length) == 0)
				return;
			int index = (n - 1) & hash;
			// first 和 root 目前都为 根结点
			TreeNode<K,V> first = (TreeNode<K,V>)tab[index], root = first, rl;
			// succ 是要删除节点的下一个，prev是要删除节点的前一个
			TreeNode<K,V> succ = (TreeNode<K,V>)next, pred = prev;
			// 首先先从TreeNode链表里将这个节点删除掉。
			if (pred == null)
				tab[index] = first = succ;
			else
				pred.next = succ;
			if (succ != null)
				succ.prev = pred;
			if (first == null)
				return;
			if (root.parent != null)
				root = root.root();
			// 根结点为空 或 根节点的右儿子为空 或 根结点的做儿子为空 或 根节点的做儿子的做儿子为空
			if (root == null || root.right == null ||
					(rl = root.left) == null || rl.left == null) {
				// 树太小了，从红黑树转换为链表
				tab[index] = first.untreeify(map);  // too small
				return;
			}
			// 从红黑树删除这个节点
			// p是要删除的节点 pl 是 p 的左节点, pr 是 P 的右节点。
			TreeNode<K,V> p = this, pl = left, pr = right, replacement;
			// 当 p 的左右节点都不为null
			if (pl != null && pr != null) {
				// s 是 p的右节点 的 左叶子节点 的左节点。。。循环找到叶子节点
				// 就是查找所有比当前节点大的节点当中最小的一个节点
				TreeNode<K,V> s = pr, sl;
				while ((sl = s.left) != null) // find successor
					s = sl;
				//交换 s 和 p 节点的颜色
				boolean c = s.red; s.red = p.red; p.red = c; // swap colors
				// sr ：s的右节点
				TreeNode<K,V> sr = s.right;
				// pp ：p的父节点
				TreeNode<K,V> pp = p.parent;
				//2： 如果s 等于pr 证明 p的 右节点 没有 左节点
				if (s == pr) { // p was s's direct parent
					//当前节点的父节点设为找到的节点
					p.parent = s;
					//找到节点的右孩子设为当前节点
					s.right = p;
				}
				//3： p 的右节点有左儿子
				// （以下操作就是将s和p对换了个位置和颜色，
				// 如果s有右儿子则设置为平衡点，否则p为平衡点）
				else {
					// sp ： s的父亲
					TreeNode<K,V> sp = s.parent;
					// 将 p 的父亲设为 sp
					// 如果sp 不为null
					if ((p.parent = sp) != null) {
						// 当前节点替代 s 节点的位置，与 s 节点的父节点进行关联
						// s 是 sp 的左儿子，左儿子设置为 p
						if (s == sp.left)
							sp.left = p;
						else// s 是 sp 的右儿子，右儿子设置为 p
							sp.right = p;
					}
					// s 的右节点设置为 p 的右孩子
					// 如果 p 的右孩子不为null
					// 右孩子的父节点设为 s 节点
					if ((s.right = pr) != null)
						pr.parent = s;
				}
				//当前节点的左孩子设为null
				p.left = null;
				//将 p 节点的右孩子设置为 s节点的右孩子
				if ((p.right = sr) != null)
					sr.parent = p; //右孩子的父节点设为当前节点
				// 将 s 节点的左儿子设置为 p节点的左儿子
				if ((s.left = pl) != null)
					pl.parent = s;// 左孩子的父节点设为找到节点
				// 将s的父亲 设置为 p 节点的父亲
				// 如果 p是根结点，那么根节点变为s
				if ((s.parent = pp) == null)
					root = s;
				// 父节点不为null，当前节点是父节点的左孩子
				else if (p == pp.left)
					// 父亲的左儿子改为s
					pp.left = s;
				else
					// 父亲的右儿子改为s
					pp.right = s;
				// s节点的右孩子不为null
				if (sr != null)
					// 则s节点的右孩子节点作为平衡删除的初始节点
					replacement = sr;
				else
					// 否则平衡删除的初始节点为 p。
					replacement = p;
			}
			//当前节点左孩子不为null，右孩子为null
			//当前节点的左孩子作为平衡删除的节点
			else if (pl != null)
				replacement = pl;
			//当前节点右孩子不为null，左孩子为null
			// 当前节点的右孩子作为平衡删除的节点
			else if (pr != null)
				replacement = pr;
			else//左右孩子都为null，当前节点作为平衡删除的节点
				replacement = p;
			//如果当前节点不是作为平衡删除的节点
			if (replacement != p) {
				//此时p.parent有三种情况，1.其原来的父节点，2.它的右子节点，3.s节点的父节点sp
				//将当前节点的父节点设为平衡删除节点的父节点
				TreeNode<K,V> pp = replacement.parent = p.parent;
				//如果当前节点的父节点为null，则表明当前节点原来是根节点，此时当前节点的父节点还是其原来的父节点
				if (pp == null)
					root = replacement;//设置作为平衡删除的节点为根节点
				// 如果父节点不为null，并且当前节点是父节点的左子节点
				else if (p == pp.left)//设置父节点的左子节点为作为平衡删除的节点
					pp.left = replacement;
				else//设置父节点的右子节点为作为平衡删除的节点
					pp.right = replacement;
				//将当前节点与树结构断开，因为当前节点不是作为平衡删除的节点
				p.left = p.right = p.parent = null;
			}
			// 获取根节点，如果删除节点是红色，则不需要做平衡删除，根节点不会再变
			// 如果删除节点是黑色，则需要做平衡删除，根节点可能会发生改变
			TreeNode<K,V> r = p.red ? root : balanceDeletion(root, replacement);

			//做平衡删除的节点是当前要删除的节点
			//平衡删除做完后将该节点从树结构中脱离出来
			if (replacement == p) {  // detach
				TreeNode<K,V> pp = p.parent;
				p.parent = null;
				if (pp != null) {
					if (p == pp.left)
						pp.left = null;
					else if (p == pp.right)
						pp.right = null;
				}
			}
			//是否需要从新设置桶的头节点
			if (movable)
				//将桶的头节点设为根节点
				moveRootToFront(tab, r);
		}
```
# balanceDeletion 红黑树删除平衡
```java
		/**
		 * 红黑树平衡删除，只有在删除的节点是黑色时才会调用此方法
		 * @param root 根结点
		 * @param x 平衡节点
		 * @return
		 */
		static <K,V> TreeNode<K,V> balanceDeletion(TreeNode<K,V> root,
												   TreeNode<K,V> x) {
			for (TreeNode<K,V> xp, xpl, xpr;;)  {
				//平衡节点为null或者平衡节点是根节点，无需做平衡处理，返回根节点
				if (x == null || x == root)
					return root;
				//平衡节点不是根，但平衡节点的父节点是null
				//则将平衡节点将成为根节点，将其颜色设置为黑色
				else if ((xp = x.parent) == null) {
					x.red = false;
					return x;
				}
				//不是根节点，父节点也不为null，
				//若做平衡的节点就是要删除的节点，则设什么颜色都无所谓，直接返回根节点
				//若做平衡的节点不是要删除的节点，而且还是红色
				//则其要替换的节点就是其父节点，替换的父节点就是要删除的节点，
				//而做平衡的节点还是红色，则其父一定是黑色，其替换其父所以要变成黑色
				//因为做平衡的节点是红，它替换掉了其父（在进入此方法之前已经替换掉了）
				//其父是黑，所以只需要确保其是黑，就能确保该树枝上的黑色节点数不变
				//替换完直接返回根节点即可
				else if (x.red) {
					x.red = false;
					return root;
				}
				//x的节点不是根，父也不为null，其颜色是黑色
				//x的节点是其父的左子节点
				else if ((xpl = xp.left) == x) {
					//如果它有红色的兄弟节点xpr，那么它的父亲节点xp一定是黑色节点
					// 将兄弟节点设为黑色，父亲节点设为红色，以父节点进行旋转
					if ((xpr = xp.right) != null && xpr.red) {
						xpr.red = false;
						xp.red = true;
						//对父节点xp做左旋转
						root = rotateLeft(root, xp);
						//重新将xp指向x的父节点，xpr指向xp新的右孩子
						xpr = (xp = x.parent) == null ? null : xp.right;
					}
					//如果xpr为空，则向上继续调整，将x的父节点xp作为新的x继续循环
					if (xpr == null)
						x = xp;
					else {
						//sl和sr分别为其兄弟节点左儿子和右儿子
						TreeNode<K,V> sl = xpr.left, sr = xpr.right;
						//若sl和sr都为黑色或者不存在，即xpr没有红色孩子，则将xpr染红
						if ((sr == null || !sr.red) &&
								(sl == null || !sl.red)) {
							xpr.red = true;
							x = xp;//本轮结束，继续向上循环
						}
						else {
							//否则的话，就需要进一步调整
							if (sr == null || !sr.red) {
								//若左孩子为红，右孩子不存在或为黑
								if (sl != null)
									//左孩子染黑
									sl.red = false;
								//将xpr染红
								xpr.red = true;
								//右旋
								root = rotateRight(root, xpr);
								//右旋后，xpr指向xp的新右孩子，即上一步中的sl
								xpr = (xp = x.parent) == null ?
										null : xp.right;
							}
							// 如果兄弟节点 不为null
							if (xpr != null) {
								// 如果父节点为空，兄弟节点染为黑色，否则和父亲节点染色相同
								xpr.red = (xp == null) ? false : xp.red;
								// sr 设置为兄弟节点的右孩子，如果sr不为null，将sr设置为黑色，防止出现两个红色相连
								if ((sr = xpr.right) != null)
									sr.red = false;
							}
							// 如果父节点不为null
							if (xp != null) {
								//将父亲节点设置为黑色
								xp.red = false;
								// 左旋父节点
								root = rotateLeft(root, xp);
							}
							x = root;
						}
					}
				}
				//x为其父节点的右孩子，跟上面操作镜像
				else { // symmetric
					if (xpl != null && xpl.red) {
						xpl.red = false;
						xp.red = true;
						root = rotateRight(root, xp);
						xpl = (xp = x.parent) == null ? null : xp.left;
					}
					if (xpl == null)
						x = xp;
					else {
						TreeNode<K,V> sl = xpl.left, sr = xpl.right;
						if ((sl == null || !sl.red) &&
								(sr == null || !sr.red)) {
							xpl.red = true;
							x = xp;
						}
						else {
							if (sl == null || !sl.red) {
								if (sr != null)
									sr.red = false;
								xpl.red = true;
								root = rotateLeft(root, xpl);
								xpl = (xp = x.parent) == null ?
										null : xp.left;
							}
							if (xpl != null) {
								xpl.red = (xp == null) ? false : xp.red;
								if ((sl = xpl.left) != null)
									sl.red = false;
							}
							if (xp != null) {
								xp.red = false;
								root = rotateRight(root, xp);
							}
							x = root;
						}
					}
				}
			}
		}
```

# rotateLeft 红黑树左旋（右旋转同理）
```java
		/**
		 * 红黑树左旋
		 * @param root 根节点
		 * @param p 要左旋的节点
		 *
		 * @return
		 */
		static <K,V> TreeNode<K,V> rotateLeft(TreeNode<K,V> root,
											  TreeNode<K,V> p) {
			// pp : p的父亲
			// r: p的右孩子
			// rl = p 的右孩子的左孩子 -> r的左孩子
			TreeNode<K,V> r, pp, rl;
			// 要 p 以及 p的右孩子 不为null
			if (p != null && (r = p.right) != null) {
				// 将p 的右孩子 设置为 rl 并且 rl不为空
				if ((rl = p.right = r.left) != null)
					// rl的父亲节点设置为p
					rl.parent = p;
				// 将 r 的父亲 设置为 p的父亲（此时r 与p为兄弟）
				// 如果父亲节点为null，则此时 r为跟节点
				// 将root 设置为r ，并设置为黑色
				if ((pp = r.parent = p.parent) == null)
					(root = r).red = false;
				// 如果父节点的左儿子是 p
				else if (pp.left == p)
					// 将父节点的 左儿子 设为r
					pp.left = r;
				else
					// 否则将 右儿子 设为r
					pp.right = r;
				// 将 r 的左节儿子 设置为p
				r.left = p;
				// p 的父亲设置为 r
				p.parent = r;
			}
			// 返回根节点
			return root;
		}
```
