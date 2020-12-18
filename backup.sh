#!/bin/bash
# **********************************************************
# * Author        : gaoxiaobo
# * Email         : 382577804@qq.com
# * Description   : 网站+数据库scp备份脚本
# **********************************************************

function error_exit {
  echo "$1" 1>&2
  exit 1
}

tmp_dir=~/web-bak
#获取参数
while getopts w:h:t:u:p:a:U:H:P:b:n: OPT; do
  case ${OPT} in
    w) web_dir=${OPTARG}
       ;;
    h) target_host=${OPTARG}
       ;;
    t) target_dir=${OPTARG}
       ;;
    u) target_user=${OPTARG}
       ;;
    p) target_passwd=${OPTARG}
       ;;
    a) target_port=${OPTARG}
       ;;
    U) db_user=${OPTARG}
       ;;
    H) db_host=${OPTARG}
       ;;
    P) db_passwd=${OPTARG}
       ;;
    b) db_port=${OPTARG}
       ;;
    n) db_database=${OPTARG}
       ;;
    \?)
       printf "[Usage] `date '+%F %T'` 
       -w <WEB_ROOT_DIRECTORY> 
       -h <TARGET_HOST> 
       -a <TARGET_HOST_PORT>
       -t <TARGET_DIRECTORY> 
       -u <TARGET_HOST_USERNAME> 
       -p <TARGET_HOST_PASSWORD>
       -H <DATABASE_HOST>
       -b <DATABASE_PORT>
       -U <DATABASE_USER>
       -P <DATABASE_PASSWORD>
       -n <DATABASE_NAME>
        \n" >&2
       exit 1
  esac
done

# 必填参数校验
if [ -z "${web_dir}" -o -z "${target_host}" -o -z "${target_dir}" -o -z "${target_user}" -o -z "${target_passwd}" -o -z "${db_user}" -o -z "${db_passwd}" -o -z "${db_database}" ]; then
    printf "[ERROR] `date '+%F %T'` following parameters is empty:\n-w=${web_dir}\n-th=${target_host}\n-td=${target_dir}\n-tu=${target_user}\n-tp=${target_passwd}\n-ud=${db_user}\n-up=${db_passwd}\n-dn=${db_database}\n"
    exit 1
fi

if [ ! -d $tmp_dir ]; then
  mkdir -p $tmp_dir
fi

if [ -z "$target_port" ]; then
  target_port='22'
fi

if [ -z "$db_port" ]; then
  db_port='3306'
fi

if [ -z "$db_host" ]; then
  db_host='localhost'
fi

if [ ! -d $web_dir ]; then
  echo '备份目录不存在！' 1>&2
  exit 1
fi

cd $web_dir
parent_path=$(dirname "$PWD") 
project_path=$(cd `dirname $0`; pwd)
project_name="${project_path##*/}"
sql_file_name=db_${project_name}_`date +%Y%m%d%H%M%S`.tar.gz
web_file_name=${project_name}_`date +%Y%m%d%H%M%S`.tar.gz

#数据库备份
type mysqldump >/dev/null 2>&1 || error_exit "mysqldump未安装" 

mysqldump --opt -u$db_user -p$db_passwd -h$db_host -P$db_port $db_database > $tmp_dir/$db_database.sql || error_exit "dump数据库失败" 

cd $tmp_dir

tar -zcvf $sql_file_name  ${db_database}.sql
expect -c "
    spawn scp -P "$target_port" -r "${tmp_dir}/${sql_file_name}" "${target_user}"@"${target_host}":"${target_dir}" 
    expect {
            \"*assword\" {set timeout 36000; send \""${target_passwd}"\r\";exp_continue;}
            \"*again\" {set timeout 36000; send \""${target_passwd}"\r\"; exp_continue}
            \"yes/no\" {send \"yes\n\"; exp_continue;}
            \"lost connection\" {exit 1}
            \"Is a directory\" {exit 1}
        }
    expect eof" 

if [ $? -ne 0 ]; then
    echo "[ERROR] 数据库备份文件传输失败" 1>&2
else
    echo ">>>>数据库备份文件传输成功" 1>&2
    rm -rf ${tmp_dir}/${sql_file_name} $tmp_dir/$db_database.sql
fi


#网站备份
tar -C $parent_path  -zcvf ${tmp_dir}/${web_file_name} ${project_name} || error_exit "网站目录打包失败" 

#scp网站tar包
expect -c "
    spawn scp -P "$target_port" -r "${tmp_dir}/${web_file_name}" "${target_user}"@"${target_host}":"${target_dir}" 
    expect {
            \"*assword\" {set timeout 36000; send \""${target_passwd}"\r\";exp_continue;}
            \"*again\" {set timeout 36000; send \""${target_passwd}"\r\"; exp_continue;}
            \"yes/no\" {send \"yes\n\"; exp_continue;}
            \"lost connection\" {exit 1}
            \"Is a directory\" {exit 1}
        }
expect eof" 

if [ $? -ne 0 ]; then
    echo "[ERROR] 网站备份文件传输失败" 1>&2
else
    echo "网站备份文件传输成功" 1>&2
    rm -rf ${tmp_dir}/${web_file_name}
fi


echo `date '+%F %T'`" 备份成功"