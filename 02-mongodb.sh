#!/bin/bash

Userid=$(id -u) #To know the user access
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

Logs_Folder="/var/log/shell-script" #Logs will be stored in this directory
Script_Name=$(echo $0 | cut -d "." -f1)
Log_File="$Logs_Folder/$Script_Name.log" 
#Log will be saved with the file name as /var/log/shell-script/02-mongodb.log

mkdir -p $Logs_Folder

echo "Script stated executing at $(date)" | tee -a $Log_File

if [ $Userid -ne 0 ]; then
    echo -e "$R ERROR >> User required root previlege to run this script $N"
    exit 1
fi

Validate(){
    if [ $1 -ne 0 ]; then
        echo -e "Installation $2 is $R FAILURE $N" | tee -a $Log_File
        exit 1
    else
        echo -e "Installation $2 is $R SUCCESS$N" | tee -a $Log_File
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
Validate $? "Adding Mongorepo"

dnf install mongodb-org -y &>>$Log_File
Validate $? "Installing MongoDB"

systemctl enable mongod &>>$Log_File
Validate $? "Enabling MongoDB"

systemctl start mongod 
Validate $? "Starting MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
Validate $? "Providing remote access to MongoDB"

systemctl restart mongod
Validate $? "Restarting MongoDB"
