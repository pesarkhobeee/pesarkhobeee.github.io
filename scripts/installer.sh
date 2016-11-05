#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OS="$(cat /etc/issue)"
OSVERSION="$(cat /etc/os-release | grep VERSION_ID | sed  's/VERSION_ID="//g' | sed  's/"//g')"

echo "Welcome to Installer, Your OS is : " $OS
echo "Warning : If you are using ubuntu please pay attention to that version, if your version is lower than 15.04 your system use UpStart else it uses SystemD"
echo $OSVERSION

echo -n "Enter your startup system [upstart|systemd] :"
read  STARTUPSYSTEM



read -d '' SYSTEMD <<- EOF
***********************************************************************************
********************************* crontab section *********************************
***********************************************************************************
Please write below line to root's crontab
* * * * *  $DIR/sinic_firewall.sh watch

***********************************************************************************
***************************** start up script section *****************************
***********************************************************************************
Please write below lines in /etc/systemd/system/sinicFirewall.service
and then please enter this command in root console:
systemctl start sinicFirewall.service
systemctl enable sinicFirewall.service

************************************************************************************
***************************** this is the file content *****************************
************************************************************************************
[Unit]
Description=Sinic Firewall service
After=network.target

[Service]
User=root
Group=root
ExecStart=$DIR/sinic_firewall.sh  start

[Install]
WantedBy=multi-user.target
EOF


read -d '' UPSTART <<- EOF
***********************************************************************************
********************************* crontab section *********************************
***********************************************************************************
Please write below line to root's crontab
* * * * *  $DIR/sinic_firewall.sh watch

***********************************************************************************
***************************** start up script section *****************************
***********************************************************************************
Please write below lines in /etc/init/sinicFirewall.conf
and then please enter this command in root console:
service testjob start sinicFirewall
************************************************************************************
***************************** this is the file content *****************************
************************************************************************************

description "Sinic Firewall service"
author      "Farid Ahmadian"

start on filesystem or runlevel [2345]
stop on shutdown

script

    export HOME="/srv"
    exec $DIR/sinic_firewall.sh  start

end script

pre-start script
    echo "$ (date) Sinic Firewall Starting" >> /var/log/sinic_firewall.log
end script

pre-stop script
    echo "$ (date) Sinic Firewall Starting" >> /var/log/sinic_firewall.log
end script
EOF

if [ $STARTUPSYSTEM == "systemd" ]
then
    echo "$SYSTEMD"
else
    echo "$UPSTART"
fi
