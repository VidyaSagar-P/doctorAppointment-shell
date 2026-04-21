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
        exit 1
    else
        echo -e "$2.. is $G success $N" | tee -a $LOG_FILE
    fi
}

echo "Script started executing at: $(date)" | tee -a $LOG_FILE

CHECK_ROOT

dnf list installed nginx &>> $LOG_FILE
if [ $? -ne 0 ]
then
    echo -e "Nginx is not installed..$Y Going to install $N"
    dnf install nginx -y &>> $LOG_FILE
    VALIDATE $? "Installing nginx"
else   
    echo -e "Nginx is already $Y installed $N"
fi

systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "Enable Nginx"

systemctl start nginx &>>$LOG_FILE
VALIDATE $? "Start Nginx"

rm -rf /usr/share/nginx/html/*

curl -o /tmp/doctor-appointment.zip https://jyo1994-vs-workspace.s3.us-east-1.amazonaws.com/doctorAppointment-index.zip
cd /usr/share/nginx/html
unzip /tmp/doctor-appointment.zip &>>$LOG_FILE
VALIDATE $? "Extract frontend code"

cp /home/ec2-user/doctorAppointment-shell/doctor.conf /etc/nginx/default.d/doctor.conf
VALIDATE $? "Copied doctor conf" 

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarted nginx"
