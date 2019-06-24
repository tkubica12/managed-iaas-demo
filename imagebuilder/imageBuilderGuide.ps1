# Create resource group and assign RBAC to robot
az group create -n company-automated-images -l eastus2
az role assignment create --assignee "cf32a0cc-373c-47c9-9156-0db11f6a6dfc" `
    --role Contributor `
    --scope $(az group show -n company-automated-images --query id -o tsv)

# Create automated image definition
az resource create `
    --resource-group company-automated-images `
    --properties "@imagebuilder.json" `
    --is-full-object `
    --resource-type Microsoft.VirtualMachineImages/imageTemplates `
    -n automatedImage

# Run build process
az resource invoke-action `
     --resource-group company-automated-images `
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates `
     -n automatedImage `
     --action Run 

# Cleanup
az group delete -n company-automated-images -y --no-wait
