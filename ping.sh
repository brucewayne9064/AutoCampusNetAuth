# ping 的总次数
PING_SUM=3

# ping 的间隔时间，单位秒
SLEEP_SEC=10

# 连续重启网卡 REBOOT_CNT 次网络都没有恢复正常，重启软路由
# 时间= (SLEEP_SEC * PING_SUM + 20) * REBOOT_CNT
REBOOT_CNT = 3

LOG_PATH="/root/ping/log.txt"  # 日志位置
cnt=0  # ping的次数
reboot_cnt=0

# 登录请求的URL和表单数据
LOGIN_URL="http://172.25.249.70/eportal/InterFace.do?method=login"
USER_ID="19102847469"
PASSWORD="42ec653fc30c627c25cbd13d5dce8d55c014f6b6ee2739e43a9ab40544f37c55dd79d1d8b5cd39ebb938a796b75e03fde81487f70ff882a2ab639e2db0115a7528399c62998e4bb518a995eee677ef401bd7cb2de5778c00c767d7741dbbdcc06818cff955d9203f42555e80c44bc562a469046ee2c059ff43aa016536219785"
SERVICE=""
QUERY_STRING="userip%3D100.66.199.207%26wlanacname%3D%26nasip%3D171.88.130.251%26wlanparameter%3D5c-02-14-ed-50-75%26url%3Dhttp%3A%2F%2F123.123.123.123%2F%26userlocation%3Dethtrunk%2F2%3A281.405"
OPERATOR_PWD=""
OPERATOR_USER_ID=""
VALIDCODE=""
PASSWORD_ENCRYPT="true"

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
    curl -s -d "method=login&userId=$USER_ID&password=$PASSWORD&service=$SERVICE&queryString=$QUERY_STRING&operatorPwd=$OPERATOR_PWD&operatorUserId=$OPERATOR_USER_ID&validcode=$VALIDCODE&passwordEncrypt=$PASSWORD_ENCRYPT" "$LOGIN_URL" > /dev/null
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