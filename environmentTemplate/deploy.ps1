# Create Resource Group
$resourceGroupName = "company-environment-rg"
New-AzureRmResourceGroup -ResourceGroupName $resourceGroupName `
-Location westeurope

# Prepare storage account and container
$storageAccountName = "mycompanyenvstorage"
New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName `
  -Name $storageAccountName `
  -Location westeurope `
  -SkuName Standard_LRS `
  | New-AzureStorageContainer -Name "windows-powershell-dsc" -Permission blob

# Compile, package and push DSC to storage
Publish-AzureRmVMDscConfiguration -ResourceGroupName $resourceGroupName `
  -StorageAccountName $storageAccountName `
  -ConfigurationPath .\setupAD.ps1 `
  -Force

Publish-AzureRmVMDscConfiguration -ResourceGroupName $resourceGroupName `
  -StorageAccountName $storageAccountName `
  -ConfigurationPath .\setupIIS.ps1 `
  -Force

# Deploy VM and configure Domain Controller
New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName `
-TemplateFile dc.json `
-TemplateParameterFile dc.parameters.json

# Assign RBAC to resource group for 8b967430-badb-45ba-8d11-bca192994047
New-AzureRMRoleAssignment -ObjectId "8b967430-badb-45ba-8d11-bca192994047" `
  -RoleDefinitionName "Contributor" `
  -ResourceGroupName $resourceGroupName