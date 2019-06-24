# Create networking
$region = "westeurope" 
az group create -n net-rg -l $region
az network vnet create -n net -g net-rg --address-prefix 10.0.0.0/16
az network vnet subnet create -n webfarm `
    -g net-rg `
    --vnet-name net `
    --address-prefix 10.0.2.0/24
az network nsg create -n web-nsg -g net-rg
az network nsg rule create -g net-rg `
    --nsg-name web-nsg `
    -n AllowHttp `
    --priority 120 `
    --source-address-prefixes '*' `
    --source-port-ranges '*' `
    --destination-address-prefixes '*' `
    --destination-port-ranges 80 `
    --access Allow `
    --protocol Tcp `
    --description "Allow HTTP"
az network vnet subnet update -g net-rg `
    -n webfarm `
    --vnet-name net `
    --network-security-group web-nsg

# Create Virtual Machine Scale Set
az group create -n web-rg -l $region

az vmss create -n webscaleset `
    -g web-rg `
    --image UbuntuLTS `
    --instance-count 3 `
    --vm-sku Standard_DS1_v2 `
    --admin-username labuser `
    --admin-password Azure12345678 `
    --authentication-type password `
    --public-ip-address web-lb-ip `
    --subnet $(az network vnet subnet show -g net-rg --name webfarm --vnet-name net --query id -o tsv) `
    --lb web-lb
az network lb probe create -g web-rg `
    --lb-name web-lb `
    --name webprobe `
    --protocol tcp `
    --port 80
az network lb rule create -g web-rg `
    --lb-name web-lb `
    --name myHTTPRule `
    --protocol tcp `
    --frontend-port 80 `
    --backend-port 80 `
    --frontend-ip-name loadBalancerFrontEnd `
    --backend-pool-name web-lbBEPool `
    --probe-name webprobe

# Create storage account and upload scripts
$storageName = "myuniquename19195"
az storage account create -n $storageName `
    -g web-rg `
    --sku Standard_LRS
az storage container create -n deploy `
    --connection-string $(az storage account show-connection-string -n $storageName -g web-rg -o tsv)
az storage blob upload -f scripts/app-v1.sh `
    -c deploy `
    -n app-v1.sh `
    --connection-string $(az storage account show-connection-string -n $storageName -g web-rg -o tsv)
az storage blob upload -f scripts/app-v2.sh `
    -c deploy `
    -n app-v2.sh `
    --connection-string $(az storage account show-connection-string -n $storageName -g web-rg -o tsv)

$v1Uri = $(az storage blob generate-sas -c deploy `
    -n app-v1.sh `
    --permissions r `
    --expiry "2030-01-01" `
    --https-only `
    --full-uri `
    --connection-string $(az storage account show-connection-string -n $storageName -g web-rg -o tsv) `
    -o tsv )
$v2Uri = $(az storage blob generate-sas -c deploy `
    -n app-v2.sh `
    --permissions r `
    --expiry "2030-01-01" `
    --https-only `
    --full-uri `
    --connection-string $(az storage account show-connection-string -n $storageName -g web-rg -o tsv) `
    -o tsv )

## Update VMSS model for v1 script and upgrade
$v1Settings = '{"fileUris": ["' + $v1Uri + '"]}'
$v1Settings | Out-File v1Settings.json
az vmss extension set --vmss-name webscaleset `
    --name CustomScript `
    -g web-rg `
    --version 2.0 `
    --publisher Microsoft.Azure.Extensions `
    --protected-settings '{\"commandToExecute\": \"bash app-v1.sh\"}' `
    --settings v1Settings.json
Remove-Item v1Settings.json

az vmss update-instances --instance-ids '*' `
    -n webscaleset `
    -g web-rg

## Update VMSS model for v2 script and upgrade
$v2Settings = '{"fileUris": ["' + $v2Uri + '"]}'
$v2Settings | Out-File v2Settings.json
az vmss extension set --vmss-name webscaleset `
    --name CustomScript `
    -g web-rg `
    --version 2.0 `
    --publisher Microsoft.Azure.Extensions `
    --protected-settings '{\"commandToExecute\": \"bash app-v2.sh\"}' `
    --settings v2Settings.json
Remove-Item v2Settings.json

az vmss update-instances --instance-ids '*' `
    -n webscaleset `
    -g web-rg

# Cleanup
az group delete -n web-rg -y --no-wait
az group delete -n net-rg -y --no-wait