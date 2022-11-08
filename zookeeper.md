vim zk-run.sh

```shell
#!/bin/bash

case $1 in
"start"){
	for i in hadoop41 hadoop42 hadoop43
	do
        echo ---------- zookeeper $i 启动 ------------
		ssh $i "/datafs/zookeeper/bin/zkServer.sh start"
	done
};;
"stop"){
	for i in hadoop41 hadoop42 hadoop43
	do
        echo ---------- zookeeper $i 停止 ------------    
		ssh $i "/datafs/zookeeper/bin/zkServer.sh stop"
	done
};;
"status"){
	for i in hadoop102 hadoop103 hadoop104
	do
        echo ---------- zookeeper $i 状态 ------------    
		ssh $i "/datafs/zookeeper/bin/zkServer.sh status"
	done
};;
esac
```

chmod u+x ./zk-run.sh

./zk-run.sh start

./zk-run.sh stop

./zk-run.sh status
