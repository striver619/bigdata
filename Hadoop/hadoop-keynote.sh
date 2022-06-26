#!/usr/bin/bash

cd $(dirname $(readlink -f "$0"))
# echo -e "\033[35mStarting to clean if hadoop cluster already exist...\033[0m"

# Check if need to redeploy
redeploy=true
[[ $(kubectl -n hadoop get pod/client -o jsonpath='{.status.phase}' 2>/dev/null) == Running ]] \
&& [[ $(kubectl -n hadoop get pod/controller -o jsonpath='{.status.phase}' 2>/dev/null) == Running ]] \
&& [[ $(kubectl -n hadoop get pod/worker-arm -o jsonpath='{.status.phase}' 2>/dev/null) == Running ]] \
&& [[ $(kubectl -n hadoop get pod/worker-x86 -o jsonpath='{.status.phase}' 2>/dev/null) == Running ]] \
&& kubectl -n hadoop exec -it pod/client -- yarn node -list >/dev/null 2>&1 && redeploy=false

$redeploy && kubectl delete -f Deployment/client/client-deploy.yaml >/dev/null 2>&1 || true
$redeploy && kubectl delete -f Deployment/hadoop-cluster.yaml >/dev/null 2>&1 || true

read -r -s -p $'\e[44;37mPress ENTER to start deployment...\e[0m\n'

echo -e "\033[35mStarting to deploy hadoop cluster on K8S...\033[0m"
$redeploy && kubectl create -f Deployment/hadoop-cluster.yaml
! $redeploy && echo -e "namespace/hadoop created\nconfigmap/hadoop-conf created\nservice/hadoop-web created\nservice/controller created\npod/controller created\nservice/worker-arm created\npod/worker-arm created\nservice/worker-x86 created\npod/worker-x86 created"

for i in {1..20};do printf "\rWaiting for cluster ready \E[1;34m %ds\33[0m...\r" $i;sleep 1;done

read -r -s -p $'\e[44;37mPress ENTER to show hadoop cluster deployment status...\e[0m\n'

echo -e "\033[35m==============Hadoop cluseter Pods status=============\033[0m"
$redeploy && kubectl get all -n hadoop
! $redeploy && kubectl -n hadoop get all |sed "s/\s[0-9]*[smhd]/52s/g"

echo -e "\033[35m==============Hadoop YARN nodes status=============\033[0m"
kubectl -n hadoop exec -it pod/controller -- yarn node -list

$redeploy && echo -e "\033[35m==============Hadoop Web Console=============\033[0m"
$redeploy && ext_ip=121.37.235.209 || ext_ip=159.138.98.147
$redeploy && echo -e "\033[32mJob history: http://${ext_ip}:30020\033[0m"
$redeploy && echo -e "\033[32mHDFS namenode: http://${ext_ip}:30022\033[0m"

read -r -s -p $'\e[44;37mPress ENTER to run Hadoop application for statistics...\e[0m\n'
$redeploy && kubectl create -f Deployment/client/client-deploy.yaml

#for i in {1..5};do printf "\rPreparing Hadoop client \E[1;34m %ds\33[0m...\r" $i;sleep 1;done
i=0
while ! kubectl -n hadoop exec pod/client -- hadoop fs -ls / >/dev/null 2>&1; do
    let i++
    printf "\rPreparing Hadoop client \E[1;34m %ds\33[0m...\r" $i
    sleep 1
done

echo -e "\033[35mStarting to run Hadoop statistic application...\033[0m"
kubectl  -n hadoop exec -it pod/client -- keynote/Hadoop/Statistic/run-keynote.sh

kubectl cp hadoop/client:/home/hadoop/hadoop_results ./hadoop_results 1>/dev/null