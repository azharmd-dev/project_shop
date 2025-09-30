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
MYSQL_Host=mysql.azharprojects.site

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

dnf install maven -y &>>$Log_File 
Validate $? "Installing Maven"

id roboshop &>>$Log_File
    if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$Log_File
        Validate $? "Creating a system user"
    else 
        echo -e "Sytem user already exist $Y SKIPPING$N"
    fi
mkdir -p /app &>>$Log_File
Validate $? "Making Application directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$Log_File
Validate $? "Downloading the application"
cd /app 

rm -rf /app/*
Validate $? "Removing existing code"

unzip /tmp/shipping.zip &>>$Log_File
Validate $? "Unzipping the shipping services"

mvn clean package &>>$Log_File
Validate $? "Installing the dependencies"

mv target/shipping-1.0.jar shipping.jar  &>>$Log_File
Validate $? "Changing the name of shipping service"

cp $Script_Dir/shipping.service /etc/systemd/system/shipping.service &>>$Log_File
Validate $? "Creating the System services"

systemctl daemon-reload &>>$Log_File
Validate $? "Reloading the system service"

systemctl enable shipping &>>$Log_File
Validate $? "Enabling the shipping services"

systemctl start shipping &>>$Log_File
Validate $? "Staring the shipping services"

dnf install mysql -y &>>$Log_File
Validate $? "Installing MYSQL Client"

mysql -h $MYSQL_Host -uroot -pRoboShop@1 -e 'use cities' &>$Log_File
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_Host -uroot -pRoboShop@1 < /app/db/schema.sql &>>$Log_File
    mysql -h $MYSQL_Host -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$Log_File
    mysql -h $MYSQL_Host -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$Log_File
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
fi

systemctl restart shipping
Validate $? "Restarted SHIPPING Service"

End_Time=$(date +%s)
Total_Time=$(($End_Time - $Start_Time))
echo -e "Total time to execute this script $Y $Total_Time $N in sec"