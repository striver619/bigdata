#!/bin/bash

hosts=(
node146
node147
node148
)

case $1 in

"start"){
    echo "-------- zk start --------"
    echo ""
    for host in ${hosts[@]}	
    do
        echo "---- zk $host start ----"
        ssh $host "/data1/bigdata/module/zookeeper-3.8.4/bin/zkServer.sh start"
        echo ""
    done
};;

"stop"){
    echo "-------- zk stop --------"
    echo ""
    for host in ${hosts[@]}	
    do
        echo "---- zk $host stop ----"
        ssh $host "/data1/bigdata/module/zookeeper-3.8.4/bin/zkServer.sh stop"
        echo ""
    done
};;

"status"){
    echo "-------- zk status --------"
    echo ""
    for host in ${hosts[@]}	
    do
        echo "---- zk $host status ----"
        ssh $host "/data1/bigdata/module/zookeeper-3.8.4/bin/zkServer.sh status"
        echo ""
    done
};;

esac

