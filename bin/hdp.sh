#!/bin/bash

case $1 in

"start"){
    echo "-------- hadoop start --------"
    echo ""
    echo "---- hadoop hdfs start ----"
    ssh node146 "/data1/bigdata/module/hadoop-3.4.1/sbin/start-dfs.sh"
    echo ""
    echo "---- hadoop yarn start ----"
    ssh node147 "/data1/bigdata/module/hadoop-3.4.1/sbin/start-yarn.sh"
    echo ""
};;

"stop"){
    echo "-------- hadoop stop --------"
    echo ""
    echo "---- hadoop yarn stop ----"
    ssh node147 "/data1/bigdata/module/hadoop-3.4.1/sbin/stop-yarn.sh"
    echo ""
    echo "---- hadoop hdfs stop ----"
    ssh node146 "/data1/bigdata/module/hadoop-3.4.1/sbin/stop-dfs.sh"
    echo ""
};;

esac

