hive metastore 、hiveserver2 服务启停脚本

cat ~/bin/mshs2.sh

```shell
#!/bin/bash

case $1 in
"start"){
    echo "----"
    echo "-- 1. start metastore ... --"
    nohup hive --service metastore -p 9083 >> /usr/hdp/hive/logs/metastore.log 2>&1 &
    echo "----"
    sleep 3
    echo "-- 2. start hiveserver2 ... --"
    nohup hiveserver2 >> /usr/hdp/hive/logs/hiveserver2.log 2>&1 &
    echo "----"
};;
"status"){
    echo "----"
    echo "-- 1. check metastore status --"
    ps -ef|grep metastore|grep -v 'grep'
    echo "----"
    echo "-- 2. check hiveserver2 status --"
    ps -ef|grep hiveserver2|grep -v 'grep'
    echo "----"
};;
"stop"){
    echo "----"
    echo "-- 1. stop metastore --"
    ps -ef|grep metastore|grep -v 'grep'|awk '{print $2}'|xargs -n1 kill -9
    echo "----"
    sleep 3
    echo "-- 2. stop hiveserver2 --"
    ps -ef|grep hiveserver2|grep -v 'grep'|awk '{print $2}'|xargs -n1 kill -9
    echo "----"
};;
esac
```

chmod 700 ~/bin/mshs2.sh

mshs2.sh start

mshs2.sh status

mshs2.sh stop
