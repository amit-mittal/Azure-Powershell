Function DeployVMSS($region, $mode)
{
    Write-Host "Deploying VMSS in Region: " $region

    $ng = New-Guid
    $resourceGroup = "VMSS-" + $mode + "-" + $ng.Guid
    $status = 0
    $details = ""
    
    try
    {
        # Variables for common values    
        $location = $region
        $vmName = "IaasVmss"

        # Create a resource group
        New-AzureRmResourceGroup -Name $resourceGroup -Location $location -ErrorAction Stop

        # Create a config object
        $vmssConfig = New-AzureRmVmssConfig -Location $location -SkuCapacity 50 -SkuName Standard_A0 -UpgradePolicyMode Manual -Tag @{ OSIsoGeneratingComponent=$mode} -ErrorAction Stop

        # Reference a virtual machine image from the gallery
        Set-AzureRmVmssStorageProfile $vmssConfig -ImageReferencePublisher MicrosoftWindowsServer -ImageReferenceOffer WindowsServer -ImageReferenceSku 2016-Datacenter -ImageReferenceVersion latest -ErrorAction Stop

        # Set up information for authenticating with the virtual machine
        Set-AzureRmVmssOsProfile $vmssConfig -AdminUsername azureuser -AdminPassword P@ssw0rd! -ComputerNamePrefix myvmssvm -ErrorAction Stop

        # Create the virtual network resources
        $subnet = New-AzureRmVirtualNetworkSubnetConfig -Name "my-subnet" -AddressPrefix 10.0.0.0/24 -ErrorAction Stop
        $vnet = New-AzureRmVirtualNetwork -Name "my-network" -ResourceGroupName $resourceGroup -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet -ErrorAction Stop
        $ipConfig = New-AzureRmVmssIpConfig -Name "my-ip-address" -LoadBalancerBackendAddressPoolsId $null -SubnetId $vnet.Subnets[0].Id -ErrorAction Stop

        # Attach the virtual network to the config object
        Add-AzureRmVmssNetworkInterfaceConfiguration -VirtualMachineScaleSet $vmssConfig -Name "network-config" -Primary $true -IPConfiguration $ipConfig -ErrorAction Stop

        # Create the scale set with the config object (this step might take a few minutes)
        New-AzureRmVmss -ResourceGroupName $resourceGroup -Name $vmName -VirtualMachineScaleSet $vmssConfig -ErrorAction Stop

        $status = 1
        Write-Host "Success in deployment!!"
    }
    catch
    {
        Write-Host "Exception while deploying!!"
        $status = 0
        $msg = $_.Exception.Message
        $details = $msg -replace "`r`n","; "
        Write-Host $msg -ForegroundColor Red
    }
    finally
    {
        sleep -Seconds 300
        Write-Host "Cleanup triggered!!"
        # Remove Resource Group
        Remove-AzureRmResourceGroup -Name $resourceGroup -Force -ErrorAction Continue
    }
    
    $finalVal = $location + "," + $mode + "," + $resourceGroup + "," + $status + "," + $details;
    Write-Host $finalVal
    $finalVal >> "VmssRunner-NodeCrp.csv"
}

while ($true)
{
    try
    {
        $regionList = @("eastus", "eastus2")
        foreach($region in $regionList)
        {
            DeployVMSS -region $region -mode "Node"
            DeployVMSS -region $region -mode "CRP"
        }
    }
    catch
    {
        $msg = $_.Exception.Message
        Write-Host "Error in main: " $msg
    }
}