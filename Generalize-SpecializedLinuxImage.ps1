# sudo waagent -deprovision+user -force
# exit

$resourceGroup = 'bsd10-RG20'
$vmName = 'bsd10-vm'
$containerName = 'bsdgen'
$vhdPrefix = 'bsd10gen'

Stop-AzureRmVM -ResourceGroupName $resourceGroup -Name $vmName

Set-AzureRmVm -ResourceGroupName $resourceGroup -Name $vmName -Generalized

$vm = Get-AzureRmVM -ResourceGroupName $resourceGroup -Name $vmName -Status
$vm.Statuses

Save-AzureRmVMImage -ResourceGroupName $resourceGroup -Name $vmName `
     -DestinationContainerName $containerName -VHDNamePrefix $vhdPrefix `
     -Path 'Temp.json'