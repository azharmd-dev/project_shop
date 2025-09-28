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

dnf install python3 gcc python3-devel -y &>>$Log_File
Validate $? "Installing Python3"

id roboshop &>>$Log_File
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$Log_File
    Validate $? "Creating system user"
else
    echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir -p /app 
Validate $? "Making app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$Log_File
Validate $? "Downloading the application"

cd /app 

rm -rf /app/* &>>$Log_File
Validate $? "Removing the existing app data"

unzip /tmp/payment.zip &>>$Log_File
Validate $? "Unzipping the Payment application"

pip3 install -r requirements.txt  &>>$Log_File

cp $Script_Dir/payment.service /etc/systemd/system/payment.service
Validate $? "Copying the payment repo"

systemctl daemon-reload
systemctl enable payment &>>$Log_File
Validate $? "Enabling payment service"

systemctl start payment
Validate $? "Starting payment service"

End_Time=$(date +%s)
Total_Time=$(($End_Time - $Start_Time))
echo -e "Total time to execute this script $Y $Total_Time $N in sec"
