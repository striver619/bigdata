#!/bin/bash

case $1 in

"start"){
    echo "-------- flink start --------"
    echo ""
    ssh node146 "/data1/bigdata/module/flink-1.20.1/bin/start-cluster.sh"
    echo ""
};;

"stop"){
    echo "-------- flink stop --------"
    echo ""
    ssh node146 "/data1/bigdata/module/flink-1.20.1/bin/stop-cluster.sh"
    echo ""
};;

esac

