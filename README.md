# Managed IaaS demo

## Agenda
1. Use GUI to create VM to understand basic concepts and configuration options
2. Native tooling and how to use it - Backup, DR to different region, logging, monitoring, workbooks, inventory, update management, automation, security monitoring, network monitoring, ...
3. Manual process to capture corporate image
4. Manual process to publish image in gallery to be used company-wide in both fully managed and unmanaged IaaS offerings
5. Using Virtual Machine Scale Sets to automate computing and web farms and lifecycle management
6. Automating process of image creation to streamline operations and provide frequently updated images
7. Automating process of VM creation and enrollment to native monitoring tools via ARM template
8. Publishing VM template in service catalog for fully-managed IaaS offering
9. Managing costs

## Presentation notes
* Use environmentTemplate to build shared networking and setup Domain Controller
* Use windowsTemplate to build VM and ensure all monitoring is enabled day before for presentation of step 2
* Use [Image Builder guide](imageBuilderGuide.ps1)
* Use [VMSS guide](vmss/vmssGuide.ps1)
* Create managed app definition per [guide](windowsTemplate/deploy.ps1)