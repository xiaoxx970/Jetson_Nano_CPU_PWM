# Jetson_Nano_CPU_PWM
Jetson Nano using software PWM to control the CPU fan speed.  
使用软件PWM控制Jetson Nano CPU风扇转速。

创建`cpu-fan.service`文件在`/etc/systemd/system/`下：
```sh
[Unit]
Description=Service to run cpu-fan contorol in system space

[Service]
ExecStart=/bin/bash -c "/脚本的/目录/cpu-fan.sh"

[Install]
WantedBy=default.target
```