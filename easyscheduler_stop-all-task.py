#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import requests

pageUrl = "http://192.168.1.6:12345/escheduler/projects/dw/instance/list-paging?searchVal=&pageSize=1000&pageNo=1" \
          "&host=&stateType=RUNNING_EXEUTION&startDate=&endDate= "

resp = requests.post(url='http://192.168.1.6:12345/escheduler/login',
                     headers={'Content-Type': 'application/x-www-form-urlencoded'},
                     data={'userName': 'zhangsan', 'userPassword': '123456'})

sessionId = resp.headers.get('Set-Cookie').split("=")[1]

resp2 = requests.get(url=pageUrl, headers={'Cookie': 'sessionId=' + sessionId + ';language=zh_CN'})

data = resp2.json()['data']['totalList']

for e in data:
    resp2 = requests.post(url='http://192.168.1.6:12345/escheduler/projects/dw/executors/execute',
                         headers={'Content-Type': 'application/x-www-form-urlencoded',
                                  'Cookie': 'sessionId=' + sessionId + ';language=zh_CN'},
                         data = {'processInstanceId': e['id'], 'executeType': 'STOP'})
