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
Start_Time=$(date +%s)

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

dnf module disable nginx -y &>>$Log_File
Validate $? "Disabling nginx"

dnf module enable nginx:1.24 -y &>>$Log_File
Validate $? "Enabling nginx version 1.24"

dnf install nginx -y &>>$Log_File
Validate $? "Installing nginx"

systemctl enable nginx &>>$Log_File
Validate $? "Enabling NGINX"

systemctl start nginx 

rm -rf /usr/share/nginx/html/* &>>$Log_File
Validate $? "Removing existig default HTML content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$Log_File
Validate $? "Downloading the frontend application code"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$Log_File
Validate $? "Unzipping the frontend code"

rm -rf /etc/nginx/nginx.conf #To removing previous nginx configuration
cp $Script_Dir/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copying nginx.conf"

systemctl restart nginx 

End_Time=$(date +%s)
Total_Time=$(($End_Time - $Start_Time))
echo -e "Total time to execute this script $Y $Total_Time $N in sec"