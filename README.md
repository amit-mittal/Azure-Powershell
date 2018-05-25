# Azure-Powershell
Scripts to create VMs on Azure using Powershell SDK

Below is a brief description about scripts:
- WindowsVMCreation_Plan.ps1 -> An image which is under a plan and needs to be approved from the portal first before it can be deployed automatically.
- WindowsVMCreation_NoPlan.ps1 -> This script can be directly used for the images which are not under a plan.
- WindowsVmCreation_WinRm.ps1 -> This script deploys a window VM and then remotely access it through powershell to invoke scripts, etc.