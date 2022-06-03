#Get current time in ms to create a unique name.
$DateTime = (Get-Date).ToUniversalTime() 
$UnixTimeStamp = [System.Math]::Truncate((Get-Date -Date $DateTime -UFormat %s))

$KEY_NAME = "Cloud-Computing-" + $UnixTimeStamp
$KEY_PEM = $KEY_NAME + ".pem"

#Create key.
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_PEM

#Create security group.
$SEC_GRP = "scriptSG-" + $UnixTimeStamp
aws ec2 create-security-group --group-name $SEC_GRP --description "script gen sg"

#Create rules for fire wall. (ports 22 & 5000).
$MY_IP = curl https://checkip.amazonaws.com
aws ec2 authorize-security-group-ingress `
	--group-name $SEC_GRP `
	--protocol tcp `
	--port 22 `
	--cidr $MY_IP/32 
	
aws ec2 authorize-security-group-ingress `
	--group-name $SEC_GRP `
	--protocol tcp `
	--port 5000 `
	--cidr 0.0.0.0/0
	
#Lunch 2 EC2 instances. 
$UBUNTU_20_04_AMI = "ami-08ca3fed11864d6bb"
$RUN_INSTANCES = (aws ec2 run-instances `
	--image-id $UBUNTU_20_04_AMI `
	--instance-type t2.micro `
	--key-name $KEY_NAME `
	--count "2" `
	--security-groups $SEC_GRP)				

#Fetch instance A&B IDs.
$RUN_INSTANCES_Convert = $RUN_INSTANCES | ConvertFrom-Json
$INSTANCE_ID_A = $RUN_INSTANCES_Convert.Instances[0].InstanceId
$INSTANCE_ID_B = $RUN_INSTANCES_Convert.Instances[1].InstanceId

#Wait for A to run.
aws ec2 wait instance-running --instance-ids $INSTANCE_ID_A

#Fetch instance A public ip address.
$Describe_Instances_A = aws ec2 describe-instances --instance-ids $INSTANCE_ID_A
$Describe_Instances_A_Convert = $Describe_Instances_A | ConvertFrom-Json
$PUBLIC_IP_A = $Describe_Instances_A_Convert.Reservations[0].Instances[0].PublicIpAddress

#Wait for B to run.
aws ec2 wait instance-running --instance-ids $INSTANCE_ID_B

#Fetch instance B public ip address.
$Describe_Instances_B = aws ec2 describe-instances --instance-ids $INSTANCE_ID_B
$Describe_Instances_B_Convert = $Describe_Instances_B | ConvertFrom-Json
$PUBLIC_IP_B = $Describe_Instances_B_Convert.Reservations[0].Instances[0].PublicIpAddress

#save ips.
"A:" + ${PUBLIC_IP_A} + ",B:" + ${PUBLIC_IP_B} > ips.txt

#Copy Required Files to A.
ssh -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" ubuntu@$PUBLIC_IP_A "mkdir .aws"
scp -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" credentials config ubuntu@${PUBLIC_IP_A}:~/.aws/
scp -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" ips.txt ubuntu@${PUBLIC_IP_A}:/home/ubuntu/

#Copy & Run bash script on A, lunch server.
scp -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" onCloudScript.bash ubuntu@${PUBLIC_IP_A}:/home/ubuntu/
ssh -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" -t ubuntu@$PUBLIC_IP_A "sudo bash ~/onCloudScript.bash"
ssh -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" ubuntu@$PUBLIC_IP_A "aws configure list" 
ssh -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" -t ubuntu@$PUBLIC_IP_A "cd app && sudo chmod -R a+rwx . && pm2 start index.js" 

#Copy Required Files to B.
ssh -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" ubuntu@$PUBLIC_IP_B "mkdir .aws"
scp -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" credentials config ubuntu@${PUBLIC_IP_B}:~/.aws/
scp -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" ips.txt ubuntu@${PUBLIC_IP_B}:/home/ubuntu/

#Copy & Run bash script on B, lunch server.
scp -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" onCloudScript.bash ubuntu@${PUBLIC_IP_B}:/home/ubuntu/
ssh -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" -t ubuntu@$PUBLIC_IP_B "sudo bash ~/onCloudScript.bash"
ssh -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" ubuntu@$PUBLIC_IP_B "aws configure list" 
ssh -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" -t ubuntu@$PUBLIC_IP_B "cd app && sudo chmod -R a+rwx . && pm2 start index.js"

"`r`n"
"Test by sending binary Data: (10 files)."
"`r`n"
for (($i = 0); $i -lt 10; $i++){

    $DateTime = (Get-Date).ToUniversalTime() 
    $UnixTimeStampTest = [System.Math]::Truncate((Get-Date -Date $DateTime -UFormat %s))
    $UnixTimeStampTest = $UnixTimeStampTest.ToString()

    for(($j = 0); $j -lt 10; $j++) {
        $UnixTimeStampTest += $UnixTimeStampTest
    }

    $BIN_NAME = "binary-data-" + $i
    $BIN_BIN = $BIN_NAME + ".bin"

	"Sending binary data to A, response id:"  
    $UnixTimeStampTest > $BIN_BIN | curl -X PUT -F "data=@${BIN_BIN}" ${PUBLIC_IP_A}:5000/enqueue?iterations=3
	"`r`n"
	Start-Sleep -Seconds 2

	"Sending binary data to B, response id:"  
	$UnixTimeStampTest > $BIN_BIN | curl -X PUT -F "data=@${BIN_BIN}" ${PUBLIC_IP_B}:5000/enqueue?iterations=3
	"`r`n"
    Start-Sleep -Seconds 2
}

#Get info on current progress.
for (($i = 0); $i -lt 20; $i++){

	"Getting data from A, response is:"  
    curl -X GET ${PUBLIC_IP_A}:5000/info
	"`r`n"
	Start-Sleep -Seconds 5

	"Getting data from B, response is:"  	
	curl -X GET ${PUBLIC_IP_B}:5000/info
	"`r`n"
    Start-Sleep -Seconds 5
}

"`r`n"
"Test Fetching Completed Jobs:"
"`r`n"

"Getting 3 values from A, response is:"
curl -X POST ${PUBLIC_IP_A}:5000/pullCompleted?top=3
"`r`n"
Start-Sleep -Seconds 2

"Getting 4 values from B, response is:"
curl -X POST ${PUBLIC_IP_B}:5000/pullCompleted?top=4
"`r`n"
Start-Sleep -Seconds 2

"Getting 10 values from A, (that will fill in from B), response is:"
curl -X POST ${PUBLIC_IP_A}:5000/pullCompleted?top=10
"`r`n"
Start-Sleep -Seconds 2

"Getting 100 values from B, (that will try to fill in from A) response is:"
curl -X POST ${PUBLIC_IP_B}:5000/pullCompleted?top=100
"`r`n"