vim kafka-run.sh

```shell
#! /bin/bash

# https://blog.csdn.net/frdevolcqzyxynjds

case $1 in
"start"){
    for i in hadoop41 hadoop42 hadoop43
    do
        echo " --------启动 $i Kafka-------"
        ssh $i "/datafs/kafka/bin/kafka-server-start.sh -daemon /datafs/kafka/config/server.properties"
    done
};;
"stop"){
    for i in hadoop41 hadoop42 hadoop43
    do
        echo " --------停止 $i Kafka-------"
        ssh $i "/datafs/kafka/bin/kafka-server-stop.sh stop"
    done
};;
esac
```

chmod u+x ./kafka-run.sh

./kafka-run.sh start

./kafka-run.sh stop
