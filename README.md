# AutoCampusNetAuth

为了实现校园网自动登录验证以及路由器翻墙功能，参考[这篇文章](https://blog.csdn.net/m0_66984299/article/details/133325819)和[这篇文章](https://sspai.com/post/57882)进行操作。路由器是红米AX6S，电脑用的是一台macos和一台Windows。

## 1. 给路由器刷入openwrt

参考[这位大佬的视频](https://www.youtube.com/watch?v=VkyIEuk6V5k)完成刷机，第一次刷好后发现他的固件没有openclash，但是我自己又装不上，所以又找其他教程。这个youtuber的[视频](https://www.youtube.com/watch?v=V0rZ26Rhhd4)里的固件是有openssh的，**所以最后采用他的固件**，前面的步骤和第一位一样。

### 1.1 准备工具

在**刷机要用到的固件和工具**目录中，有如下内容：

- miwifi_rb03_firmware_stable_1.2.7（内测版）测试固件，可以开启路由器telnet功能。
- MobaXterm_Portable_v23.0 工具，作用是通过telnet协议或者ssh协议登录路由器执行命令，上传openwrt固件到路由器。
- 计算root密码工具，首先在浏览器输入192.168.31.1登录路由器后台管理页面，复制首页的SN码，进入到提供的计算root密码的网站，输入SN码，计算得到密码。

- openwrt固件
  - 原版：只能有线登录，配置复杂，系统纯净
  - 新手版：做好配置的版本

在**telent命令**目录中，存放着在建立telnet连接后要执行的命令。

### 1.2 刷机过程

-  选择系统升级-手动升级，把miwifi_rb03_firmware_stable_1.2.7刷入。

  升级过程中路由器亮黄灯，升级完成变成蓝灯，此时刷新后台页面重新登录即可，这时候会发现固件版本已经变成miwifi开发版1.2.7。

- 使用MobaXterm_Portable_v23.0登录路由器，因为这个是win版软件，我这里用macos的Termius，win的Xshell应该也可以。

  因为还没有配置ssh，所以这边先用telnet协议登录。输入后台的ip进行连接，连接成功之后要输入用户名和密码。用户名是root，密码是root密码工具用sn码计算出来的密码（注意在命令行中密码一般是不显示的）。当你看到这个界面说明成功了。

  ```shell
  BusyBox v1.25.1 (2021-10-25 11:02:56 UTC) built-in shell (ash)
  
   -----------------------------------------------------
         Welcome to XiaoQiang!
   -----------------------------------------------------
    $$$$$$\  $$$$$$$\  $$$$$$$$\      $$\      $$\        $$$$$$\  $$\   $$\
   $$  __$$\ $$  __$$\ $$  _____|     $$ |     $$ |      $$  __$$\ $$ | $$  |
   $$ /  $$ |$$ |  $$ |$$ |           $$ |     $$ |      $$ /  $$ |$$ |$$  /
   $$$$$$$$ |$$$$$$$  |$$$$$\         $$ |     $$ |      $$ |  $$ |$$$$$  /
   $$  __$$ |$$  __$$< $$  __|        $$ |     $$ |      $$ |  $$ |$$  $$<
   $$ |  $$ |$$ |  $$ |$$ |           $$ |     $$ |      $$ |  $$ |$$ |\$$\
   $$ |  $$ |$$ |  $$ |$$$$$$$$\       $$$$$$$$$  |       $$$$$$  |$$ | \$$\
   \__|  \__|\__|  \__|\________|      \_________/        \______/ \__|  \__|
  
  
  root@XiaoQiang:~# 
  ```

- 执行telnet命令。可以用GPT看看都是什么作用，大概来说都是NVRAM（非易失性随机存取存储器）设置。SSH功能也开启了。

  ```shell
  nvram set ssh_en=1 && nvram set uart_en=1 && nvram set boot_wait=on && nvram set bootdelay=3 && nvram set flag_try_sys1_failed=0 && nvram set flag_try_sys2_failed=1
  
  nvram set flag_boot_rootfs=0 && nvram set "boot_fw1=run boot_rd_img;bootm"
  
  nvram set flag_boot_success=1 && nvram commit && /etc/init.d/dropbear enable && /etc/init.d/dropbear start
  ```

- 在Termius中用ssh建立连接。进入tmp目录，上传新手版固件。

  ```shell
  cd /tmp
  ```

  **最终发现Termius或者XFTP都不能用sftp协议建立连接，所以最后还是只能找了台Windows，用MobaXterm把文件上传到tmp目录。**

- 使用mtd命令刷机，第一次刷入的叫做底包。

  其中-r参数表示更新完自动重启。等待路由器黄灯变蓝灯。根据新手版的说明，刷机成功后，默认WiFi名称：Openwrt_5G ; Openwrt_2.4G 。 密码：无（但是Openwrt_2.4G好像有密码，不知道是多少）。这个固件的初始登陆ip是：192.168.6.1，用户名是：root，密码是：password。再刷入upgrade.bin文件（第二次刷入的叫升级包）可以升级系统(选择不保留配置)。升级的系统自带的功能变多了。

  ```shell
  mtd -r write /tmp/factory.bin firmware
  ```
  
  但是在这里遇到一点问题，就是刷入新系统之后安装openclash需要的依赖装不上，提示内核版本不对，还有就是ssh也出问题连不上，所以这里先考虑下一步刷回原厂系统，再重新来一次，使用前面说的另一个版本固件。


- 刷回原厂系统
  - 准备两个工具，在[官网](https://www.miwifi.com/miwifi_download.html)可以找到，分别是小米路由器修复工具和AX6S官方固件。
  - 关闭Windows防火墙和病毒保护。
  - **路由器连接网线到电脑**，根据软件提示进行操作 ，选择对应的网口，然后写入文件，然后按住复位按钮，拔掉电源再插上，直到橙灯闪烁，松开复位键即可。

## 2.配置翻墙

### 2.1 刷入的固件自带openclash

OpenClash是一个运行在 OpenWrt 上的 Clash 客户端，兼容 Shadowsocks(R)、Vmess、Trojan、Snell 等协议，根据灵活的规则配置实现策略代理。参考[这个视频](https://www.youtube.com/watch?v=_U9uXhoyaeE)进行配置。我买的订阅是是[TAGInternet](https://tagss04.pro/#/home)的。

- 选择配置文件订阅-添加

- 从机场复制订阅链接
- 修改配置文件名-粘贴订阅地址
- 保存配置-更新配置
- 插件设置-版本更新-更新内核（根据[这个](https://www.youtube.com/watch?v=bVPp9HaxDLU&t=188s)设置成功的）
- 显示主程序运行中即成功
- 如果网站访问检查里面Youtube显示无法连接，说明订阅里面没有开启对应节点而是选择的direct
  - 代理模式选择规则。
  - 打开YACD控制面板或者DashBoard控制面板，然后把selecter选择为其他结点就行了。

### 2.2 刷入的固件没有openclash（没有验证成功）

 [OpenClash](https://github.com/vernesong/OpenClash) 的官方仓库中有详细的说明文档。大致来说分为以下几个步骤：

> #安装依赖
> * luci
> * luci-base
> * iptables
> * dnsmasq-full
> * coreutils
> * coreutils-nohup
> * bash
> * curl
> * jsonfilter
> * ca-certificates
> * ipset
> * ip-full
> * iptables-mod-tproxy
> * kmod-tun(TUN模式)
> * luci-compat(Luci-19.07)
>
> #上传IPK文件至您路由器的 /tmp 目录下
>
> #假设安装包名字为
> luci-app-openclash_0.33.7-beta_all.ipk
>
> #执行安装命令
> opkg install /tmp/luci-app-openclash_0.33.7-beta_all.ipk
>
> #执行卸载命令
> #插件在卸载后会自动备份配置文件到 /tmp 目录下，除非路由器重启，在下次安装时将还原您的配置文件
> opkg remove luci-app-openclash
>
> 安装完成后刷新LUCI页面，在菜单栏 -> 服务 -> OpenClash 进入插件页面

## 3. 校园网自动登录

### 3.1 抓取登录链接

连接要实现自动登录的无线网，保持未登录状态，现在找不到。经过一次断链后发现ip地址是172.25.249.70。

以chrome浏览器为例，按F12打开开发者模式，选择network，录制，勾选preserve log，点击登录，查看抓取的内容。原文的抓取到的登录链接是get方式传输的请求，参数在url里面，我们学校的是post方法传输的request，参数在body里面，所以不能直接用抓取到的链接进行登录。

- 找到请求后，右键单击选择copy -> copy as cURL，复制到vscode里面，进行下一步处理。

  ```shell
  curl 'http://172.25.249.70/eportal/InterFace.do?method=login' \
    -H 'Accept: */*' \
    -H 'Accept-Language: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6' \
    -H 'Connection: keep-alive' \
    -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
    -H 'Cookie: EPORTAL_COOKIE_USERNAME=宽带账号; EPORTAL_COOKIE_SERVER=; EPORTAL_COOKIE_DOMAIN=; EPORTAL_COOKIE_SAVEPASSWORD=true; EPORTAL_COOKIE_OPERATORPWD=; EPORTAL_COOKIE_NEWV=true; EPORTAL_COOKIE_PASSWORD=宽带密码; EPORTAL_AUTO_LAND=; EPORTAL_USER_GROUP=%E7%94%B5%E5%AD%90%E7%A7%91%E5%A4%A7%E6%B8%85%E6%B0%B4%E6%B2%B3%E6%A0%A1%E5%8C%BA%E7%94%A8%E6%88%B7%E7%BB%84; EPORTAL_COOKIE_SERVER_NAME=; JSESSIONID=06FB1A96D12160A5E783BC79DB1F004C; JSESSIONID=748075FE982D90B1116C701351160002' \
    -H 'Origin: http://172.25.249.70' \
    -H 'Referer: http://172.25.249.70/eportal/index.jsp?userip=100.66.199.207&wlanacname=&nasip=171.88.130.251&wlanparameter=5c-02-14-ed-50-75&url=http://123.123.123.123/&userlocation=ethtrunk/2:281.405' \
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36' \
    --data-raw 'userId=宽带账号&password=宽带密码&service=&queryString=userip%253D100.66.199.207%2526wlanacname%253D%2526nasip%253D171.88.130.251%2526wlanparameter%253D5c-02-14-ed-50-75%2526url%253Dhttp%253A%252F%252F123.123.123.123%252F%2526userlocation%253Dethtrunk%252F2%253A281.405&operatorPwd=&operatorUserId=&validcode=&passwordEncrypt=true' \
    --insecure
  ```

- 用这个来构造永久使用的cURL

  - -H的部分是http request header里面的，可以进行一些修改和删除

    - 例如修改-H User-Agent可以把电脑进行伪装。例如把这个改为以下代码来伪装成Windows电脑：

      ```shell
      -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.0.0 Safari/537.36 Edg/93.0.961.0'
      ```

  - --data这里需要重点关注，根据抓到的请求，`userId=` 后是我们的宽带账号，`password=` 后是我们的宽带密码。同时，后面的 `userip%253D` 后是我们获得的内网 IP，`wlanparameter%253D` 后是我们设备的 MAC 地址。为了构造可永久使用的 cURL，首先要确保宽带账号、宽带密码是正确的。最后需要处理的，就是内网 IP 和设备 MAC 地址的问题。

- 在路由器的系统上获得内网ip：

  ```shell
  ifconfig | grep inet | grep -v inet6 | grep -v 127 | grep -v 192 | awk '{print $(NF-2)}' | cut -d ':' -f2
  ```

- 在路由器的系统上获得mac地址：

  ```shell
  ifconfig ra0 | grep HWaddr | awk '{print $NF}' | tr '[:upper:]' '[:lower:]' | tr ':' '-'
  ```

- 构造请求

  ```shell
  CURRENT_IP=$(ifconfig | grep inet | grep -v inet6 | grep -v 127 | grep -v 192 | awk '{print $(NF-2)}' | cut -d ':' -f2)
  
  MAC_ADDRESS=$(ifconfig ra0 | grep HWaddr | awk '{print $NF}' | tr '[:upper:]' '[:lower:]' | tr ':' '-')
  
  curl -X POST "http://172.25.249.70/eportal/InterFace.do?method=login" -H "Accept: */*" -H "Accept-Language: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6" -H "Connection: keep-alive" -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" -H "Cookie: EPORTAL_COOKIE_USERNAME=宽带账号; EPORTAL_COOKIE_SERVER=; EPORTAL_COOKIE_DOMAIN=; EPORTAL_COOKIE_SAVEPASSWORD=true; EPORTAL_COOKIE_OPERATORPWD=; EPORTAL_COOKIE_NEWV=true; EPORTAL_COOKIE_PASSWORD=宽带密码; EPORTAL_AUTO_LAND=; EPORTAL_USER_GROUP=%E7%94%B5%E5%AD%90%E7%A7%91%E5%A4%A7%E6%B8%85%E6%B0%B4%E6%B2%B3%E6%A0%A1%E5%8C%BA%E7%94%A8%E6%88%B7%E7%BB%84; EPORTAL_COOKIE_SERVER_NAME=; JSESSIONID=06FB1A96D12160A5E783BC79DB1F004C; JSESSIONID=748075FE982D90B1116C701351160002" -H "Origin: http://172.25.249.70" -H "Referer: http://172.25.249.70/eportal/index.jsp?userip=${CURRENT_IP}&wlanacname=&nasip=171.88.130.251&wlanparameter=${MAC_ADDRESS}&url=http://123.123.123.123/&userlocation=ethtrunk/2:281.405" -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36" --data-raw "userId=宽带账号&password=宽带密码&service=&queryString=userip%253D${CURRENT_IP}%2526wlanacname%253D%2526nasip%253D171.88.130.251%2526wlanparameter%253D${MAC_ADDRESS}%2526url%253Dhttp%253A%252F%252F123.123.123.123%252F%2526userlocation%253Dethtrunk%252F2%253A281.405&operatorPwd=&operatorUserId=&validcode=&passwordEncrypt=true"
  ```

  在这里，我们用变量 `CURRENT_IP` 存储获得的内网 IP，用变量 `MAC_ADDRESS` 存储获得的 MAC 地址，并在 curl 命令中进行了替换。需要注意的是，要在 bash 命令的引号中使用变量的话，引号必须为**双引号**，而不能采用由 Chrome 复制得来的单引号。

- 测试

  先断开认证，再进行测试

  打开mac终端，输入上面构造的三条命令。在mac上进行测试的时候没有成功。显示：

  ```shell
  {"userIndex":null,"result":"fail","message":"设备未注册,请在ePortal上添加认证设备","forwordurl":null,"keepaliveInterval":0,"validCodeUrl":""}%  
  ```

  应该是获取的ip和mac地址有问题，如果我不用动态获取的而是用原本的cURL里面的ip和mac地址就可以，不知道为什么。

  在openwrt上测试一下，成功，所以应该就是抓取的问题：

  ```shell
  {"userIndex":"38396661336264646362666631666631626434656438646638656535353832335f3130302e36362e3139392e3230375f3139313032383437343639","result":"success","message":"","forwordurl":null,"keepaliveInterval":0,"validCodeUrl":""}
  ```

> ### 测试链接是否可用（get方法的request）
>
> 先退出认证账号，使网络不可用，
>
> 键盘按住win+r键 输入cmd 回车 在弹出的命令窗口中输入curl 链接 回车 如果网络恢复链接，则说明连接可用，可以进行下一步

### 3.2 两种自动登录实现思路

- 一是将设置自动登陆脚本，并设置为开机自动执行，这样再给路由器设置定时重启任务，路由器会在重启后自动登录网页。该方案适用于固定时间掉线的网络环境，例如有的单位是每天晚上1点自动掉线，这种方案比较简单好用。参见第3.3部分。
- 第二种思路是每隔一段时间检测网络是否掉线，掉线了就自动执行登陆脚本，这种方案更加灵活。参见第3.4部分。

### 3.3 定时重启自动登录网页认证功能（get方法的http request，未测试）

#### 3.3.1 使用ssh连接路由器

这里使用的Termius，还是ip为：192.168.6.1，用户名：root，密码：password。

#### 3.3.2 写入脚本

```shell
mkdir autologin
cd autologin
vi autologin.sh
```

输入i进入编辑模式，然后输入 curl "链接"。按esc，然后输入“:wq”保存并退出。

输入 sh autologin.sh 测试是否成功（先退出网页登陆，运行改步骤后网络恢复则说明脚本没有问题，如果出现 curl not found，需要将路由器连接外网后在openwrt中搜索安装curl，或者在ssh下依次输入 opkg update 和 opkg install curl）

#### 3.3.3 设置开机启动

在路由器的启动任务中输入 sh root/autologin/autologin.sh,如下图所示，这样路由器每次重启就会自动登录。

#### 3.3.4 设置路由器自动重启
在Scheduled Tasks中加入如下代码即可实现每天5：10分重启路由器，有其他的需求的搜索“corn语法”，根据说明进行修改。

```shell
10 5 * * * sleep 70 && touch /etc/banner && reboot   //每天5点10分路由器自动重启
```

保存上述脚本后，注意在启动项里重启一下corn，或者直接重启一下路由器，在重启路由器之前注意检查路由器时区是否正确，如果时区不正确还需要手动修改时区到亚洲/上海。

至此路由器即实现了每天五点十分重启，并且重启后自动登录网页认证。

### 3.4 自动检测并登录功能（post方法的http request， 成功）

#### 3.4.1 使用ssh连接路由器

这里使用的Termius，还是ip为：192.168.6.1，用户名：root，密码：password。

```shell
┌─────────────────────────────────────────────┐
│                                             │
│ mmmmm                         m       ""#   │
│   #   mmmmm mmmmm  mmm  mmm mm#mm  mmm  #   │
│   #   # # # # # # #" "# #" "  #   "   # #   │
│   #   # # # # # # #   # #     #   m"""# #   │
│ mm#mm # # # # # # "#m#" #     "mm "mm"# "mm │
│                                             │
│─────────────────────────────────────────────│
│              ImmortalWrt 18.06              │
└─────────────────────────────────────────────┘
```

#### 3.4.2 创建脚本

**sh脚本（shell script）是一种使用shell命令编写的脚本文件，适用于Unix/Linux系统，包括OpenWrt。**

脚本的流程为，具体实现看仓库里的ping.sh：

1. 初始化网络检测次数、等待时间、重登录尝试次数和日志路径。
2. 定义`check_network`函数，用于ping检测网络是否正常。
3. 定义`log`函数，用于记录日志信息。
4. 定义`perform_login`函数，用于执行网络登录操作。
5. 进入无限循环，循环体内：
   - 使用`check_network`检查网络状态。
   - 如果网络正常，记录日志并退出循环。
   - 如果网络异常，增加ping尝试计数，并在达到设定次数后尝试重新登录。
   - 如果重新登录尝试达到限制次数网络仍未恢复，执行设备重启操作。
6. 循环中每隔设定的等待时间再次检查网络状态。

#### 3.4.3 上传登录脚本到路由器

```shell
root@ImmortalWrt:~# mkdir ping
root@ImmortalWrt:~# cd ping
root@ImmortalWrt:~/ping# vi ping.sh
```

把代码复制进去然后esc，:wq退出

#### 3.4.4 测试脚本是否正常

可以输入 sh ping.sh 测试是否成功（先退出网页登陆，运行该步骤后网络恢复则说明脚本没有问题，如果出现 curl not found，需要将路由器连接外网后在openwrt中搜索安装curl，或者在ssh下依次输入 opkg update 和 opkg install curl）

结果成功！

```shell
root@ImmortalWrt:~/ping# sh ping.sh
-> [1/3] Network maybe disconnected, checking again after 10 seconds!
-> [2/3] Network maybe disconnected, checking again after 10 seconds!
-> [3/3] Network maybe disconnected, checking again after 10 seconds!
try to re-login
{"userIndex":"38396661336264646362666631666631626434656438646638656535353832335f3130302e36362e3139392e3230375f3139313032383437343639","result":"success","message":"","forwordurl":null,"keepaliveInterval":0,"validCodeUrl":""}登录成功
network is ok
root@ImmortalWrt:~/ping# 
```

给脚本增加执行权限

```shell
root@ImmortalWrt:~/ping# ls -l ping.sh 
-rw-r--r--    1 root     root          4135 Aug  4 00:27 ping.sh
root@ImmortalWrt:~/ping# chmod +x ping.sh 
root@ImmortalWrt:~/ping# ls -l ping.sh 
-rwxr-xr-x    1 root     root          4135 Aug  4 00:27 ping.sh
root@ImmortalWrt:~/ping# 
```

#### 3.4.5 设置定时任务

**计划任务（Corn）是 Unix 和 类Unix 系统中一个常见的功能，用于设置周期性的被执行的命令。**

计划任务的每个任务被存储在`corntab`文件中。在正常的 Linux 系统下，每个用户对应一 corntab 个文件，还有一个针对整个系统的 corntab 文件。不过在 OpenWrt，只有针对于整个系统的 corntab 文件，位于`/etc/corntab/root`。

```shell
root@ImmortalWrt:~/ping# cd /etc
root@ImmortalWrt:/etc# cd crontabs/
root@ImmortalWrt:/etc/crontabs# ls
cron.update  root
root@ImmortalWrt:/etc/crontabs# vi root 
```

在这个文件里面添加计划，表示20分钟检查一次：

```shell
*/20 * * * * /root/ping/ping.sh
```

具体参数含义为：

- `*/20` 表示每20分钟。
- `*` 表示每小时的每个分钟。
- `*` 表示每天的每个小时。
- `*` 表示每月的每天。
- `*` 表示每周的每一天。

`/root/ping/ping.sh`是你的脚本实际存放的路径。确保替换成你的脚本实际路径。

其他设置方法可以用[这个网站](https://crontab.guru/)来设置。

然后需要重新启动corn服务：

- 打开路由器的后台，选择 系统-计划任务，看到刚才写的任务在这里出现。

- 选择系统-启动项
- 找到corn，点击重启，即可完成

#### 3.4.6 测试定时任务是否正常

先把任务改成每两分钟执行一次，然后断开网络认证，进行测试，结果没有问题：

```shell
2024-08-04 01:04:00network is ok
2024-08-04 01:06:02-> [1/3] Network maybe disconnected, checking again after 10 seconds!
2024-08-04 01:06:14-> [2/3] Network maybe disconnected, checking again after 10 seconds!
2024-08-04 01:06:26-> [3/3] Network maybe disconnected, checking again after 10 seconds!
2024-08-04 01:06:26try to re-login
2024-08-04 01:06:27............
2024-08-04 01:06:45network is ok
2024-08-04 01:08:00network is ok
2024-08-04 01:10:00network is ok
2024-08-04 01:12:00network is ok
2024-08-04 01:14:00network is ok
```

再把任务定时改回20分钟，进行测试：

```shell
2024-08-04 01:14:00network is ok
2024-08-04 01:20:00network is ok
2024-08-04 01:40:00network is ok
```

经过测试并没有问题

至此已经实现了路由器自动登录网页认证的功能！！