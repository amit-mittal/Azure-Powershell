Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionId '<sub-id>'

try
{
    while ($true)
    {
        Write-Host "Starting with the creation of VM resources..."

        $resourceGroup = 'Tdp-Group-1'
        $regionName = 'westcentralus'
        $vmsize="Standard_DS1_v2"
        $secretURL="<Key-Vault-URI>"
        $vaultName = 'KeyVault-3'

        New-AzureRmResourceGroup -Name $resourceGroup -Location $regionName -ErrorAction Stop

        # Create a subnet configuration
        $subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name 'TestPsSubnet' -AddressPrefix 192.168.1.0/24 -ErrorAction Stop

        # Create a virtual network
        $vnet = New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Location $regionName -Name 'TestPsVnet' -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig -ErrorAction Stop

        $pip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup -Location $regionName -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name "mypublicdns$(Get-Random)" -ErrorAction Stop

        # Create a virtual network card and associate with public IP address and NSG
        $nic = New-AzureRmNetworkInterface -Name 'TestPsNic' -ResourceGroupName $resourceGroup -Location $regionName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -ErrorAction Stop

        # Define a credential object
        $secpasswd = ConvertTo-SecureString "<PASSWORD>" -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ("<USER>", $secpasswd)

        #$cred = Get-Credential

        # Key Vault
        $sourceVaultId = (Get-AzureRmKeyVault -ResourceGroupName 'KeyVaultRg-3' -VaultName $vaultName -ErrorAction Stop).ResourceId
        $CertificateStore = "My"

        # Create a virtual machine configuration
        $vmConfig = New-AzureRmVMConfig -VMName 'TestPsVm' -VMSize $vmsize | `
        Set-AzureRmVMOperatingSystem -Windows -ComputerName 'TestPsName' -Credential $cred -WinRMHttp -WinRMHttps -WinRMCertificateUrl $secretURL | `
        Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter -Version latest | `
        Add-AzureRmVMNetworkInterface -Id $nic.Id | `
        Add-AzureRmVMSecret -SourceVaultId $sourceVaultId -CertificateStore $CertificateStore -CertificateUrl $secretURL

        New-AzureRmVM -ResourceGroupName $resourceGroup -Location $regionName -VM $vmConfig -ErrorAction Stop

        Write-Host "VM has been successfully created"

        $ip = Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup | Select IpAddress
        $address = "https://" + $ip.IpAddress + ":5986"
        $myUri = [System.Uri]$address
        Get-PSSession -ConnectionUri $myUri -Credential $cred `
        -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck) -Authentication Negotiate -ErrorAction Stop

        Write-Host "RDP to VM is successfully working"

        Remove-AzureRmResourceGroup -Name $resourceGroup -Force -ErrorAction Stop

        Write-Host "Cleanup completed successfully..."
    }
}
catch
{
    $ErrorMessage = $_.Exception.Message

    $o = New-Object -com Outlook.Application 
    $mail = $o.CreateItem(0)

    #2 = high importance email header
    $mail.importance = 2
    $mail.subject = “Failure in Windows WinRM runner“
    $mail.body = “Error Received: $ErrorMessage. For details, check the logs.“

    #for multiple email, use semi-colon ; to separate
    $mail.To = “<EMAIL-ID>“
    $mail.Send()
    
    Write-Host $ErrorMessage
}