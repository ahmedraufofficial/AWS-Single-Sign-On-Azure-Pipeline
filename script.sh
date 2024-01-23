#!/bin/bash
echo "Hello, HashiCorp!"
apk update
apk add curl
apk add jq
accountName="On One Password"

#get details from 1password
curl -L https://cache.agilebits.com/dist/1P/op2/pkg/v2.17.0-beta.01/op_linux_amd64_v2.17.0-beta.01.zip -o op_linux_amd64_v2.17.0-beta.01.zip
unzip op_linux_amd64_v2.17.0-beta.01.zip
mv op /usr/local/bin/
op --version
export OP_SERVICE_ACCOUNT_TOKEN="ONE PASSWORD TOKEN WHICH HAS AWS ROOT CREDENTIALS"
accountDetails=$(op item get --vault "AWS I AM User" "AWS I AM User - $accountName" --format=json | op item get --fields username,"Account ID","Access Key","Secret Key","Account")
account=$(echo "$accountDetails" | cut -d ',' -f 2)
access_key=$(echo "$accountDetails" | cut -d ',' -f 3)
secret_key=$(echo "$accountDetails" | cut -d ',' -f 4)
account_name=$(echo "$accountDetails" | cut -d ',' -f 5)
reseller_account=$(echo "AWS $accountName Reseller Account")

#API call
response=$(curl --location 'AZURE FUNCTION URL CREATED IN STEP 2 (CHECK README)' --header 'Content-Type: application/json' --data "{\"appName\": \"$accountName\", \"accountId\": \"$account\"}")
echo $response
appId=$(echo "$response" | jq -r '.appId')
token=$(echo "$response" | jq -r '.token')
servicePrincipalId=$(echo "$response" | jq -r '.servicePrincipalId')
#get certificate
curl --location "https://login.microsoftonline.com/{MICROSOFT TENANT ID}/federationmetadata/2007-06/federationmetadata.xml?appid=$appId" -H "Content-Type: application/json" -H "Authorization: Bearer $token" -H "Cookie: fpc=COOKIE DATA IF ANY; stsservicecookie=estsfd; x-ms-gateway-slice=estsfd" > certificate.xml
ls

#install terraform
release=`curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest |  grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1'`
wget https://releases.hashicorp.com/terraform/${release}/terraform_${release}_linux_amd64.zip
unzip terraform_${release}_linux_amd64.zip
mv terraform /usr/bin/terraform
terraform --version

#create variables.tf
echo 'variable "access_key" {
  type    = string
  default = "'"$access_key"'"
}

variable "secret_key" {
  type    = string
  default = "'"$secret_key"'"
}

variable "account" {
  type    = string
  default = "'"$account"'"
}
' > variables.tf

response=$(curl -sS -w "%{http_code}\n" --location "https://api.bitbucket.org/2.0/repositories/{Bitbucket Repository Path}/downloads/$account.terraform.tfstate" --header 'Authorization: Bearer {BITBUCKET TOKEN}' -o /dev/null)
if [ $response -eq 200 ]; then
  echo "Successfull Response. Downloading Terraform state..."
  curl --location "https://api.bitbucket.org/2.0/repositories/{Bitbucket Repository Path}/downloads/$account.terraform.tfstate" --header 'Authorization: Bearer {BITBUCKET TOKEN}' -o "$account.terraform.tfstate"
  ls
  mv $account.terraform.tfstate terraform.tfstate
  terraform init
  #terraform plan
  terraform apply --auto-approve
  cp terraform.tfstate $account.terraform.tfstate
  curl -s -X POST https://api.bitbucket.org/2.0/repositories/{Bitbucket Repository Path}/downloads -F files=@$account.terraform.tfstate --header 'Authorization: Bearer {BITBUCKET TOKEN}'
else
  echo "Response code is not 200. Initializing new Terraform state..."
  terraform init
  #terraform plan
  terraform apply --auto-approve
  cp terraform.tfstate $account.terraform.tfstate
  curl -s -X POST https://api.bitbucket.org/2.0/repositories/{Bitbucket Repository Path}/downloads -F files=@$account.terraform.tfstate --header 'Authorization: Bearer {BITBUCKET TOKEN}'
  terraform plan
fi

terraformOutput=$(terraform output --json)
provisionAccessKey=$(echo "$terraformOutput" | jq -r '.access_key.value')
provisionSecretKey=$(echo "$terraformOutput" | jq -r '.secret_key.value')

echo "Service Principal: $servicePrincipalId"
echo "Access Key: $provisionAccessKey"
echo "Secret Key: $provisionSecretKey"

echo "Starting to provision"

provision=$(curl --location 'AZURE FUNCTION URL CREATED IN STEP 2 (CHECK README)' \
--header 'Content-Type: application/json' \
--data '{
    "provision": {
        "servicePrincipal": "'"$servicePrincipalId"'",
        "accessKey": "'"$provisionAccessKey"'",
        "secretKey": "'"$provisionSecretKey"'"
    }
}')

echo $provision

#docker run --rm --name my-container -v $(pwd)/main.tf:/main.tf -v $(pwd)/script.sh:/app/script.sh alpine sh -c "sh /app/script.sh"