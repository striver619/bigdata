#!/usr/bin/bash

hadoop_controller=${HADOOP_CONTROLLER:-""}
k8s_namespace=${K8S_NAMESPACE:-"hadoop"}

if [[ "$hadoop_controller" != "" ]]; then
  sed -i "s/localhost/$hadoop_controller/g" ${HADOOP_HOME}/etc/hadoop/*-site.xml
  ipaddr=""
  count=0
  while ! echo $ipaddr | grep "172."; do
    ipaddr=$(nslookup *.${hadoop_controller}.${k8s_namespace} | grep -Eo "([0-9]+\.)+[0-9]+" | tail -1)
    let count++
    [ $count -ge 150 ] && echo "ERROR: cannot query internal IP of $hadoop_controller after 300s" && break
    sleep 2
  done
  echo "$ipaddr    $hadoop_controller" | sudo tee -a /etc/hosts
fi

[[ $# != 0 ]] && exec "$@"
tail -f /dev/null
