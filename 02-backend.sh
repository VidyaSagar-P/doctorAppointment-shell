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

dnf list installed maven &>> $LOG_FILE
if [ $? -ne 0 ]
then
    echo -e "maven is not installed.$Y Going to install..$N" | tee -a $LOG_FILE
    dnf install maven -y &>> LOG_FILE 
    VALIDATE $? "Installing maven" | tee -a $LOG_FILE
else
    echo -e "maven is already $G installed $N" | tee -a $LOG_FILE
fi

id doctor &>> $LOG_FILE
if [ $? -ne 0 ]
then
    echo -e "User::doctor not available..$Y creating now $N"
    useradd --system --home /app --shell /sbin/nologin --comment "doctor system user" doctor
    VALIDATE $? "User creationn"
else
    echo -e "User::doctor as already created $G SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating /app directory"

curl -L -o /tmp/doctorapp.zip https://jyo1994-vs-workspace.s3.us-east-1.amazonaws.com/hospital-be.zip &>> LOG_FILE
VALIDATE $? "Downloading backend application code"

cd /app
rm -rf /app/*
unzip /tmp/doctorapp.zip &>> LOG_FILE
VALIDATE $? "Extracting code"

cp /home/ec2-user/doctorAppointment-shell/doctor.service /etc/systemd/system/doctor.service
VALIDATE $? "Copied"

# load the data before running backend
dnf list installed mysql &>> $LOG_FILE
if [ $? -ne 0 ]
then
    echo -e "Mysql is not installed.$Y Going to install..$N" | tee -a $LOG_FILE
    dnf install mysql-server -y &>> LOG_FILE 
    VALIDATE $? "Installing mysql server" | tee -a $LOG_FILE
else
    echo -e "Mysql is already $G installed $N" | tee -a $LOG_FILE
fi

mysql -h doctor-mysqld.bavs.space -uroot -pDoctor@1 < /app/db/app-user.db
VALIDATE $? "Schema loading"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable doctor &>>$LOG_FILE
VALIDATE $? "Enabled backend"

systemctl restart doctor &>>$LOG_FILE
VALIDATE $? "Restarted Backend"