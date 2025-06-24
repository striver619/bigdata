#!/bin/sh

cat <<EOF> ~/.bashrc

# LOCAL ENV PATH

# sh color style
PS1='\[\033[01;33;1m\]\u\[\033[01;37;0m\]@\[\033[01;34;1m\]\h \[\033[01;37;1m\]\w \[\033[0m\]$ '

# shortcut
## flinksql
alias fsql='sql-client.sh'

# User environment PATH
PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export PATH

# local bigdata env path

## JDK 8
export JAVA_HOME=/data1/bigdata/module/bisheng-jdk1.8.0_452
export PATH=$PATH:$JAVA_HOME/bin

## HADOOP 3.4.1
export HADOOP_HOME=/data1/bigdata/module/hadoop-3.4.1
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HADOOP_HOME/lib/native
export HADOOP_CLASSPATH=`hadoop classpath`

## ZOOKEEPER 3.8.4
export ZOOKEEPER_HOME=/data1/bigdata/module/zookeeper-3.8.4
export PATH=$PATH:$ZOOKEEPER_HOME/bin

## FLINK 1.20.1
export FLINK_HOME=/data1/bigdata/module/flink-1.20.1
export PATH=$PATH:$FLINK_HOME/bin

## FLUSS 0.7.0
export FLUSS_HOME=/data1/bigdata/module/fluss-0.7.0
export PATH=$PATH:$FLUSS_HOME/bin

EOF
