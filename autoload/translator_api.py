#!/usr/bin/env python3
# -*- coding: utf-8 -*-


# tmxmall api
# import requests, json
# setmtprovider_url = "http://api.tmxmall.com/v1/http/setmtprovider?"\
        # + "user_name=1315521905@qq.com&client_id=6ff3d6d5649954f1fc942f2e9908e6eb"\
        # + "&mt_provider=Youdao"
# r_ = requests.get(setmtprovider_url)
# r = r_.json()
# print(r)

# translate_url = "http://api.tmxmall.com/v1/http/mttranslate?"\
        # + "text=你好"\
        # + "&user_name=1315521905@qq.com&client_id=6ff3d6d5649954f1fc942f2e9908e6eb"\
        # + "&from=zh-CN&to=en-US&de=pascal"
# r_ = requests.get(translate_url)
# r = r_.json()
# print(r)

# google api
# from googletrans import Translator
# t = Translator(service_urls=[
    # 'translate.google.cn',
    # 'translate.google.com'
    # ])
# print(t.translate('你好世界'))

import requests
from random import randint
import hashlib
import re

def get_translate_response(q):
    if not isinstance(q, str):
        return "get_translate_response: error, q is not a str"
    baidu_url = "http://api.fanyi.baidu.com/api/trans/vip/translate"

    appid = '20200305000393031'
    salt = str(randint(pow(2, 16), pow(2,32)))
    passwd = 'P1jM70wUbgTg5iiIYPaU'

    md5 = hashlib.md5()
    md5.update((appid+q+salt+passwd).encode('utf-8'))

    r = requests.get(baidu_url, params={
        'q': q,
        'from': 'en',
        'to': 'zh',
        'appid': appid,
        'salt': salt,
        'sign': md5.hexdigest()
        })
    # print(r_)
    # return r_.json()
    return r

def translate_safe(q):
    r = get_translate_response(q)
    return r.text

    # try:
        # ret_json = r.json()
    # except Exception as e:
        # return [e.__repr__()]

    # if 'trans_result' not in ret_json.keys():
        # return [ret_json.__repr__()]
    # else:
        # trans_result = ret_json['trans_result']
        # return [t['dst'] for t in trans_result]
