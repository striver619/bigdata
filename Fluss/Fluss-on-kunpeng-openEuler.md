# Fluss on 鲲鹏 openEuler 大数据实战

基于鲲鹏欧拉操作系统，构建 HDFS、ZK、FLINK、FLUSS、PAIMON 实时数据环境

## 0. 参考文档

- Deploying Flink Distributed Cluster：
https://nightlies.apache.org/flink/flink-docs-release-1.20/zh/docs/try-flink/local_installation/

- Deploying Fluss Distributed Cluster：
https://fluss.apache.org/docs/install-deploy/deploying-distributed-cluster/

- Fluss Secure & Authentication：
https://fluss.apache.org/docs/quickstart/security/
https://fluss.apache.org/docs/security/authentication/

- 使用案例：
https://fluss.apache.org/docs/engine-flink/getting-started/

## 1. 机器准备

- 机器数量：6 台
- 机器型号：华为泰山鲲鹏920 ARMV8
- 机器配置：8 CPU核、16G 内存、500G（SSD 系统盘）+ 2T（SAS 数据盘）
- 操作系统：openEuler release 20.03 (LTS-SP1)
- 内核版本：Linux 4.19.90-2012.4.0.0053.oe1.aarch64

## 2. 组件版本及下载地址：

- 注意组件依赖关系：
  - ZooKeeper、Hadoop 依赖 JDK 8

  - Flink、Fluss 依赖 JDK 17

  - Paimon 是插件直接添加到 Flink 的 lib 目录下

- JDK 8：
  - 官方下载：https://www.oracle.com/java/technologies/javase/javase8u211-later-archive-downloads.html
   - 因为使用 arm64 服务器，所以下载 aarch64 版本：jdk-8u441-linux-aarch64.tar.gz；如果是 x86 服务器，则下载 x86_64 版本

- ZooKeeper 3.8.4：
  - 官方下载：https://www.apache.org/dyn/closer.lua/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz
  - 国内下载：https://mirrors.bfsu.edu.cn/apache/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz

- Hadoop 3.4.1：
  - 官方下载：https://www.apache.org/dyn/closer.cgi/hadoop/common/hadoop-3.4.1/hadoop-3.4.1.tar.gz
  - 国内下载：https://mirrors.bfsu.edu.cn/apache/hadoop/common/hadoop-3.4.1/hadoop-3.4.1.tar.gz

- JDK 17：
  - 官方下载：https://www.oracle.com/java/technologies/javase/jdk17-0-13-later-archive-downloads.html
  - 因为使用 arm64 服务器，所以下载 aarch64 版本：jdk-17.0.14_linux-aarch64_bin.tar.gz；如果是 x86 服务器，则下载 x86_64 版本

- Flink 1.20.1：
  - 官方下载：https://www.apache.org/dyn/closer.lua/flink/flink-1.20.1/flink-1.20.1-bin-scala_2.12.tgz
  - 国内下载：https://mirrors.bfsu.edu.cn/apache/flink/flink-1.20.1/flink-1.20.1-bin-scala_2.12.tgz

- Fluss 0.7.0：
  - 阿里下载：https://alibaba.github.io/fluss-docs/downloads/
  - Github：https://github.com/alibaba/fluss/releases/download/v0.7.0/fluss-0.7.0-bin.tgz
  - 官方下载：https://fluss.apache.org/downloads/
  - Github：https://github.com/alibaba/fluss/releases/download/v0.7.0/fluss-0.7.0-bin.tgz

- Fluss Connector：
  - fluss-flink：https://repo1.maven.org/maven2/com/alibaba/fluss/fluss-flink-1.20/0.7.0/fluss-flink-1.20-0.7.0.jar
  - fluss-fs-hadoop：https://repo1.maven.org/maven2/com/alibaba/fluss/fluss-fs-hadoop/0.7.0/fluss-fs-hadoop-0.7.0.jar
  - fluss-flink-tiering：https://repo1.maven.org/maven2/com/alibaba/fluss/fluss-flink-tiering/0.7.0/fluss-flink-tiering-0.7.0.jar
  - fluss-lake-paimon：https://repo1.maven.org/maven2/com/alibaba/fluss/fluss-lake-paimon/0.7.0/fluss-lake-paimon-0.7.0.jar

- Paimon 1.1.0：
  - 官网下载（需源码编译）：https://paimon.apache.org/downloads
  - Maven 中央仓库下载：https://repo1.maven.org/maven2/org/apache/paimon/paimon-flink-1.20/1.1.0/paimon-flink-1.20-1.1.0.jar


## 3. IP、主机名映射（6台一样）

- 配置主机名（root 用户操作）
  如果没配置主机名，请手动设置（以 node146 为例，其他机器同理）

```
hostnamectl set-hostname node146;bash
```

- 配置 IP、主机名映射

```
vim /etc/hosts
```

```
10.107.160.146    node146
10.107.160.147    node147
10.107.160.148    node148
10.107.160.81    node81
10.107.160.82    node82
10.107.160.83    node83
```

## 4. 用户创建（6 台一样）

- root 用户 创建新用户

```
useradd qcdata
echo "Hw12#$_34"|passwd --stdin qcdata
echo "qcdata  ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
```

## 5. 配置免密登录（以 node146 为例，免密集群 6 台机器）

- 生成 ssh public key

```
su - qcdata
ssh-keygen -t rsa
mkdir ~/bin
```

- 安装 expect、tcl-devel

```
yum install expect tcl-devel -y
```

- 自动发送 ssh public key

```
vim ~/bin/auto_send_pubkey.sh
```

```
#!/usr/bin/expect

set timeout 10  
set username [lindex $argv 0]  
set password [lindex $argv 1]  
set hostname [lindex $argv 2]  

spawn ssh-copy-id -i ~/.ssh/id_rsa.pub $username@$hostname

expect {
            "Are you sure you want to continue connecting (yes/no)?" {
            send "yes\r"
            expect "password:"
                send "$password\r"
            }
            "password:" {
                send "$password\r"
            }
            "Now try logging into the machine" {
                #it has authorized, do nothing!
            }
        }
expect eof
```

- 编写批量配置免密脚本

```
vim ~/bin/auto_nopasswd_all.sh
```

```
#!/bin/bash

hosts=(
node14{6..8}
node8{1..3}
)

for host in ${hosts[@]}
do
    sh ~/bin/auto_send_pubkey.sh qcdata "Hw12#$_34" $host
    echo ""
done
```

- 执行批量免密脚本

```
sh auto_nopasswd_all.sh
```

## 6. 常用工具脚本

- 6.1 批量控制远程脚本（批量执行每一台机器相同命令）

```
vim ~/bin/xcall
```

```
#!/bin/bash

hosts=(
node14{6..8}
node8{1..3}
)

for host in ${hosts[@]}
do
    echo "-------- $host --------"
    ssh $host "$*"
    echo ""
done
```

- 添加可执行权限

```
chmod +x ~/bin/xcall
```

- 测试 xcall 脚本是否可用（顺便为下一个脚本做准备）

```
xcall "yum install rsync -y"
```

- 6.2 批量同步文件及目录脚本

```
vim ~/bin/xsync
```

```
#!/bin/bash

hosts=(
node14{6..8}
node8{1..3}
)

if [ $# -lt 1 ]
then
  echo Not Enough Arguement!
  exit;
fi

for host in ${hosts[@]}
do
  echo ====================  $host  ====================
  for file in $@
  do
    if [ -e $file ]
    then
      pdir=$(cd -P $(dirname $file); pwd)
      fname=$(basename $file)
      ssh $host "mkdir -p $pdir"
      rsync -av $pdir/$fname $host:$pdir
    else
      echo $file does not exists!
    fi
  done
done
```

- 添加可执行权限

```
chmod +x ~/bin/xsync
```

- 用法示例：

```
xsync /etc/hosts
```

- 6.3 批量查看集群各节点进程脚本

```
cat ~/bin/jpsall
```

```
#!/bin/bash

xcall "jps|grep -v 'Jps'"
```

- 添加可执行权限

```
chmod +x ~/bin/jpsall
```

- 脚本用法

```
jpsall
```

## 7. 集群机器全关全禁防火墙和SELINUX

- 关禁防火墙

```
systemctl stop firewalld
systemctl disable firewalld
```

- 关禁 SELINUX

```
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
```

## 8. 上传软件安装包

- 先创建软件包存放、软件安装目录

```
mkdir /data/{software,module}
```

- 上传软件安装包到目录 /data/software

## 9. 集群规划

node146    zk, hdfs(nn,dn), flink(jobmanager,taskmanager), fluss(coordinator-server)
node147    zk, hdfs(dn), flink(taskmanager), fluss(tablet-server)
node148    zk, hdfs(sn,dn), flink(taskmanager), fluss(tablet-server)
node81     flink(taskmanager), fluss(tablet-server)
node82     flink(taskmanager), fluss(tablet-server)
node83     flink(taskmanager), fluss(tablet-server)

## 10. 安装 JDK 8

- 解压安装包

```
cd /data1/software/
tar -zxf jdk-8u441-linux-aarch64.tar.gz -C /data1/module/
ls -l /data1/module/jdk1.8.0_441
```

- 追加配置到当前用户环境变量文件

```
vim ~/.bashrc
```

```
export JAVA_HOME=/data1/module/jdk1.8.0_441
export PATH=$PATH:$JAVA_HOME/bin
```

- 同步 JDK 8 安装目录及环境变量文件到集群其他节点

```
xsync /data1/module/jdk1.8.0_441
xsync ~/.bashrc
```

- 批量生效环境变量

```
xcall "source ~/.bashrc"
```

- 批量验证环境变量

```
xcall "java -version"
```

## 11. 安装部署 ZooKeeper 3.8.4 集群

- 解压软件安装包

```
cd /data1/software/
tar -zxf apache-zookeeper-3.8.4-bin.tar.gz -C /data1/module
```

- 重命名软件安装目录名

```
cd /data1/module/
mv apache-zookeeper-3.8.4-bin zookeeper-3.8.4
```

- 创建数据和日志目录

```
cd zookeeper-3.8.4
mkdir {data,logs}
```

- 追加配置环境变量

```
vim ~/.bashrc
```

```
export ZOOKEEPER_HOME=/data1/module/zookeeper-3.8.4
export PATH=$PATH:$ZOOKEEPER_HOME/bin
```

- 配置 zoo.cfg 文件

```
vim conf/zoo.cfg
```

```
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/data1/module/zookeeper-3.8.4/data
dataLogDir=/data1/module/zookeeper-3.8.4/logs
clientPort=2181
server.0=node146:2888:3888
server.1=node147:2888:3888
server.2=node148:2888:3888
admin.serverPort=18080
```

- 批量同步 zookeeper 软件安装目录及环境变量文件

```
xsync /data1/module/zookeeper-3.8.4
xsync ~/.bashrc
```

- 批量生效环境变量

```
xcall "source ~/.bashrc"
```

- 配置 集群各节点 ID

```
ssh node146 "echo '0' > /data1/module/zookeeper-3.8.4/data/myid"
ssh node147 "echo '1' > /data1/module/zookeeper-3.8.4/data/myid"
ssh node148 "echo '2' > /data1/module/zookeeper-3.8.4/data/myid"
```

- 编写 zookeeper 集群 批量启停脚本

```
vim ~/bin/zk.sh
```

```
#!/bin/bash

hosts=(
node14{6..8}
)

case $1 in

"start"){
    echo "-------- ZOOKEEPER CLUSTER START --------"
    echo ""
    for host in ${hosts[@]}
    do
        echo "---- zk $host start ----"
        ssh $host "/data1/module/zookeeper-3.8.4/bin/zkServer.sh start"
        echo ""
    done
};;

"stop"){
    echo "-------- ZOOKEEPER CLUSTER STOP --------"
    echo ""
    for host in ${hosts[@]}
    do
        echo "---- zk $host stop ----"
        ssh $host "/data1/module/zookeeper-3.8.4/bin/zkServer.sh stop"
        echo ""
    done
};;

"status"){
    echo "-------- ZOOKEEPER CLUSTER STATUS --------"
    echo ""
    for host in ${hosts[@]}
    do
        echo "---- zk $host status ----"
        ssh $host "/data1/module/zookeeper-3.8.4/bin/zkServer.sh status"
        echo ""
    done
};;

esac
```

- 添加可执行权限

```
chmod +x ~/bin/zk.sh
```

- 启动 zookeeper 集群，并查看进程状态

```
zk.sh start
jpsall
```

- 查看 zookeeper 集群状态

```
zk.sh status
```

- 停止 zookeeper 集群，并查看进程状态

```
zk.sh stop
jpsall
```

## 12. 安装部署 Hadoop 3.4.1 的 HDFS 集群

由于 FLINK 和 FLUSS 需要用到 HDFS，所以只部署 HDFS 集群

- 解压安装包

```
cd /data1/software/
tar -zxf hadoop-3.4.1.tar.gz -C /data1/module/
```

- 进入 hdfs 配置文件目录

```
cd /data1/module/hadoop-3.4.1/etc/hadoop/
```

- 配置 workers 集群节点文件

```
vim workers
```

```
node146
node147
node148
```

- 创建 hdfs 临时文件目录

```
mkdir /data1/module/hadoop-3.4.1/nndndata
```

- 配置 core-site.xml 文件

```
vim core-site.xml
```

```
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>

  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://node146:8020</value>
  </property>

  <property>
    <name>hadoop.tmp.dir</name>
    <value>/data1/module/hadoop-3.4.1/nndndata</value>
  </property>

  <property>
    <name>hadoop.native.lib</name>
    <value>false</value>
  </property>

</configuration>
```

- 配置 hdfs-site.xml 文件

```
vim hdfs-site.xml
```

```
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>

<configuration>

  <property>
    <name>dfs.namenode.rpc-address</name>
    <value>node146:8020</value>
  </property>

  <property>
    <name>dfs.namenode.http-address</name>
    <value>node146:0</value>
  </property>

  <property>
    <name>dfs.namenode.secondary.http-address</name>
    <value>node148:0</value>
  </property>

  <property>
    <name>dfs.replication</name>
    <value>3</value>
  </property>

</configuration>
```

- 配置 hadoop-env.sh 文件

```
vim hadoop-env.sh
```

```
export JAVA_HOME=/data1/module/jdk1.8.0_441
```

- 同步 hadoop 安装目录都集群其他节点

```
xsync /data1/module/hadoop-3.4.1
```

- 追加配置环境变量

```
vim ~/.bashrc
```

```
export HADOOP_HOME=/data1/module/hadoop-3.4.1
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HADOOP_HOME/lib/native
export HADOOP_CLASSPATH=`hadoop classpath`
```

- 同步环境变量文件

```
xsync ~/.bashrc
```

- 批量生效集群环境变量

```
xcall "source ~/.bashrc"
```

- 验证 hadoop 环境变量是否配好

```
xcall "hadoop version"
```

- 在 node146 节点格式化 namenode

```
cd /data1/module/hadoop-3.4.1/bin
hdfs namenode -format
```

- 批量干掉 hdfs warn 级别日志

```
xcall "echo 'export HADOOP_ROOT_LOGGER=ERROR,console' >> /data1/module/hadoop-3.4.1/etc/hadoop/hadoop-env.sh"
```

- 编写 hdfs 集群批量启停脚本

```
vim ~/bin/hdfs.sh
```

```
#!/bin/bash

case $1 in

"start"){
    echo "---- HADOOP HDFS CLUSTER START ----"
    ssh node146 "/data1/module/hadoop-3.4.1/sbin/start-dfs.sh"
    echo ""
};;

"stop"){
    echo "---- HADOOP HDFS CLUSTER STOP ----"
    ssh node146 "/data1/module/hadoop-3.4.1/sbin/stop-dfs.sh"
    echo ""
};;

esac
```

- 添加可执行权限

```
chmod +x ~/bin/hdfs.sh
```

- 启动 hdfs 集群，并查看进程状态

```
hdfs.sh start
jpsall
```

- 停止 hdfs 集群，并查看进程状态

```
hdfs.sh stop
jpsall
```

## 13. 安装 JDK 17

主要给 FLINK 和 FLUSS 使用

- 解压安装包

```
cd /data1/software/
tar -zxf jdk-17.0.14_linux-aarch64_bin.tar.gz -C /data1/module
```

- 同步分发安装目录

```
xsync /data1/module/jdk-17.0.14
```

- 追加环境变量 链接快捷方式

```
xcall "echo 'alias java17=/data1/module/jdk-17.0.14/bin/java' >> ~/.bashrc"
```

- 批量生效环境变量

```
xcall "source ~/.bashrc"
```

- 批量查看 JDK 17 版本

```
xcall "java17 -version"
```

## 14. 安装部署 Flink 1.20.1 集群

- 解压安装包

```
cd /data1/software/
tar -zxf flink-1.20.1-bin-scala_2.12.tgz -C /data1/module
ls -l /data1/module/flink-1.20.1/
```

- 拷贝相关依赖 jar 包 到 flink 的 lib 目录下

```
vim flink-deps-jars.sh
```

```
#!/bin/bash
JARS=(
fluss-flink-1.20-0.7.0.jar
fluss-fs-hadoop-0.7.0.jar
paimon-flink-1.20-1.1-20250410.002752-111.jar
fluss-lake-paimon-0.7.0.jar
fluss-flink-tiering-0.7.0.jar
)

for jar in ${JARS[@]}
do
    cp -v /data1/software/$jar /data1/module/flink-1.20.1/lib/
done
```

- 执行脚本

```
sh flink-deps-jars.sh
```

- 配置 flink 的 config 配置文件

```
cd /data1/module/flink-1.20.1/conf
```

- 一次性编写好集群 6 个节点的配置文件（后面会用到，很香）

```
vim config-node146.yaml
```

```
env:
  java:
    home: /data1/module/jdk-17.0.14
    opts:
      all: --add-exports=java.base/sun.net.util=ALL-UNNAMED --add-exports=java.rmi/sun.rmi.registry=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED --add-exports=java.security.jgss/sun.security.krb5=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.base/java.time=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.locks=ALL-UNNAMED

jobmanager:
  bind-host: 0.0.0.0
  rpc:
    address: node146
    port: 6123
  memory:
    flink:
      size: 10240m
  execution:
    failover-strategy: region

taskmanager:
  bind-host: 0.0.0.0
  host: node146
  numberOfTaskSlots: 6
  memory:
    flink:
      size: 10240m
    framework:
      heap:
        size: 2048m
      off-heap:
        size: 2048m
        batch-shuffle:
          size: 1024m
    task:
      heap:
        size: 2048m
      off-heap:
        size: 2048m
        batch-shuffle:
          size: 1024m
    managed:
      size: 1024m
    network:
      size: 1024m

parallelism:
  default: 4

state:
  backend:
    type: rocksdb
    incremental: false
  checkpoints:
      dir: hdfs://node146:8020/flink-checkpoints
  savepoints:
      dir: hdfs://node146:8020/flink-savepoints

rest:
  address: node146
  bind-address: 0.0.0.0
  port: 8888
```

---

```
vim config-node147.yaml
```

```
env:
  java:
    home: /data1/module/jdk-17.0.14
    opts:
      all: --add-exports=java.base/sun.net.util=ALL-UNNAMED --add-exports=java.rmi/sun.rmi.registry=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED --add-exports=java.security.jgss/sun.security.krb5=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.base/java.time=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.locks=ALL-UNNAMED

jobmanager:
  bind-host: 0.0.0.0
  rpc:
    address: node146
    port: 6123
  memory:
    flink:
      size: 10240m
  execution:
    failover-strategy: region

taskmanager:
  bind-host: 0.0.0.0
  host: node147
  numberOfTaskSlots: 6
  memory:
    flink:
      size: 10240m
    framework:
      heap:
        size: 2048m
      off-heap:
        size: 2048m
        batch-shuffle:
          size: 1024m
    task:
      heap:
        size: 2048m
      off-heap:
        size: 2048m
        batch-shuffle:
          size: 1024m
    managed:
      size: 1024m
    network:
      size: 1024m

parallelism:
  default: 4

state:
  backend:
    type: rocksdb
    incremental: false
  checkpoints:
      dir: hdfs://node146:8020/flink-checkpoints
  savepoints:
      dir: hdfs://node146:8020/flink-savepoints

rest:
  address: node146
  bind-address: 0.0.0.0
  port: 8888
```

---

```
vim config-node148.yaml
```

```
env:
  java:
    home: /data1/module/jdk-17.0.14
    opts:
      all: --add-exports=java.base/sun.net.util=ALL-UNNAMED --add-exports=java.rmi/sun.rmi.registry=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED --add-exports=java.security.jgss/sun.security.krb5=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.base/java.time=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.locks=ALL-UNNAMED

jobmanager:
  bind-host: 0.0.0.0
  rpc:
    address: node146
    port: 6123
  memory:
    flink:
      size: 10240m
  execution:
    failover-strategy: region

taskmanager:
  bind-host: 0.0.0.0
  host: node148
  numberOfTaskSlots: 6
  memory:
    flink:
      size: 10240m
    framework:
      heap:
        size: 2048m
      off-heap:
        size: 2048m
        batch-shuffle:
          size: 1024m
    task:
      heap:
        size: 2048m
      off-heap:
        size: 2048m
        batch-shuffle:
          size: 1024m
    managed:
      size: 1024m
    network:
      size: 1024m

parallelism:
  default: 4

state:
  backend:
    type: rocksdb
    incremental: false
  checkpoints:
      dir: hdfs://node146:8020/flink-checkpoints
  savepoints:
      dir: hdfs://node146:8020/flink-savepoints

rest:
  address: node146
  bind-address: 0.0.0.0
  port: 8888
```

---

```
vim config-node81.yaml
```

```
env:
  java:
    home: /data1/module/jdk-17.0.14
    opts:
      all: --add-exports=java.base/sun.net.util=ALL-UNNAMED --add-exports=java.rmi/sun.rmi.registry=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED --add-exports=java.security.jgss/sun.security.krb5=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.base/java.time=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.locks=ALL-UNNAMED

jobmanager:
  bind-host: 0.0.0.0
  rpc:
    address: node146
    port: 6123
  memory:
    flink:
      size: 10240m

  execution:
    failover-strategy: region

taskmanager:
  bind-host: 0.0.0.0
  host: node81
  numberOfTaskSlots: 6
  memory:
    flink:
      size: 10240m
    framework:
      heap:
        size: 2048m
      off-heap:
        size: 2048m
        batch-shuffle:
          size: 1024m
    task:
      heap:
        size: 2048m
      off-heap:
        size: 2048m
        batch-shuffle:
          size: 1024m
    managed:
      size: 1024m
    network:
      size: 1024m

parallelism:
  default: 4

state:
  backend:
    type: rocksdb
    incremental: false
  checkpoints:
      dir: hdfs://node146:8020/flink-checkpoints
  savepoints:
      dir: hdfs://node146:8020/flink-savepoints

rest:
  address: node146
  bind-address: 0.0.0.0
  port: 8888
```

---

```
vim config-node82.yaml
```

```
env:
  java:
    home: /data1/module/jdk-17.0.14
    opts:
      all: --add-exports=java.base/sun.net.util=ALL-UNNAMED --add-exports=java.rmi/sun.rmi.registry=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED --add-exports=java.security.jgss/sun.security.krb5=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.base/java.time=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.locks=ALL-UNNAMED

jobmanager:
  bind-host: 0.0.0.0
  rpc:
    address: node146
    port: 6123
  memory:
    flink:
      size: 10240m
  execution:
    failover-strategy: region

taskmanager:
  bind-host: 0.0.0.0
  host: node82
  numberOfTaskSlots: 6
  memory:
    flink:
      size: 10240m
    framework:
      heap:
        size: 2048m
      off-heap:
        size: 2048m
        batch-shuffle:
          size: 1024m
    task:
      heap:
        size: 2048m
      off-heap:
        size: 2048m
        batch-shuffle:
          size: 1024m
    managed:
      size: 1024m
    network:
      size: 1024m

parallelism:
  default: 4

state:
  backend:
    type: rocksdb
    incremental: false
  checkpoints:
      dir: hdfs://node146:8020/flink-checkpoints
  savepoints:
      dir: hdfs://node146:8020/flink-savepoints

rest:
  address: node146
  bind-address: 0.0.0.0
  port: 8888
```

---

```
vim config-node83.yaml
```

```
env:
  java:
    home: /data1/module/jdk-17.0.14
    opts:
      all: --add-exports=java.base/sun.net.util=ALL-UNNAMED --add-exports=java.rmi/sun.rmi.registry=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED --add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED --add-exports=java.security.jgss/sun.security.krb5=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.net=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.lang.reflect=ALL-UNNAMED --add-opens=java.base/java.text=ALL-UNNAMED --add-opens=java.base/java.time=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.util.concurrent=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.atomic=ALL-UNNAMED --add-opens=java.base/java.util.concurrent.locks=ALL-UNNAMED

jobmanager:
  bind-host: 0.0.0.0
  rpc:
    address: node146
    port: 6123
  memory:
    flink:
      size: 10240m
  execution:
    failover-strategy: region

taskmanager:
  bind-host: 0.0.0.0
  host: node83
  numberOfTaskSlots: 6
  memory:
    flink:
      size: 10240m
    framework:
      heap:
        size: 2048m
      off-heap:
        size: 2048m
        batch-shuffle:
          size: 1024m
    task:
      heap:
        size: 2048m
      off-heap:
        size: 2048m
        batch-shuffle:
          size: 1024m
    managed:
      size: 1024m
    network:
      size: 1024m

parallelism:
  default: 4

state:
  backend:
    type: rocksdb
    incremental: false
  checkpoints:
      dir: hdfs://node146:8020/flink-checkpoints
  savepoints:
      dir: hdfs://node146:8020/flink-savepoints

rest:
  address: node146
  bind-address: 0.0.0.0
  port: 8888
```


- 同步分发 flink 安装目录

```
xsync /data1/module/flink-1.20.1
```

- 统一配置 flink config 脚本

```
vim all-config-yaml.sh
```

```
#!/bin/bash

hosts=(
node14{6..8}
node8{1..3}
)

for host in ${hosts[@]}
do
    echo "-------- $host --------"
    ssh $host "cp -v /data1/module/flink-1.20.1/conf/config-$host.yaml /data1/module/flink-1.20.1/conf/config.yaml"
    echo ""
done
```

- 执行脚本

```
sh all-config-yaml.sh
```

- 追加配置环境变量

```
vim ~/.bashrc
```

```
export FLINK_HOME=/data1/module/flink-1.20.1
export PATH=$PATH:$FLINK_HOME/bin
```

- 同步分发 环境变量配置文件

```
xsync ~/.bashrc
```

- 批量生效环境变量

```
xcall "source ~/.bashrc"
```

- 编写 flink 批量启停脚本

```
vim ~/bin/flink.sh
```

```
#!/bin/bash

case $1 in

"start"){
    echo "-------- FLINK CLUSTER START --------"
    ssh node146 "/data1/module/flink-1.20.1/bin/start-cluster.sh"
    echo ""
};;

"stop"){
    echo "-------- FLINK CLUSTER STOP --------"
    ssh node146 "/data1/module/flink-1.20.1/bin/stop-cluster.sh"
    echo ""
};;

esac
```

- 添加可执行权限

```
chmod +x ~/bin/flink.sh
```

- 启动 flink 集群及查看集群进程

```
flink.sh start
jpsall
```

- 停止 flink 集群及查看集群进程

```
flink.sh stop
jpsall
```

## 15. 安装部署 Fluss 0.7.0 集群

- 解压安装包

```
cd /data1/software/
tar -zxf fluss-0.7.0-bin.tgz -C /data1/module
```

- 拷贝 fluss-flink-tiering-0.7.0.jar 文件到 fluss 的 lib 目录下

```
cp -v /data1/software/fluss-flink-tiering-0.7.0.jar /data1/module/fluss-0.7.0/lib
```

- 创建本地 fluss 临时数据目录

```
mkdir -p /data1/module/fluss-0.7.0/tmp/fluss-data
```

- 创建 hdfs 远程 fluss 数据目录

```
hdfs dfs -mkdir -p /fluss/tmp/fluss-remote-data
```

- 创建本地 paimon 临时数据目录

```
mkdir -p /data1/module/fluss-0.7.0/tmp/paimon_data_warehouse
```

- 批量配置 fluss 的 server 配置文件

```
cd /data1/module/fluss-0.7.0/conf
```

```
vim server-node146.yaml
```

```
env.java.home: /data1/module/jdk-17.0.14
zookeeper.address: node146:2181,node147:2181,node148:2181
zookeeper.path.root: /fluss
default.bucket.number: 1
default.replication.factor: 1
data.dir: /data1/module/fluss-0.7.0/tmp/fluss-data
remote.data.dir: hdfs://node146:8020/fluss/tmp/fluss-remote-data
bind.listeners: CLIENT://node146:9000, INTERNAL://node146:9123
advertised.listeners: CLIENT://{node146's public network IP}:{public network port}
security.protocol.map: CLIENT:SASL, INTERNAL:PLAINTEXT
internal.listener.name: INTERNAL
security.sasl.enabled.mechanisms: PLAIN
security.sasl.plain.jaas.config: com.alibaba.fluss.security.auth.sasl.plain.PlainLoginModule required user_admin="admin-Fluss-NB!." user_fluss="fluss-Fluss-NB!.";
authorizer.enabled: true
super.users: User:admin,User:fluss
tablet-server.id: 0
datalake.format: paimon
datalake.paimon.metastore: filesystem
datalake.paimon.warehouse: /data1/module/fluss-0.7.0/tmp/paimon_data_warehouse
```

---

```
vim server-node147.yaml
```

```
env.java.home: /data1/module/jdk-17.0.14
zookeeper.address: node146:2181,node147:2181,node148:2181
zookeeper.path.root: /fluss
default.bucket.number: 1
default.replication.factor: 1
data.dir: /data1/module/fluss-0.7.0/tmp/fluss-data
remote.data.dir: hdfs://node146:8020/fluss/tmp/fluss-remote-data
bind.listeners: CLIENT://node147:9000, INTERNAL://node147:9123
advertised.listeners: CLIENT://{node147's public network IP}:{public network port}
security.protocol.map: CLIENT:SASL, INTERNAL:PLAINTEXT
internal.listener.name: INTERNAL
security.sasl.enabled.mechanisms: PLAIN
security.sasl.plain.jaas.config: com.alibaba.fluss.security.auth.sasl.plain.PlainLoginModule required user_admin="admin-Fluss-NB!." user_fluss="fluss-Fluss-NB!.";
authorizer.enabled: true
super.users: User:admin,User:fluss
tablet-server.id: 1
datalake.format: paimon
datalake.paimon.metastore: filesystem
datalake.paimon.warehouse: /data1/module/fluss-0.7.0/tmp/paimon_data_warehouse
```

---

```
vim server-node148.yaml
```

```
env.java.home: /data1/module/jdk-17.0.14
zookeeper.address: node146:2181,node147:2181,node148:2181
zookeeper.path.root: /fluss
default.bucket.number: 1
default.replication.factor: 1
data.dir: /data1/module/fluss-0.7.0/tmp/fluss-data
remote.data.dir: hdfs://node146:8020/fluss/tmp/fluss-remote-data
bind.listeners: CLIENT://node148:9000, INTERNAL://node148:9123
advertised.listeners: CLIENT://{node148's public network IP}:{public network port}
security.protocol.map: CLIENT:SASL, INTERNAL:PLAINTEXT
internal.listener.name: INTERNAL
security.sasl.enabled.mechanisms: PLAIN
security.sasl.plain.jaas.config: com.alibaba.fluss.security.auth.sasl.plain.PlainLoginModule required user_admin="admin-Fluss-NB!." user_fluss="fluss-Fluss-NB!.";
authorizer.enabled: true
super.users: User:admin,User:fluss
tablet-server.id: 2
datalake.format: paimon
datalake.paimon.metastore: filesystem
datalake.paimon.warehouse: /data1/module/fluss-0.7.0/tmp/paimon_data_warehouse
```

---

```
vim server-node81.yaml
```

```
env.java.home: /data1/module/jdk-17.0.14
zookeeper.address: node146:2181,node147:2181,node148:2181
zookeeper.path.root: /fluss
default.bucket.number: 1
default.replication.factor: 1
data.dir: /data1/module/fluss-0.7.0/tmp/fluss-data
remote.data.dir: hdfs://node146:8020/fluss/tmp/fluss-remote-data
bind.listeners: CLIENT://node81:6000, INTERNAL://node81:9123
advertised.listeners: CLIENT://{node81's public network IP}:{public network port}
security.protocol.map: CLIENT:SASL, INTERNAL:PLAINTEXT
internal.listener.name: INTERNAL
security.sasl.enabled.mechanisms: PLAIN
security.sasl.plain.jaas.config: com.alibaba.fluss.security.auth.sasl.plain.PlainLoginModule required user_admin="admin-Fluss-NB!." user_fluss="fluss-Fluss-NB!.";
authorizer.enabled: true
super.users: User:admin,User:fluss
tablet-server.id: 3
datalake.format: paimon
datalake.paimon.metastore: filesystem
datalake.paimon.warehouse: /data1/module/fluss-0.7.0/tmp/paimon_data_warehouse
```

---

```
vim server-node82.yaml
```

```
env.java.home: /data1/module/jdk-17.0.14
zookeeper.address: node146:2181,node147:2181,node148:2181
zookeeper.path.root: /fluss
default.bucket.number: 1
default.replication.factor: 1
data.dir: /data1/module/fluss-0.7.0/tmp/fluss-data
remote.data.dir: hdfs://node146:8020/fluss/tmp/fluss-remote-data
bind.listeners: CLIENT://node82:6000, INTERNAL://node82:9123
advertised.listeners: CLIENT://{node82's public network IP}:{public network port}
security.protocol.map: CLIENT:SASL, INTERNAL:PLAINTEXT
internal.listener.name: INTERNAL
security.sasl.enabled.mechanisms: PLAIN
security.sasl.plain.jaas.config: com.alibaba.fluss.security.auth.sasl.plain.PlainLoginModule required user_admin="admin-Fluss-NB!." user_fluss="fluss-Fluss-NB!.";
authorizer.enabled: true
super.users: User:admin,User:fluss
tablet-server.id: 4
datalake.format: paimon
datalake.paimon.metastore: filesystem
datalake.paimon.warehouse: /data1/module/fluss-0.7.0/tmp/paimon_data_warehouse
```

---

```
vim server-node83.yaml
```

```
env.java.home: /data1/module/jdk-17.0.14
zookeeper.address: node146:2181,node147:2181,node148:2181
zookeeper.path.root: /fluss
default.bucket.number: 1
default.replication.factor: 1
data.dir: /data1/module/fluss-0.7.0/tmp/fluss-data
remote.data.dir: hdfs://node146:8020/fluss/tmp/fluss-remote-data
bind.listeners: CLIENT://node83:6000, INTERNAL://node83:9123
advertised.listeners: CLIENT://{node83's public network IP}:{public network port}
security.protocol.map: CLIENT:SASL, INTERNAL:PLAINTEXT
internal.listener.name: INTERNAL
security.sasl.enabled.mechanisms: PLAIN
security.sasl.plain.jaas.config: com.alibaba.fluss.security.auth.sasl.plain.PlainLoginModule required user_admin="admin-Fluss-NB!." user_fluss="fluss-Fluss-NB!.";
authorizer.enabled: true
super.users: User:admin,User:fluss
tablet-server.id: 5
datalake.format: paimon
datalake.paimon.metastore: filesystem
datalake.paimon.warehouse: /data1/module/fluss-0.7.0/tmp/paimon_data_warehouse
```

- 同步分发 fluss 安装目录

```
xsync /data1/module/fluss-0.7.0
```

- 追加配置环境变量

```
vim ~/.bashrc
```

```
export FLUSS_HOME=/data1/module/fluss-0.7.0
export PATH=$PATH:$FLUSS_HOME/bin
```

- 同步 环境变量配置文件

```
xsync ~/.bashrc
```

- 生效环境变量

```
xcall "source ~/.bashrc"
```

- 统一批量配置 fluss server 配置文件

```
vim all-server-yaml.sh
```

```
#!/bin/bash

hosts=(
node14{6..8}
node8{1..3}
)

for host in ${hosts[@]}
do
    echo "-------- $host --------"
    ssh $host "cp -v /data1/module/fluss-0.7.0/conf/server-$host.yaml /data1/module/fluss-0.7.0/conf/server.yaml"
    echo ""
done
```

- 执行脚本

```
sh all-server-yaml.sh
```

- 编写 fluss 批量启停脚本

```
vim ~/bin/fluss.sh
```

```
#!/bin/bash

hosts=(
node14{7,8}
node8{1..3}
)

case $1 in

"start"){
    echo "-------- FLUSS CLUSTER START --------"
    echo ""
    echo "---- start coordinator-server ----"
    ssh node146 "/data1/module/fluss-0.7.0/bin/coordinator-server.sh start"
    echo ""
    echo "---- start tablet-server ----"
    for host in ${hosts[@]}
    do
        echo ""
        echo "---- start $host tablet-server ----"
        ssh $host "/data1/module/fluss-0.7.0/bin/tablet-server.sh start"
        echo ""
    done
};;

"stop"){
    echo "-------- FLUSS CLUSTER STOP --------"
    echo ""
    echo "---- stop tablet-server ----"
    for host in ${hosts[@]}
    do
        echo ""
        echo "---- stop $host tablet-server ----"
        ssh $host "/data1/module/fluss-0.7.0/bin/tablet-server.sh stop"
        echo ""
    done
    echo ""
    echo "---- stop coordinator-server ----"
    ssh node146 "/data1/module/fluss-0.7.0/bin/coordinator-server.sh stop"
    echo ""
};;

esac
```

- 添加可执行权限

```
chmod +x ~/bin/fluss.sh
```

- 启动 fluss 集群并查看集群进程

```
fluss.sh start
jpsall
```

- 停止 fluss 集群并查看集群进程

```
fluss.sh stop
jpsall
```


## 16. flink sql 配置鉴权及快捷键

- 进入 flink sql 客户端

```
sql-client.sh
```

- 配置鉴权

```
Flink SQL> CALL fluss_catalog.sys.add_acl(
>     resource => 'cluster',
>     permission => 'ALLOW',
>     principal => 'User:fluss',
>     operation => 'ALL',
>     host => '*'
> );
+---------+
|  result |
+---------+
| success |
+---------+
1 row in set

Flink SQL>
```

- 查看鉴权

```
Flink SQL> CALL fluss_catalog.sys.list_acl(
>     resource => 'cluster'
> );
+-------------------------------------------------------------------------------------------------+
|                                                                                          result |
+-------------------------------------------------------------------------------------------------+
| resourceType="fluss-cluster";permission="ALLOW";principal="User:fluss";operation="ALL";host="*" |
+-------------------------------------------------------------------------------------------------+
1 row in set

Flink SQL>
```

- 配置 flink sql 快速启动 免认证模式 脚本

```
vim ~/bin/fsql-nosasl-init.sql
```

```
CREATE CATALOG IF NOT EXISTS fluss_catalog WITH (
  'type' = 'fluss',
  'bootstrap.servers' = 'node146:9123',
  'client.security.protocol' = 'PLAINTEXT'
);
use catalog fluss_catalog;
SET 'execution.runtime-mode' = 'streaming';
SET 'sql-client.execution.result-mode' = 'tableau';
SET 'sql-client.execution.max-table-result.rows' = '10000';
SET 'table.exec.state.ttl' = '24h';
```

- 配置 flink sql 快速启动 SASL 认证模式 脚本

```
vim ~/bin/fsql-sasl-init.sql
```

```
CREATE CATALOG IF NOT EXISTS fluss_catalog WITH (
  'type' = 'fluss',
  'bootstrap.servers' = 'node146:9000',
  'client.security.protocol' = 'SASL',
  'client.security.sasl.mechanism' = 'PLAIN',
  'client.security.sasl.username' = 'fluss',
  'client.security.sasl.password' = 'fluss-Fluss-NB!.'
);
use catalog fluss_catalog;
SET 'execution.runtime-mode' = 'streaming';
SET 'sql-client.execution.result-mode' = 'tableau';
SET 'sql-client.execution.max-table-result.rows' = '10000';
SET 'table.exec.state.ttl' = '24h';
```

- 追加配置环境变量文件

```
vim ~/.bashrc
```

```
alias fsql='sql-client.sh -i ~/bin/fsql-nosasl-init.sql'
alias fsqls='sql-client.sh -i ~/bin/fsql-sasl-init.sql'
```

- 批量生效环境变量

```
xcall "source ~/.bashrc"
```

- 免认证模式进 flink sql

```
fsql
```

- SASL 认证模式进 flink sql

```
fsqls
```

## 17. 统一群启脚本

```
vim ~/bin/cluster.sh
```

```
#!/bin/bash

case $1 in

"start"){
    echo "-------- CLUSTER START --------"
    echo ""
    zk.sh start
    echo ""
    hdfs.sh start
    echo ""
    flink.sh start
    echo ""
    fluss.sh start
    echo ""
};;

"stop"){
    echo "-------- CLUSTER STOP --------"
    echo ""
    fluss.sh stop
    echo ""
    flink.sh stop
    echo ""
    hdfs.sh stop
    echo ""
    zk.sh stop
    echo ""
};;

esac
```

- 脚本添加可执行权限

```
chmod +x ~/bin/cluster.sh
```

- 集群批量启动

```
cluster.sh start
```

- 集群批量停止

```
cluster.sh stop
```

- 批量查看集群节点进程

```
jpsall
```

- 集群各节点进程全启

```
-------- node146 --------
3578102 QuorumPeerMain
3580834 SqlClient
3577631 DataNode
3579181 StandaloneSessionClusterEntrypoint
3580298 CoordinatorServer
3579880 TaskManagerRunner
3577481 NameNode

-------- node147 --------
2580517 TaskManagerRunner
2579685 QuorumPeerMain
2579488 DataNode
2580863 TabletServer

-------- node148 --------
2582215 TaskManagerRunner
2581071 DataNode
2581386 QuorumPeerMain
2582569 TabletServer
2581192 SecondaryNameNode

-------- node81 --------
2578273 TabletServer
2577921 TaskManagerRunner

-------- node82 --------
2578245 TabletServer
2577897 TaskManagerRunner

-------- node83 --------
2577671 TaskManagerRunner
2578018 TabletServer
```

## 18. 关于此文的几点说明

- 关于笔者张阳，曾就职于 中国人保、麒麟软件、华为、铁科院、中广核工程、南方电网、华夏银行，欢迎有坑位的老板 wechat 联系: zhangyang_bigdata

- flink 配置过程中，对 taskmanager 堆内存分配，参考：https://nightlies.apache.org/flink/flink-docs-release-1.20/zh/docs/deployment/memory/mem_setup/

- fluss 配置的 remote.data.dir 远程数据目录 配置的是 hdfs 路径，新部署集群前务必要规划好是否使用 hdfs 或 本地目录存储，部署后使用集群后如果变更远程目录又本地到 hdfs 会出现没数据的情况，宇侠老师给讲解是 kv 数据信息存储在内存，即便机器重启也无效，zk 节点存储元数据信息；

- fluss 配置的 SASL 鉴权，主要是为了使用 IDEA 远程连接 FLUSS，感谢洪顺老师指导给提供的配置参考支持！

- flink 和 fluss 配置 JDK 17 环境变量，为了防止和当前用户环境变量冲突，所以配置在配置文件中 env.java.home 参数，感谢云邪伍神指导！

- 此文主要用于分享交流 Fluss 技术，若文章有不当之处，欢迎各位同行批评指正，不胜感激！

- 此文后续应用请转向 电信数据智能专家 左美美老师 的 B站 Fluss 系列课程：https://space.bilibili.com/1710526702/lists/5768077

## 19. 致谢

- 感谢 Fluss 社区大神 云邪老师、宇侠老师、洪顺老师 提供的技术答疑 & 协助支持！

- 祝 Fluss 社区越来越好！天天向上！

