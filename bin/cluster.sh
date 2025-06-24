#!/bin/bash

case $1 in

"start"){
    echo "-------- cluster start --------"
    echo ""
    zk.sh start
    echo ""
    hdp.sh start
    echo ""
    flink.sh start
    echo ""
    fluss.sh start
    echo ""
};;

"stop"){
    echo "-------- cluster stop --------"
    echo ""
    fluss.sh stop
    echo ""
    flink.sh stop
    echo ""
    hdp.sh stop
    echo ""
    zk.sh stop
    echo ""
};;

esac

