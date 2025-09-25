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

dnf install mysql-server -y &>>$Log_File
Validate $? "Installing MYSQL server"

systemctl enable mysqld &>>$Log_File
Validate $? "Enabling MYSQL server"

systemctl start mysqld &>>$Log_File
Validate $? "Starting MYSQL server"

mysql_secure_installation --set-root-pass RoboShop@1 &>>$Log_File
Validate $? "Setting up Root password"

End_Time=$(date +%s)
Total_Time=$(($End_Time - $Start_Time))
echo -e "Total time to execute this script $Y $Total_Time $N in sec"