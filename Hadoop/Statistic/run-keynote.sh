#!/usr/bin/bash

cdir=$(dirname $(readlink -f "$0"))

jarfile="${cdir}/target/statistic-1.0-SNAPSHOT.jar"
main_class="org.keynote.statistic.Statistic"

gitee_userinfo_file="${cdir}/../../data/Gitee-All-Gitee-user-detail-data-2020-10-28 19_29_54.csv"
dfs_userinfo_input="/gitee_userinfo_input"
dfs_userinfo_output="/gitee_userinfo_results"

result_dir=~/hadoop_results

echo -e "\033[35mStarting to confirm and prepare...\033[0m"
if [[ -f "$gitee_userinfo_file" ]];then
  echo -e "Gitee user info existed \033[32m OK \033[0m"
else
  echo -e "\033[31mThe Gitee user info data file doesn't exist: $gitee_userinfo_file \033[0m"
fi

hadoop fs -rm -r ${dfs_userinfo_input} > /dev/null 2>&1
format_input=$(echo "$gitee_userinfo_file" | sed 's/ /\%20/g')
hadoop fs -put "$format_input" "$dfs_userinfo_input" > /dev/null 2>&1
hadoop fs -rm -r ${dfs_userinfo_output} > /dev/null 2>&1
echo -e "Input data prepared in HDFS \033[32m OK \033[0m"

rm -fr $result_dir > /dev/null 2>&1 || true && echo -e "Results collection prepared \033[32m OK \033[0m"

printf "\n"
echo -e "\033[35mStarting to count statistics of openEuler gitee users...\033[0m"
hadoop jar "$jarfile" "$main_class" ${dfs_userinfo_input} ${dfs_userinfo_output}

printf "\n"
echo -e "\033[35mStarting to collect result statistics...\033[0m"
hadoop fs -get ${dfs_userinfo_output} ${result_dir}
echo -e "\033[32mSuccessfully count the Gitee user statistics!\033[0m"