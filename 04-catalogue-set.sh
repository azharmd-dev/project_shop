#!/bin/bash

set -euo pipefail

trap 'echo "There is an error in $LINENO, Command is: $BASH_COMMAND"' ERR

Userid=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

Logs_Folder="/var/log/shell-roboshop"
Script_Name=$( echo $0 | cut -d "." -f1 )
Script_Dir=$PWD
MONGODB_HOST=mongodb.azharprojects.site
Log_File="$Logs_Folder/$Script_Name.log"

mkdir -p $Logs_Folder
echo "Script started executed at: $(date)" | tee -a $Log_File

if [ $Userid -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1
fi

##### NodeJS ####
dnf module disable nodejs -y &>>$Log_File
dnf module enable nodejs:20 -y  &>>$Log_File
dnf install nodejs -y &>>$Log_File
echo -e "Installing NodeJS 20 ... $G SUCCESS $N"

id roboshop &>>$Log_File
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$Log_File
else
    echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir -p /app
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$Log_File
cd /app 
rm -rf /app/*
unzip /tmp/catalogue.zip &>>$Log_File
npm install &>>$Log_File
cp $Script_Dir/catalogue.service /etc/systemd/system/catalogue.service
systemctl daemon-reload
systemctl enable catalogue &>>$Log_File
echo -e "Catalogue application setup ... $G SUCCESS $N"

cp $Script_Dir/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$Log_File

INDEX=$(mongosh mongodb.azharprojects.site --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$Log_File
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue
echo -e "Loading products and restarting catalogue ... $G SUCCESS $N"