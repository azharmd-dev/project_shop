#!/bin/bash

Userid=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

Logs_Folder="/var/log/shell-script"
Script_Name=$( echo $0 | cut -d "." -f1 )
Log_File=$Logs_Folder/$Script_Name.log 
Script_Dir=$PWD

mkdir -p $Logs_Folder
echo "Script execution started at $(date)" | tee -a $Log_File

if [ $Userid -ne 0 ]; then
    echo "ERROR--> User Required Root privilege access"
    exit 1
fi

Validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 is $R FAILURE $N" | tee -a $Log_File
        exit 1
    else
        echo -e "$2 is $G SUCCESS $N" | tee -a $Log_File
    fi
}

##NodeJs##
dnf module disable nodejs -y &>>$Log_File
Validate $? "Disabling NodeJS"

dnf module enable nodejs:20 -y &>>$Log_File
Validate $? "Enabling NodeJS"

dnf install nodejs -y &>>$Log_File
Validate $? "Installing NodeJS"

id roboshop &>>$Log_File
    if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$Log_File
        Validate $? "Creating a system user"
    else 
        echo -e "Sytem user already exist $Y SKIPPING$N"
    fi

mkdir /app &>>$Log_File
Validate $? "Creating application directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$Log_File
Validate $? "Downloading cart application"

cd /app &>>$Log_File
Validate $? "Chaninging to app directory"

unzip /tmp/cart.zip &>>$Log_File
Validate $? "Unzipping the file"

npm install &>>$Log_File
Validate $? "Installing dependencies"

cp $Script_Dir/cart.service /etc/systemd/system/cart.service &>>$Log_File
Validate $? "Creating systemctl cart service"

systemctl daemon-reload
systemctl enable cart  &>>$Log_File
Validate $? "Enabling cart service"

systemctl start cart &>>$Log_File
Validate $? "Starting cart service"