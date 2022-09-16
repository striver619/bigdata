#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import requests

pageUrl = "http://ip1:port/escheduler/projects/dw/instance/list-paging?searchVal=&pageSize=1000&pageNo=1" \
          "&host=&stateType=RUNNING_EXEUTION&startDate=&endDate= "

# 获取 Cookie:
# EasyScheduler 工作流实例 页面，浏览器 F12
# Network --> Fetch/XHR --> F5 刷新页面 --> Name --> list-paging?searchVal=&page
# Headers --> Request Headers --> Cookie

sessionId = 'eexxx76-5xx4-4xx4-ad96-xxx8'

resp = requests.get(url=pageUrl, headers={'Cookie': 'sessionId=' + sessionId + ';language=zh_CN',
                                          'X-Forwarded-for': 'ip2'})

data = resp.json()['data']['totalList']
for e in data:
    resp = requests.post(url='http://ip1:port/escheduler/projects/dw/executors/execute',
                         headers={'Content-Type': 'application/x-www-form-urlencoded',
                                  'Cookie': 'sessionId=' + sessionId + ';language=zh_CN',
                                  'X-Forwarded-for': 'ip2'},
                         data = {'processInstanceId': e['id'], 'executeType': 'STOP'})
