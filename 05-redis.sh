#!/bin/bash

Userid=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

Logs_Folder="/var/log/shell-script"
Script_Name=$( echo $0 | cut -d "." -f1 )
Log_File=$Logs_Folder/$Script_Name.log 
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
        echo -e "$2  is $G SUCCESS $N" | tee -a $$Log_File
    fi
}

dnf list module redis  &>>$Log_File
Validate $? "Checking redis installed or not"

dnf module disable redis -y  &>>$Log_File
Validate $? "disabling redis"    

dnf module enable redis:7 -y  &>>$Log_File
Validate $? "enabling redis version 7"

dnf install redis -y  &>>$Log_File
Validate $? "Installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Allowing Remote connections to Redis"

systemctl enable redis  &>>$Log_File
Validate $? "Enabling systemctl service"

systemctl start redis 
Validate $? "Starting systemctl service"

End_Time=$(date +%s)
Total_Time=$(($End_Time - $Start_Time))
echo -e "Time taken to execute the script $Y $Total_Time $N in sec"