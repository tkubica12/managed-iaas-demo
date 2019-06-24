# Testing ARM template: create Resource Group
$userResourceGroupName = "company-app1-rg"
New-AzureRmResourceGroup -ResourceGroupName $userResourceGroupName `
-Location westeurope

# Testing ARM template: deploy VM and join it to domain
New-AzureRmResourceGroupDeployment -ResourceGroupName $userResourceGroupName `
  -TemplateFile mainTemplate.json `
  -TemplateParameterFile parameters.json `
  -vmNamePrefix app1

# Testing ARM template: destroy resource group
Remove-AzureRmResourceGroup -Name $userResourceGroupName -Force -AsJob

# Point to our resource group
$resourceGroupName = "company-environment-rg"

# Compress template and UI definition to zip file
Compress-Archive -Path createUiDefinition.json, mainTemplate.json `
  -Force `
  -DestinationPath windowsVm.zip

# Get storage account for zip (needed just for app registration to Azure, you can use any URL)
$storageAccountName = "mycompanyenvstorage"
$envResourceGroupName = "company-environment-rg"
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $envresourceGroupName `
  -Name $storageAccountName
$ctx = $storageAccount.Context
New-AzureStorageContainer -Name "templates" -Permission blob -Context $ctx
Set-AzureStorageBlobContent -Blob windowsVm.zip `
    -Container templates `
    -File .\windowsVm.zip `
    -Context $ctx `
    -Force

# We will assign management rights of deployed instances to Service Principal I have prepared before
$userId="5219efa3-dc8d-45e1-9b82-6df5f1b063c8"
$roleid=(Get-AzureRmRoleDefinition -Name Owner).Id

# Create the definition for a managed application
New-AzureRmManagedApplicationDefinition `
  -Name "Windows2016IIS" `
  -Location "westeurope" `
  -ResourceGroupName $resourceGroupName `
  -LockLevel None `
  -DisplayName "Windows 2016 with IIS" `
  -Description "Windows 2016 with IIS" `
  -Authorization "${userId}:$roleId" `
  -PackageFileUri "https://mycompanyenvstorage.blob.core.windows.net/templates/windowsVm.zip"


# Update definition
Remove-AzureRmManagedApplicationDefinition `
    -Name "Windows2016IIS" `
    -ResourceGroupName $resourceGroupName `
    -Force
Compress-Archive -Path createUiDefinition.json, mainTemplate.json `
-DestinationPath windowsVm.zip -Force
Set-AzureStorageBlobContent -Blob windowsVm.zip `
    -Container templates `
    -File .\windowsVm.zip `
    -Context $ctx `
    -Force
New-AzureRmManagedApplicationDefinition `
    -Name "Windows2016IIS" `
    -Location "westeurope" `
    -ResourceGroupName $resourceGroupName `
    -LockLevel None `
    -DisplayName "Windows 2016 with IIS" `
    -Description "Windows 2016 with IIS" `
    -Authorization "${userId}:${roleId}" `
    -PackageFileUri "https://mycompanyenvstorage.blob.core.windows.net/templates/windowsVm.zip"

