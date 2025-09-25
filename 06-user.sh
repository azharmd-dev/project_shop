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
        echo -e "$2  is $G SUCCESS $N" | tee -a $$Log_File
    fi
}

dnf module disable nodejs -y &>> $Log_File
Validate $? "Disabling NodeJS"

dnf module enable nodejs:20 -y &>> $Log_File
Validate $? "Disabling NodeJS" 

dnf install nodejs -y &>> $Log_File
Validate $? "Installing NodeJS" 

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $Log_File
    VALIDATE $? "Creating system user"
else
    echo -e "User already exist ... $Y SKIPPING $N"
fi
mkdir -p /app &>> $Log_File

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip  &>> $Log_File
Validate $? "Downloading the code"
cd /app 
unzip /tmp/user.zip &>> $Log_File
Validate $? "Unzippping the downloded file"
npm install &>> $Log_File
Validate $? "Installing dependencies"

cp $Script_Dir/user.service /etc/systemd/system/user.service
Validate $? "Copying USER services"

systemctl daemon-reload
systemctl enable user &>> $Log_File
Validate $? "Enabling systemctl user service"

systemctl start user
Validate $? "Enabling systemctl user service"

End_Time=$(date +%s)
Total_Time=$(($End_Time - $Start_Time))
echo -e "Total time taken to execute script $Y $Total_Time $N in sec"