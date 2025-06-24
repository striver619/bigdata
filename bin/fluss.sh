#!/bin/bash

case $1 in

"start"){
    echo "-------- fluss start --------"
    echo ""
    echo "---- start node146 coordinator-server ----"
    ssh node146 "/data1/bigdata/module/fluss-0.7.0/bin/coordinator-server.sh start"
    echo ""
    echo "---- start node147 tablet-server ----"
    ssh node147 "/data1/bigdata/module/fluss-0.7.0/bin/tablet-server.sh start"
    echo ""
    echo "---- start node148 tablet-server ----"
    ssh node148 "/data1/bigdata/module/fluss-0.7.0/bin/tablet-server.sh start"
    echo ""
};;

"stop"){
    echo "-------- fluss stop --------"
    echo ""
    echo "---- stop node148 tablet-server ----"
    ssh node148 "/data1/bigdata/module/fluss-0.7.0/bin/tablet-server.sh stop"
    echo ""
    echo "---- stop node147 tablet-server ----"
    ssh node147 "/data1/bigdata/module/fluss-0.7.0/bin/tablet-server.sh stop"
    echo ""
    echo "---- stop node146 coordinator-server ----"
    ssh node146 "/data1/bigdata/module/fluss-0.7.0/bin/coordinator-server.sh stop"
    echo ""
};;

esac

