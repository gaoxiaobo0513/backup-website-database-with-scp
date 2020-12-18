# 网站+数据库scp远程备份脚本

### WEB 服务器自动备份脚本 （Shell）  

本脚本仅在CentOS 7 x64测试通过

## 使用示例

```bash
./backup.sh -w /usr/local/nginx/www/baidu.com -h 123.123.123.123 -t /data/backups/baidu.com/ -u bak -p 123456 -U root -P 123456 -n db_baidu
```



## 参数说明

```shell
#web根目录
-w 

#备份服务器地址
-h

#[可选]备份服务器ssh端口号，默认22端口
-a

#备份服务器备份路径
-t

#备份服务器用户
-u

#[可选]数据库地址，默认localhost
-H

#[可选]数据库端口号，默认3306
-b

#数据库用户
-U

#数据库密码
-P

#需要备份的数据库名
-n
```



## 使用说明

本备份脚本会在当前用户目录下生成web-bak文件夹作为备份临时目录，成功将备份文件scp到目标备份服务器后会删除本地备份，如果由于某些原因导致未能成功scp则不会删除本地备份，如网络断开、用户名密码错误等。

###  1、安装必备组件

```bash
yum -y install expect wget
```

### 2、下载脚本至服务器

```bash
wget https://raw.githubusercontent.com/gaoxiaobo0513/backup-website-database-with-scp/master/backup.sh

chmod +x backup.sh
```

### 3、添加至定时任务

```bash
vi /etc/crontab 
#每天凌晨两点自动备份，脚本运行路径、日志路径、脚本参数请自行修改
0 2 * * * root source /etc/profile && /usr/local/src/bak/backup.sh -w /usr/local/nginx/www/baidu.com -h 123.123.123.123 -t /data/backups/baidu.com/ -u bak -p 123456 -U root -P 123456 -n db_baidu > /usr/local/src/backup/backup-cron.log  2>&1 &
```

