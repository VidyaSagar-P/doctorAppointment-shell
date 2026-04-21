#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/doctor-appointment"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIME_STAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME-$TIME_STAMP.log"

mkdir -p $LOG_FOLDER

USERID=$(id -u)

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo -e "Please proceed with the $Y root privileges..$N" 
        exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2.. is $R failed $N" | tee -a $LOG_FILE
    else
        echo -e "$2.. is $G success $N" | tee -a $LOG_FILE
    fi
}

echo "Script started executing at: $(date)" | tee -a $LOG_FILE

CHECK_ROOT

mkdir -p $LOG_FOLDER

dnf list installed mysql &>> $LOG_FILE
if [ $? -ne 0 ]
then
    echo -e "Mysql is not installed.$Y Going to install..$N" | tee -a $LOG_FILE
    dnf install mysql-server -y &>> LOG_FILE 
    VALIDATE $? "Installing mysql server" | tee -a $LOG_FILE
else
    echo -e "Mysql is already $G installed $N" | tee -a $LOG_FILE
fi

systemctl enable mysqld &>> LOG_FILE
VALIDATE $? "Enabled mysql server"

systemctl start mysqld &>> LOG_FILE
VALIDATE $? "Started mysql server"

mysql -h doctor-mysqld.bavs.space -uroot -pDoctor@1 -e "show databases;" &>> LOG_FILE
if [ $? -ne 0 ]
then
    echo -e "Mysql root password not configured, setting now" | tee -a $LOG_FILE
    mysql_secure_installation --set-root-pass Doctor@1
else
    echo -e "Mysql root password already configured..$Y SKIPPING $N" | tee -a $LOG_FILE
fi
