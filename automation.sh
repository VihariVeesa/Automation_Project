
#!/bin/bash
myname=sunnyvihari
S3_bucket="upgrad-sunnyvihari"

sudo apt update -y

STR=$(dpkg -s apache2 | grep Status)
case "$STR" in 
   *ok*) echo "Apache2 package exists";; 
    *) sudo apt install apache2;;
esac

AS=$(sudo service apache2 status | grep active | wc -l)
if [ $AS > 0 ]
then
    echo "apache2 service is running "
else 
    echo "apache2 service is not running"
    sudo systemctl apache2 start
    echo "apache2 service started"
fi

AE=$(sudo service apache2 status | grep active | wc -l)
if [ $AE > 0  ]
then 
    echo "apache2 service is already enabled"
else    
    echo "enabling apache2 service"
    sudo systemctl enable apache2.service
fi

cd /var/log/apache2
timestamp=$(date '+%d%m%Y-%H%M%S') 

sudo tar -czvf  $myname-httpd-logs-${timestamp}.tar  *.log


sudo cp -r  $myname-httpd-logs-${timestamp}.tar /tmp/


aws s3 \
cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
s3://${S3_bucket}/${myname}-httpd-logs-${timestamp}.tar

if [ -f /var/www/html/inventory.html ]
then
	 echo "File exists" 
else
	 echo " Log Type               Date Created      Type          Size" >>  /var/www/html/inventory.html 
fi

logtype="httpd-logs"
type="tar"
size=$(du -h $myname-httpd-logs-${timestamp}.tar | awk '{print $1;}')

echo " <br>  $logtype           $timestamp        $type      $size" >> /var/www/html/inventory.html 

if [ -f /etc/cron.d/automation ]
then
	 echo "automation file exists" 
else
	 sudo systemctl stop cron
	 echo " 7 0 * * *  /root/Automation_Project/automation.sh" >> /etc/cron.d/automation
	 sudo systemctl start cron
fi
