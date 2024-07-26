# AutoCampusNetAuth

为了实现校园网自动登录验证以及路由器翻墙功能，参考[这篇文章](https://blog.csdn.net/m0_66984299/article/details/133325819)进行操作。路由器是红米AX6S，电脑用的是macos。

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

  其中-r参数表示更新完自动重启。等待路由器黄灯变蓝灯。根据新手版的说明，刷机成功后，默认WiFi名称：Openwrt_5G ; Openwrt_2.4G 。 密码：无（但是Openwrt_2.4G好像有密码，不知道是多少）。这个固件的初始登陆ip是：192.168.6.1，密码是：password。再刷入upgrade.bin文件（第二次刷入的叫升级包）可以升级系统(选择不保留配置)。升级的系统自带的功能变多了。

  ```shell
  mtd -r write /tmp/factory.bin firmware
  ```
  
  但是在这里遇到一点问题，就是刷入新系统之后安装openclash需要的依赖装不上，提示内核版本不对，还有就是ssh也出问题连不上，所以这里先考虑下一步刷回原厂系统，再重新来一次，使用前面说的另一个版本固件。


- 刷回原厂系统
  - 准备两个工具，在[官网](https://www.miwifi.com/miwifi_download.html)可以找到，分别是小米路由器修复工具和AX6S官方固件。
  - 关闭Windows防火墙和病毒保护。
  - **路由器连接网线到电脑**，根据软件提示进行操作 ，选择对应的网口，然后写入文件，然后按住复位按钮，拔掉电源再插上，直到橙灯闪烁，松开复位键即可。

## 2.配置翻墙

OpenClash是一个运行在 OpenWrt 上的 Clash 客户端，兼容 Shadowsocks(R)、Vmess、Trojan、Snell 等协议，根据灵活的规则配置实现策略代理。参考[这个视频](https://www.youtube.com/watch?v=_U9uXhoyaeE)进行配置。我买的订阅是是[TAGInternet](https://tagss04.pro/#/home)的。

- 选择配置文件订阅-添加

- 从机场复制订阅链接
- 修改配置文件名-粘贴订阅地址
- 保存配置-更新配置
- 插件设置-版本更新-更新内核
- 显示主程序运行中即成功
- 如果网站访问检查里面Youtube显示无法连接，说明订阅里面没有开启对应节点而是选择的direct
  - 代理模式选择规则。
  - 打开YACD控制面板或者DashBoard控制面板，然后把selecter选择为其他结点就行了。