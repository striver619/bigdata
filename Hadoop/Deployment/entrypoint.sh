#!/bin/bash
set -x

svcs_specified=${HADOOP_SERVICES:-""}
hadoop_controller=${HADOOP_CONTROLLER:-""}

if [[ "$hadoop_controller" != "" ]]; then
  sed -i "s/localhost/$hadoop_controller/g" $HADOOP_HOME/etc/hadoop/core-site.xml
  sed -i "s/localhost/$hadoop_controller/g" $HADOOP_HOME/etc/hadoop/yarn-site.xml
fi

sleep 5

hostnames=${HOST_NAMES:-""}
k8s_namespace=${K8S_NAMESPACE:-"hadoop"}

for hn in $hostnames; do
  ipaddr=""
  count=0
  while ! echo $ipaddr | grep "172."
  do
    ipaddr=$(nslookup *.${hn}.${k8s_namespace} | grep -Eo "([0-9]+\.)+[0-9]+"| tail -1)
    let count++
    [ $count -ge 150 ] && echo "ERROR: cannot query internal IP of $hn after 300s" && break
    sleep 2
  done
  echo "$ipaddr    $hn" | sudo tee -a /etc/hosts
done

function start_svc() {
  case $1 in
  namenode)
    hdfs namenode -format
    hdfs --daemon start namenode
    ;;
  datanode)
    hdfs --daemon start datanode
    ;;
  resourcemanager)
    yarn --daemon start resourcemanager
    ;;
  nodemanager)
    yarn --daemon start nodemanager
    ;;
  historyserver)
    mapred --daemon start historyserver
    ;;
  *)
    echo "Unsupported service $1"
    exit 1
    ;;
  esac
}
[[ $# != 0 ]] && exec "$@"

if [[ "$svcs_specified" == "all" ]]; then
  svcs="namenode datanode resourcemanager nodemanager historyserver"
elif [[ "$svcs_specified" == "controller" ]]; then
  svcs="namenode resourcemanager historyserver"
elif [[ "$svcs_specified" == "worker" ]]; then
  svcs="datanode nodemanager"
else
  svcs="$svcs_specified"
fi

for svc in $svcs; do
  start_svc "$svc"
done

tail -f /dev/null
