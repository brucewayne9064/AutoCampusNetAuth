#!/bin/sh

# ping 的总次数
PING_SUM=3

# ping 的间隔时间，单位秒
SLEEP_SEC=10

# 连续重启网卡 REBOOT_CNT 次网络都没有恢复正常，重启软路由
# 时间= (SLEEP_SEC * PING_SUM + 20) * REBOOT_CNT
REBOOT_CNT=3

LOG_PATH="/root/ping/log.txt"  # 日志位置
cnt=0  # ping的次数
reboot_cnt=0

# 登录请求的URL和表单数据
# LOGIN_URL=""
# USER_ID=""
# PASSWORD=""
# SERVICE=""
# QUERY_STRING=""
# OPERATOR_PWD=""
# OPERATOR_USER_ID=""
# VALIDCODE=""
# PASSWORD_ENCRYPT=""

# 检查网络连接
check_network() {
    ping -c 1 -W 1 www.baidu.com > /dev/null
    ret=$?

    ping -c 1 -W 1 www.bilibili.com > /dev/null
    ret2=$?

    if [ $ret -eq 0 ] || [ $ret2 -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# 记录日志
log() {
    echo -n `date '+%Y-%m-%d %H:%M:%S'` >> $LOG_PATH
    echo "$1" >> $LOG_PATH
    echo "$1"
}

# 执行登录
perform_login() {

    CURRENT_IP=$(ifconfig | grep inet | grep -v inet6 | grep -v 127 | grep -v 192 | awk '{print $(NF-2)}' | cut -d ':' -f2)
    MAC_ADDRESS=$(ifconfig ra0 | grep HWaddr | awk '{print $NF}' | tr '[:upper:]' '[:lower:]' | tr ':' '-')
    curl -X POST "http://172.25.249.64/eportal/InterFace.do?method=login" -H "Accept: */*" -H "Accept-Language: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6" -H "Connection: keep-alive" -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" -H "Cookie: EPORTAL_COOKIE_USERNAME=19102847469; EPORTAL_COOKIE_SERVER=; EPORTAL_COOKIE_DOMAIN=; EPORTAL_COOKIE_SAVEPASSWORD=true; EPORTAL_COOKIE_OPERATORPWD=; EPORTAL_COOKIE_NEWV=true; EPORTAL_COOKIE_PASSWORD=42ec653fc30c627c25cbd13d5dce8d55c014f6b6ee2739e43a9ab40544f37c55dd79d1d8b5cd39ebb938a796b75e03fde81487f70ff882a2ab639e2db0115a7528399c62998e4bb518a995eee677ef401bd7cb2de5778c00c767d7741dbbdcc06818cff955d9203f42555e80c44bc562a469046ee2c059ff43aa016536219785; EPORTAL_AUTO_LAND=; EPORTAL_USER_GROUP=%E7%94%B5%E5%AD%90%E7%A7%91%E5%A4%A7%E6%B8%85%E6%B0%B4%E6%B2%B3%E6%A0%A1%E5%8C%BA%E7%94%A8%E6%88%B7%E7%BB%84; EPORTAL_COOKIE_SERVER_NAME=; JSESSIONID=06FB1A96D12160A5E783BC79DB1F004C; JSESSIONID=748075FE982D90B1116C701351160002" -H "Origin: http://172.25.249.70" -H "Referer: http://172.25.249.70/eportal/index.jsp?userip=${CURRENT_IP}&wlanacname=&nasip=171.88.130.251&wlanparameter=${MAC_ADDRESS}&url=http://123.123.123.123/&userlocation=ethtrunk/2:281.405" -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36" --data-raw "userId=19102847469&password=42ec653fc30c627c25cbd13d5dce8d55c014f6b6ee2739e43a9ab40544f37c55dd79d1d8b5cd39ebb938a796b75e03fde81487f70ff882a2ab639e2db0115a7528399c62998e4bb518a995eee677ef401bd7cb2de5778c00c767d7741dbbdcc06818cff955d9203f42555e80c44bc562a469046ee2c059ff43aa016536219785&service=&queryString=userip%253D${CURRENT_IP}%2526wlanacname%253D%2526nasip%253D171.88.130.251%2526wlanparameter%253D${MAC_ADDRESS}%2526url%253Dhttp%253A%252F%252F123.123.123.123%252F%2526userlocation%253Dethtrunk%252F2%253A281.405&operatorPwd=&operatorUserId=&validcode=&passwordEncrypt=true"

    if [ $? -eq 0 ]; then
        log "登录成功"
    else
        log "登录失败"
    fi
}


while :; do
    # 如果网络ping正常，退出while循环
    if check_network; then
        log 'network is ok'
        exit 0
    else
        # 网络不正常， 增加计数器并记录日志
        cnt=$((cnt + 1))  
        log "-> [$cnt/$PING_SUM] Network maybe disconnected, checking again after $SLEEP_SEC seconds!"

        # 如果计数器达到PING_SUM，则调用perform_login函数尝试重新登录。
        if [ $cnt -ge $PING_SUM ]; then
            log 'try to re-login'
            perform_login

            cnt=0
            sleep 8

            reboot_cnt=$((reboot_cnt + 1))
            # 如果尝试重新登录次数达到REBOOT_CNT，则重启路由器。
            if [ $reboot_cnt -ge $REBOOT_CNT ]; then
                log "-> Network has some problem, lets reboot"
                reboot
            fi
        fi
    fi   
    # 间隔 SLEEP_SEC 秒再循环一次
    sleep $SLEEP_SEC
done


# 抓取的原始cURL
# curl 'http://172.25.249.70/eportal/InterFace.do?method=login' \
#   -H 'Accept: */*' \
#   -H 'Accept-Language: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6' \
#   -H 'Connection: keep-alive' \
#   -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
#   -H 'Cookie: EPORTAL_COOKIE_USERNAME=19102847469; EPORTAL_COOKIE_SERVER=; EPORTAL_COOKIE_DOMAIN=; EPORTAL_COOKIE_SAVEPASSWORD=true; EPORTAL_COOKIE_OPERATORPWD=; EPORTAL_COOKIE_NEWV=true; EPORTAL_COOKIE_PASSWORD=42ec653fc30c627c25cbd13d5dce8d55c014f6b6ee2739e43a9ab40544f37c55dd79d1d8b5cd39ebb938a796b75e03fde81487f70ff882a2ab639e2db0115a7528399c62998e4bb518a995eee677ef401bd7cb2de5778c00c767d7741dbbdcc06818cff955d9203f42555e80c44bc562a469046ee2c059ff43aa016536219785; EPORTAL_AUTO_LAND=; EPORTAL_USER_GROUP=%E7%94%B5%E5%AD%90%E7%A7%91%E5%A4%A7%E6%B8%85%E6%B0%B4%E6%B2%B3%E6%A0%A1%E5%8C%BA%E7%94%A8%E6%88%B7%E7%BB%84; EPORTAL_COOKIE_SERVER_NAME=; JSESSIONID=06FB1A96D12160A5E783BC79DB1F004C; JSESSIONID=748075FE982D90B1116C701351160002' \
#   -H 'Origin: http://172.25.249.70' \
#   -H 'Referer: http://172.25.249.70/eportal/index.jsp?userip=100.66.199.207&wlanacname=&nasip=171.88.130.251&wlanparameter=5c-02-14-ed-50-75&url=http://123.123.123.123/&userlocation=ethtrunk/2:281.405' \
#   -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36' \
#   --data-raw 'userId=19102847469&password=42ec653fc30c627c25cbd13d5dce8d55c014f6b6ee2739e43a9ab40544f37c55dd79d1d8b5cd39ebb938a796b75e03fde81487f70ff882a2ab639e2db0115a7528399c62998e4bb518a995eee677ef401bd7cb2de5778c00c767d7741dbbdcc06818cff955d9203f42555e80c44bc562a469046ee2c059ff43aa016536219785&service=&queryString=userip%253D100.66.199.207%2526wlanacname%253D%2526nasip%253D171.88.130.251%2526wlanparameter%253D5c-02-14-ed-50-75%2526url%253Dhttp%253A%252F%252F123.123.123.123%252F%2526userlocation%253Dethtrunk%252F2%253A281.405&operatorPwd=&operatorUserId=&validcode=&passwordEncrypt=true' \
#   --insecure

# # 删减后的抓取的登录cURL
# curl 'http://172.25.249.70/eportal/InterFace.do?method=login' \
#   -H 'Accept: */*' \
#   -H 'Accept-Language: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6' \
#   -H 'Connection: keep-alive' \
#   -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
#   -H 'Cookie: EPORTAL_COOKIE_USERNAME=19102847469; EPORTAL_COOKIE_SERVER=; EPORTAL_COOKIE_DOMAIN=; EPORTAL_COOKIE_SAVEPASSWORD=true; EPORTAL_COOKIE_OPERATORPWD=; EPORTAL_COOKIE_NEWV=true; EPORTAL_COOKIE_PASSWORD=42ec653fc30c627c25cbd13d5dce8d55c014f6b6ee2739e43a9ab40544f37c55dd79d1d8b5cd39ebb938a796b75e03fde81487f70ff882a2ab639e2db0115a7528399c62998e4bb518a995eee677ef401bd7cb2de5778c00c767d7741dbbdcc06818cff955d9203f42555e80c44bc562a469046ee2c059ff43aa016536219785; EPORTAL_AUTO_LAND=; EPORTAL_USER_GROUP=%E7%94%B5%E5%AD%90%E7%A7%91%E5%A4%A7%E6%B8%85%E6%B0%B4%E6%B2%B3%E6%A0%A1%E5%8C%BA%E7%94%A8%E6%88%B7%E7%BB%84; EPORTAL_COOKIE_SERVER_NAME=; JSESSIONID=06FB1A96D12160A5E783BC79DB1F004C; JSESSIONID=748075FE982D90B1116C701351160002' \
#   -H 'Origin: http://172.25.249.70' \
#   -H 'Referer: http://172.25.249.70/eportal/index.jsp?userip=100.66.199.207&wlanacname=&nasip=171.88.130.251&wlanparameter=5c-02-14-ed-50-75&url=http://123.123.123.123/&userlocation=ethtrunk/2:281.405' \
#   -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36' \
#   --data-raw 'userId=19102847469&password=42ec653fc30c627c25cbd13d5dce8d55c014f6b6ee2739e43a9ab40544f37c55dd79d1d8b5cd39ebb938a796b75e03fde81487f70ff882a2ab639e2db0115a7528399c62998e4bb518a995eee677ef401bd7cb2de5778c00c767d7741dbbdcc06818cff955d9203f42555e80c44bc562a469046ee2c059ff43aa016536219785&service=&queryString=userip%253D100.66.199.207%2526wlanacname%253D%2526nasip%253D171.88.130.251%2526wlanparameter%253D5c-02-14-ed-50-75%2526url%253Dhttp%253A%252F%252F123.123.123.123%252F%2526userlocation%253Dethtrunk%252F2%253A281.405&operatorPwd=&operatorUserId=&validcode=&passwordEncrypt=true' \

# # 获取ip和mac地址
# CURRENT_IP=$(ifconfig | grep inet | grep -v inet6 | grep -v 127 | grep -v 192 | awk '{print $(NF-2)}' | cut -d ':' -f2)

# MAC_ADDRESS=$(ifconfig ra0 | grep HWaddr | awk '{print $NF}' | tr '[:upper:]' '[:lower:]' | tr ':' '-')

# # 构造动态获得ip和mac地址的cURL
# curl -X POST "http://172.25.249.70/eportal/InterFace.do?method=login" -H "Accept: */*" -H "Accept-Language: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6" -H "Connection: keep-alive" -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" -H "Cookie: EPORTAL_COOKIE_USERNAME=19102847469; EPORTAL_COOKIE_SERVER=; EPORTAL_COOKIE_DOMAIN=; EPORTAL_COOKIE_SAVEPASSWORD=true; EPORTAL_COOKIE_OPERATORPWD=; EPORTAL_COOKIE_NEWV=true; EPORTAL_COOKIE_PASSWORD=42ec653fc30c627c25cbd13d5dce8d55c014f6b6ee2739e43a9ab40544f37c55dd79d1d8b5cd39ebb938a796b75e03fde81487f70ff882a2ab639e2db0115a7528399c62998e4bb518a995eee677ef401bd7cb2de5778c00c767d7741dbbdcc06818cff955d9203f42555e80c44bc562a469046ee2c059ff43aa016536219785; EPORTAL_AUTO_LAND=; EPORTAL_USER_GROUP=%E7%94%B5%E5%AD%90%E7%A7%91%E5%A4%A7%E6%B8%85%E6%B0%B4%E6%B2%B3%E6%A0%A1%E5%8C%BA%E7%94%A8%E6%88%B7%E7%BB%84; EPORTAL_COOKIE_SERVER_NAME=; JSESSIONID=06FB1A96D12160A5E783BC79DB1F004C; JSESSIONID=748075FE982D90B1116C701351160002" -H "Origin: http://172.25.249.70" -H "Referer: http://172.25.249.70/eportal/index.jsp?userip=${CURRENT_IP}&wlanacname=&nasip=171.88.130.251&wlanparameter=${MAC_ADDRESS}&url=http://123.123.123.123/&userlocation=ethtrunk/2:281.405" -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36" --data-raw "userId=19102847469&password=42ec653fc30c627c25cbd13d5dce8d55c014f6b6ee2739e43a9ab40544f37c55dd79d1d8b5cd39ebb938a796b75e03fde81487f70ff882a2ab639e2db0115a7528399c62998e4bb518a995eee677ef401bd7cb2de5778c00c767d7741dbbdcc06818cff955d9203f42555e80c44bc562a469046ee2c059ff43aa016536219785&service=&queryString=userip%253D${CURRENT_IP}%2526wlanacname%253D%2526nasip%253D171.88.130.251%2526wlanparameter%253D${MAC_ADDRESS}%2526url%253Dhttp%253A%252F%252F123.123.123.123%252F%2526userlocation%253Dethtrunk%252F2%253A281.405&operatorPwd=&operatorUserId=&validcode=&passwordEncrypt=true"

# # 构造原本的cURL
# curl -X POST "http://172.25.249.70/eportal/InterFace.do?method=login" -H "Accept: */*" -H "Accept-Language: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6" -H "Connection: keep-alive" -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" -H "Cookie: EPORTAL_COOKIE_USERNAME=19102847469; EPORTAL_COOKIE_SERVER=; EPORTAL_COOKIE_DOMAIN=; EPORTAL_COOKIE_SAVEPASSWORD=true; EPORTAL_COOKIE_OPERATORPWD=; EPORTAL_COOKIE_NEWV=true; EPORTAL_COOKIE_PASSWORD=42ec653fc30c627c25cbd13d5dce8d55c014f6b6ee2739e43a9ab40544f37c55dd79d1d8b5cd39ebb938a796b75e03fde81487f70ff882a2ab639e2db0115a7528399c62998e4bb518a995eee677ef401bd7cb2de5778c00c767d7741dbbdcc06818cff955d9203f42555e80c44bc562a469046ee2c059ff43aa016536219785; EPORTAL_AUTO_LAND=; EPORTAL_USER_GROUP=%E7%94%B5%E5%AD%90%E7%A7%91%E5%A4%A7%E6%B8%85%E6%B0%B4%E6%B2%B3%E6%A0%A1%E5%8C%BA%E7%94%A8%E6%88%B7%E7%BB%84; EPORTAL_COOKIE_SERVER_NAME=; JSESSIONID=06FB1A96D12160A5E783BC79DB1F004C; JSESSIONID=748075FE982D90B1116C701351160002" -H "Origin: http://172.25.249.70" -H "Referer: http://172.25.249.70/eportal/index.jsp?userip=100.66.199.207&wlanacname=&nasip=171.88.130.251&wlanparameter=5c-02-14-ed-50-75&url=http://123.123.123.123/&userlocation=ethtrunk/2:281.405" -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36" --data-raw "userId=19102847469&password=42ec653fc30c627c25cbd13d5dce8d55c014f6b6ee2739e43a9ab40544f37c55dd79d1d8b5cd39ebb938a796b75e03fde81487f70ff882a2ab639e2db0115a7528399c62998e4bb518a995eee677ef401bd7cb2de5778c00c767d7741dbbdcc06818cff955d9203f42555e80c44bc562a469046ee2c059ff43aa016536219785&service=&queryString=userip%253D100.66.199.207%2526wlanacname%253D%2526nasip%253D171.88.130.251%2526wlanparameter%253D5c-02-14-ed-50-75%2526url%253Dhttp%253A%252F%252F123.123.123.123%252F%2526userlocation%253Dethtrunk%252F2%253A281.405&operatorPwd=&operatorUserId=&validcode=&passwordEncrypt=true"



# 新ip版本
# curl 'http://172.25.249.64/eportal/InterFace.do?method=login' \
#   -H 'Accept: */*' \
#   -H 'Accept-Language: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6' \
#   -H 'Connection: keep-alive' \
#   -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
#   -H 'Cookie: EPORTAL_COOKIE_OPERATORPWD=; EPORTAL_COOKIE_SERVER=; EPORTAL_AUTO_LAND=; EPORTAL_USER_GROUP=null; EPORTAL_COOKIE_USERNAME=19102847469; EPORTAL_COOKIE_DOMAIN=; EPORTAL_COOKIE_SAVEPASSWORD=true; EPORTAL_COOKIE_NEWV=true; EPORTAL_COOKIE_PASSWORD=42ec653fc30c627c25cbd13d5dce8d55c014f6b6ee2739e43a9ab40544f37c55dd79d1d8b5cd39ebb938a796b75e03fde81487f70ff882a2ab639e2db0115a7528399c62998e4bb518a995eee677ef401bd7cb2de5778c00c767d7741dbbdcc06818cff955d9203f42555e80c44bc562a469046ee2c059ff43aa016536219785; EPORTAL_COOKIE_SERVER_NAME=; JSESSIONID=27DD7149DB38C977F96261FAF8A56B7C' \
#   -H 'Origin: http://172.25.249.64' \
#   -H 'Referer: http://172.25.249.64/eportal/index.jsp?userip=100.66.199.207&wlanacname=&nasip=171.88.130.251&wlanparameter=5c-02-14-ed-50-75&url=http://123.123.123.123/&userlocation=ethtrunk/2:281.405' \
#   -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36' \
#   --data-raw 'userId=19102847469&password=42ec653fc30c627c25cbd13d5dce8d55c014f6b6ee2739e43a9ab40544f37c55dd79d1d8b5cd39ebb938a796b75e03fde81487f70ff882a2ab639e2db0115a7528399c62998e4bb518a995eee677ef401bd7cb2de5778c00c767d7741dbbdcc06818cff955d9203f42555e80c44bc562a469046ee2c059ff43aa016536219785&service=&queryString=userip%253D100.66.199.207%2526wlanacname%253D%2526nasip%253D171.88.130.251%2526wlanparameter%253D5c-02-14-ed-50-75%2526url%253Dhttp%253A%252F%252F123.123.123.123%252F%2526userlocation%253Dethtrunk%252F2%253A281.405&operatorPwd=&operatorUserId=&validcode=&passwordEncrypt=true' \
#   --insecure