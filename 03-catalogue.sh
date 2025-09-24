#!/bin/bash

Userid=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

Logs_Folder="/var/log/shell-script" #Logs will be stored in this directory
Script_Name=$(echo $0 | cut -d "." -f1)
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.azharprojects.site
Log_File="$Logs_Folder/$Script_Name.log" 
#Log will be saved with the file name as /var/log/shell-script/02-mongodb.log

mkdir -p $Logs_Folder 
echo "Scrpit execution started at $(date)::" | tee -a $Log_File

if [ $Userid -ne 0 ]; then
    echo -e "User required root access"
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $Log_File
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $Log_File
    fi
}

#Installation of NodeJS

dnf module disable nodejs -y &>>$Log_File
VALIDATE $? "Disabling NodeJS deafult version"

dnf module enable nodejs:20 -y &>>$Log_File
VALIDATE $? "Enabling NodeJS version 20"

dnf install nodejs -y &>>$Log_File
VALIDATE $? "Installing NogdeJS"

id roboshop &>>$Log_File
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$Log_File
    VALIDATE $? "Creating System User"
else
    echo -e "user already exits .. $Y SKIPPING$n"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$Log_File
VALIDATE $? "Downloading catalogue application"

cd /app 
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/catalogue.zip &>>$Log_File
VALIDATE $? "unzip catalogue"

npm install &>>$Log_File
VALIDATE $? "Install dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copy systemctl service"

echo "$SCRIPT_DIR/catalogue.service"

systemctl daemon-reload
systemctl enable catalogue &>>$Log_File
VALIDATE $? "Enable catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy mongo repo"

dnf install mongodb-mongosh -y &>>$Log_File
VALIDATE $? "Install MongoDB client"

INDEX=$(mongosh mongodb.daws86s.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$Log_File
    VALIDATE $? "Load catalogue products"
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue
VALIDATE $? "Restarted catalogue"

