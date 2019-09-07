#!/bin/sh
#作  者： xiaoxx
#用  途： 通过温度检测自动控制Jetson nano PWM风扇转速
#博  客： xiaoxx.cc
#参  照： https://github.com/tankririri/RaspberryPi_CPU_PWM

if [ -n "$1" ] ;then
CONF=$1
else
CONF=/home/ljp/.cpu-fan.conf
fi
LOG=/var/log/cpu-fan/cpu-fan.log

#开机风扇全速运行
#默认的pwm值范围是0~255
echo 255 > /sys/devices/pwm-fan/target_pwm


#初始化参数
fan=0

while true
  do
  #获取cpu温度
  tmp=`cat /sys/class/thermal/thermal_zone0/temp`
  load=`cat /proc/loadavg | awk '{print $1}'`

  #读取配置
  while read line; do
	name=`echo $line | awk -F '=' '{print $1}'`
	value=`echo $line | awk -F '=' '{print $2}'`
	case $name in
	"MODE")
	MODE=$value
	;;
	"set_temp_min")
	set_temp_min=$value
	;;
	"shutdown_temp")
	shutdown_temp=$value
	;;
	"set_temp_max")
	set_temp_max=$value
	;;
	*)
	;;
	esac
  done < $CONF
  
  #计算pwm值，从变量set_temp_min设置的温度开始开启风扇，最低转速50%
  pwm=$((($tmp-$set_temp_min)*128/($set_temp_max-$set_temp_min)+60))
  if [ $pwm -le 60 ] ;then
  pwm=60
  fi

  #设置pwm值上限
  if [ $pwm -gt 255 ] ;then
  pwm=255
  fi
    
  #第一次超过设置温度全速开启风扇，防止风扇不能启动
  if [ $tmp -gt $set_temp_min ] && [ $fan -eq 0 ] && [ $MODE -eq 2 ] ;then
  echo 255 > /sys/devices/pwm-fan/target_pwm
  fan=1
  echo "`date` temp=$tmp pwm=1023 MODE=$MODE CPU load=$load 第一次超过设置温度全速开启风扇" >> $LOG
  sleep 1
  fi
 
  #小于设置温度关闭风扇
if [ $fan -eq 0 ] ;then
  pwm=0
  fi
  if [ $tmp -le $shutdown_temp ] && [ $MODE -eq 2 ] ;then
  pwm=0
  fan=0
  echo $pwm > /sys/devices/pwm-fan/target_pwm
  echo "`date` temp=$tmp pwm=$pwm MODE=$MODE CPU load=$load 小于设置温度关闭风扇 " >> $LOG
  sleep 5
else

  #检查MODE，为0时关闭风扇
  if [ $MODE -eq 0 ] ;then
  pwm=0
  fan=0
  else
  
  #检查MODE，为1时持续开启风扇最高转速
  if [ $MODE -eq 1 ] ;then
  pwm=255
  fan=1
  fi
  fi

  echo $pwm > /sys/devices/pwm-fan/target_pwm
    
loadavg=`cat /proc/loadavg`
awk=`cat /proc/loadavg | awk '{print $0}'`
  echo "`date` temp=$tmp pwm=$pwm load=$load "
  #每5秒钟检查一次温度
  sleep 5

fi
done
