#!/bin/bash

# Make sure you place file "userdata" at the same location with this script.

# Pay attention to which region is your AWS CLI is configured and specify the region in the commands if related to a different region than your setup. 

# Before you begin, make sure you modify this script with your relevant information. Lines needs to be modified are:11,12,13,14,85,139,165.

#--------Variables--------

amazonLinux2AMI="ami-0dc2d3e4c0f9ebd18" #-----amazon free tier AMI - amazon Linux 2.
keypair="keypair-virg" #----------------------us-east-1 key pair (N.Virginia)
userdata="userdata.txt" #----------------user data to install nginx.
Kpair="keypair" #-----------------------------us-east-2 key pair (OHIO)

echo "🅛 Hello user! I'm Luna, an automated bash script instructor. 
In this exercise, you will learn how to create and modify EC2 instances,
copy AMI between regions using AWS CLI, and do some automation. Good luck!"

#--------US-EAST-1 N.VIRGINIA REGION--------

echo "🅛 Now let's create Security Group and launch an EC2 in Virginia region."
# create security group and save returned SG id in a variable
ASSI8SGid=$(aws ec2 create-security-group --group-name ASSI8SG --description "Assignment#8 security group --region us-east-1" \
	--query 'GroupId' --output text)

# authorize port 80 in security group
aws ec2 authorize-security-group-ingress --group-name ASSI8SG --protocol tcp --port 80 --cidr 0.0.0.0/0 

# port 22 for ssh (assignment required)
aws ec2 authorize-security-group-ingress --group-name ASSI8SG --protocol tcp --port 22 --cidr 0.0.0.0/0


# create an EC2 instance
aws ec2 run-instances --image-id "$amazonLinux2AMI" --instance-type t2.nano \
    --key-name "$keypair" --associate-public-ip-address --user-data file://$userdata \
	--security-group-ids "$ASSI8SGid" \
	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=assi8ec2}]' \
    --region us-east-1

echo "🅛 Well done!"

# instanceId query region us-east-1 VARIABLE
ec2var=$(aws ec2 describe-instances --region us-east-1 --filters Name=tag:Name,Values=assi8ec2 --query 'Reservations[*].Instances[*].[InstanceId]' --output text)

aws ec2 wait instance-status-ok --instance-ids $ec2var

echo "🅛 ec2 instance created"

echo "🅛 Now, let's create AMI. It's will take some time.....zzzz....."

# create AMI from an EC2 instance
aws ec2 create-image \
    --instance-id "$ec2var" \
    --name "assi8AMI" \
    --description "An AMI for assi#8" \
    --tag-specifications 'ResourceType=image,Tags=[{Key=Name,Value=assi8AMI}]'

# imageId query region us-east-1 VARIABLE
amiVAR=$(aws ec2 describe-images --region us-east-1 --filters Name=tag:Name,Values=assi8AMI --query 'Images[*].[ImageId]' --output text)

aws ec2 wait image-available --region us-east-1 --image-ids $amiVAR

echo "🅛 Great news! Image created"
echo "🅛 Let's create instance from your AMI"

# create an EC2 instance from the existing AMI
aws ec2 run-instances --region us-east-1 --image-id "$amiVAR" --instance-type t2.nano \
    --key-name "$keypair" --associate-public-ip-address \
    --security-group-ids "$ASSI8SGid" \
	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=assi8ec2AMI}]' 
    
ec2var2=$(aws ec2 describe-instances --region us-east-1 --filters Name=tag:Name,Values=assi8ec2AMI --query 'Reservations[*].Instances[*].[InstanceId]' --output text)

aws ec2 wait instance-status-ok --region us-east-1 --instance-ids $ec2var2

echo "🅛 ec2 from AMI created"

ip_address_ec2AMI_Virginia=$(aws ec2 describe-instances --instance-ids $ec2var2 --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)

echo "🅛 Let's ssh into your instance. Please, give me the answer?"

# ec2 index.html content check

ssh -i /Users/jane.gordy/Downloads/keypair-virg.pem ec2-user@"$ip_address_ec2AMI_Virginia" "cat /usr/share/nginx/html/index.html ; ls /usr/share/nginx/html/alexabuy.jpg" 

echo "🅛 Great!"

echo "************************DONE************************"


echo "🅛 Now, let's copy the Virginia AMI to Ohio"

# copy AMI to ohio us-east-2

aws ec2 copy-image --name assi8AMI --source-image-id "$amiVAR" \
    --source-region us-east-1 \
    --region us-east-2 --name "AMIcopy" \
    

# imageId query region us-east-2 VARIABLE
amicopyVAR=$(aws ec2 describe-images --region us-east-2 --filters Name=name,Values=AMIcopy --query 'Images[*].[ImageId]' --output text)

aws ec2 wait image-available --region us-east-2 --image-ids $amicopyVAR

echo "🅛 Well Done! An image copy created (us-east-2)"

echo "🅛 Let me create a security group for you. Don't thank me!"

# create security group and save returned SG id in a variable
ASSI8SGidohio=$(aws ec2 create-security-group --group-name assi8SGohio --region us-east-2 --description "Assignment#8 security group --region us-east-2" \
	--query 'GroupId' --output text)

# authorize port 80 in security group
aws ec2 authorize-security-group-ingress --group-name assi8SGohio --region us-east-2 --protocol tcp --port 80 --cidr 0.0.0.0/0 

sleep 20

echo "🅛 Let's create instance from your AMI"

# create an EC2 instance from the existing AMIcopy OHIO
aws ec2 run-instances --region us-east-2 --image-id "$amicopyVAR" --instance-type t2.nano \
    --key-name "$Kpair" --associate-public-ip-address \
    --security-group-ids "$ASSI8SGidohio" \
	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=assi8ec2AMIcopy}]'

echo "🅛 ec2 from AMI created(us-east-2)"


ip_address_ec2_Virginia=$(aws ec2 describe-instances --instance-ids $ec2var --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)

echo "🅛 Let's ssh into your instance. Please, give me the answer?"

echo "🅛 Now let's play with an instance type and change from t2.nano to t2.micro. First, take a look at current free memory."

sleep 10

# ec2 memory check (us-east-1)
ssh -i /Users/jane.gordy/Downloads/keypair-virg.pem ec2-user@"$ip_address_ec2_Virginia" "free -m" 

echo "*************************************************DONE*************************************************"

# ec2 stop-instance
aws ec2 stop-instances --instance-ids $ec2var

aws ec2 wait instance-stopped --instance-ids $ec2var

echo "🅛 Resizing starts."

# ec2 instance resize
aws ec2 modify-instance-attribute \
--instance-id "$ec2var" \
--instance-type "{\"Value\": \"t2.micro\"}"

sleep 30

echo "ec2 resize completed"

# ec2 start-instance
aws ec2 start-instances --instance-ids $ec2var

aws ec2 wait instance-status-ok --instance-ids $ec2var

# ec2 memory check (us-east-1)
ssh -i /Users/jane.gordy/Downloads/keypair-virg.pem ec2-user@"$ip_address_ec2_Virginia" "free -m" 


echo "*************************************************SCRIPT SUCCESSFULLY COMPLETED*************************************************"

echo "🅛 You have completed this Assignment! Now you should have a better understanding of how thing in AWS works. Good Job, see you next time!"

