# Conecta-se ao Tenant do Azure
# connect-azaccount -TenantId "a82988f9-cc0e-4703-9454-bc53bff5d1e4"

# ** VARIÁVEIS **
$rgName = "lab"
$rgRegion = "CentralUS"
# Coleta o IP público do usuário, a fim de liberar somente esse IP para acessar os recursos dentro da VNET, utilizando NSG
$publicIpAddress = Invoke-WebRequest -Uri ifconfig.me -UseBasicParsing | Select-Object -ExpandProperty Content 
$keyvaultPassSecret = "vmPass"
$keyvaultADDSRecoverySecret = "addsRecovery"
$adminUsername = "masterOfKeys"
$vnetName = "vnet-lab"
$subnetServersName = "subnet-servers"
$subnetClientName = "subnet-clients"
$vmADName = "vm-ad"
$vmIISName = "vm-iis"
$vmClientName = "vm-client"
$nsgName = "nsg-firewall"
$vmADSize = "Standard_B2s"
$vmIISSize = "Standard_B2s"
$vmClientSize = "Standard_B1s"
# Evite nomes com acentos ou cedilha
$adDomainName = "contoso.corp"
$resourceDeploymentJsonFile = "ARM_Templates\resourcesDeploymentParameters.json"
$addsConfigurationJsonFile = "ARM_Templates\addsConfigurationParameters.json"
# Gera um nome único para o KeyVault (o nome deve ser único dentro do Azure)
$nameLenght = 4
$kvCaracteres = "qazwsedcrfvtgbyhnujmikopQAZWSEDCRFVTGBYHNUJMKLP123456789"
$keyvaultName = "kvstorerdn" + -join ($kvCaracteres.ToCharArray() | Get-Random -Count $nameLenght)
# Gera uma senha única para as VMs
$passLenght = 22
$passCaracteres = "qazwsedcrfvtgbyhnujmikopQAZWSEDCRFVTGBYHNUJMKLP123456789*$@"

# Cria um Resource Group
Clear-Host
Write-Host ""
Write-Host "** CRIANDO O RESOURCE GROUP '"$rgName"'!"
New-AzResourceGroup `
  -Name $rgName `
  -Location $rgRegion

# A variável '$?' do Powershell armazena um valor TRUE se o último comando executado foi bem sucedido (New-AzResourceGroup) e FALSE se não. 
# Aqui, '!$?' significa 'SE NÃO FOR TRUE, PARE DE EXECUTAR'
if(!$?){
  Break
}

# Cria o KeyVault
Clear-Host
Write-Host "CRIADO COM SUCESSO O RESOURCE GROUP '"$rgName"'!"
Write-Host "** CRIANDO O KEYVAULT '"$keyvaultName"'"
Write-Host ""
$keyVaultInfo = New-AzKeyVault `
  -VaultName $keyvaultName `
  -ResourceGroupName $rgName `
  -Location $rgRegion -EnabledForTemplateDeployment `
  -Verbose

if(!$?){
  Break
}

# Cria um KeyVault Secret para a senha das VMs
Clear-Host
Write-Host "CRIADO COM SUCESSO O KEYVAULT '"$keyvaultName"'!"
Write-Host "** CRIANDO O KEYVAULT SECRET '"$keyvaultPassSecret"'!"
Write-Host ""
Set-AzKeyVaultSecret `
  -VaultName $keyvaultName `
  -Name $keyvaultPassSecret `
  -SecretValue (ConvertTo-SecureString (-join ($passCaracteres.ToCharArray() | Get-Random -Count $passLenght)) -AsPlainText -Force) 

if(!$?){
  Break
} 

# Cria um KeyVault Secret para a senha de recuperação do ADDS
Clear-Host
Write-Host "CRIADO COM SUCESSO O KEYVAULT SECRET '"$keyvaultPassSecret"'!"
Write-Host "** CRIANDO O KEYVAULT SECRET '"$keyvaultADDSRecoverySecret"'"
Write-Host ""
Set-AzKeyVaultSecret `
  -VaultName $keyvaultName `
  -Name $keyvaultADDSRecoverySecret `
  -SecretValue (ConvertTo-SecureString (-join ($passCaracteres.ToCharArray() | Get-Random -Count $passLenght)) -AsPlainText -Force) 

if(!$?){
  Break
} 

# Atualiza o arquivo de parâmetros 'addsConfigurationParameters.json'. Ele é o responsável por referenciar a chave no KeyVault na criação das VMs
# Aqui, o arquivo JSON será atualizado com as informações do KeyVault (id e secretname)
# ARQUIVO DE PARÂMETROS DA SENHA DAS VMS
$resourcesDeployParameters = Get-Content $resourceDeploymentJsonFile -raw | ConvertFrom-Json
$resourcesDeployParameters.parameters.adminPassword.reference.keyVault.id = $keyVaultInfo.ResourceId
$resourcesDeployParameters.parameters.adminPassword.reference.secretName = $keyvaultPassSecret
$resourcesDeployParameters | ConvertTo-Json -Depth 4  | Set-Content $resourceDeploymentJsonFile

# ARQUIVO DE PARÂMETROS DA SENHA DE RECUPERAÇÃO DO ADDS
$addsConfigurationParameters = Get-Content $addsConfigurationJsonFile -raw | ConvertFrom-Json
$addsConfigurationParameters.parameters.addsRecoveryPassword.reference.keyVault.id = $keyVaultInfo.ResourceId
$addsConfigurationParameters.parameters.addsRecoveryPassword.reference.secretName = $keyvaultADDSRecoverySecret
$addsConfigurationParameters | ConvertTo-Json -Depth 4  | Set-Content $addsConfigurationJsonFile

# Faz o deploy dos recursos
Clear-Host
Write-Host "CRIADO COM SUCESSO O KEYVAULT SECRET '"$keyvaultADDSRecoverySecret"'!"
Write-Host "** REALIZANDO O DEPLOY DOS RECURSOS"
Write-Host ""
$resourcesDeploymentFile = "ARM_Templates\resources-deploy.json"
$resourcesDeploymentName = "resources.deploy"
$resourcesDeployment = New-AzResourceGroupDeployment `
  -Name $resourcesDeploymentName `
  -TemplateUri $resourcesDeploymentFile `
  -ResourceGroupName $rgName `
  -publicIpAddress $publicIpAddress `
  -adminUsername $adminUsername `
  -vnetName $vnetName `
  -subnetServersName $subnetServersName `
  -subnetClientName $subnetClientName `
  -vmADName $vmADName `
  -vmADSize $vmADSize `
  -vmIISName $vmIISName `
  -vmIISSize $vmIISSize `
  -vmClientName $vmClientName `
  -vmClientSize $vmClientSize `
  -nsgName $nsgName `
  -TemplateParameterFile $resourceDeploymentJsonFile `
  -Verbose

if(!$?){
  Break
} 

# Coleta o IP privado atribuído pelo DHCP do Azure para a VM do ADDS. Utilizaremos posteriormente para atualizar o DNS da VNET
# Esse output vem do ARM Template executado anteriormente
$vmADPrivateIp = $resourcesDeployment.Outputs.Item("vmADPrivateIp").value

Clear-Host
Write-Host "DEPLOY DOS RECURSOS REALIZADO COM SUCESSO!"
Write-Host "** DEFININDO O IP PRIVADO DA VM ad-vm PARA STATIC"
Write-Host ""
$vmAdUpdateDeploymentFile = "ARM_Templates\vm-ad-update.json"
$vmAdUpdateDeploymentName = "vm-ad.update"
New-AzResourceGroupDeployment `
  -Name $vmAdUpdateDeploymentName `
  -TemplateUri $vmAdUpdateDeploymentFile `
  -ResourceGroupName $rgName `
  -vmADPrivateIp $vmADPrivateIp `
  -vnetName $vnetName `
  -subnetServersName $subnetServersName `
  -vmADName $vmADName `
  -Verbose

if(!$?){
  Break
} 

# Instala a feature de ADDS na VM vm-ad
Clear-Host
Write-Host "SETADO O IP DA VM vm-ad PARA STATIC COM SUCESSO!"
Write-Host "** INSTALANDO A FEATURE DO ADDS NA VM vm-ad"
Write-Host ""
$vmAdExtensionDeploymentFile = "ARM_Templates\vm-ad-extension.json"
$vmAdExtensionDeploymentName = "vm-ad.extension"
New-AzResourceGroupDeployment `
  -Name $vmAdExtensionDeploymentName `
  -TemplateUri $vmAdExtensionDeploymentFile `
  -ResourceGroupName $rgName `
  -vmADName $vmADName `
  -adDomainName $adDomainName `
  -TemplateParameterFile $addsConfigurationJsonFile `
  -Verbose

if(!$?){
  Break
}  

# Atualiza o DNS da VNET para utilizar o IP da vm-ad
Clear-Host
Write-Host "FEATURE DO ADDS INSTALADA COM SUCESSO!"
Write-Host "** ATUALIZANDO O DNS DA VNET PARA UTILIZAR O IP PRIVADO DA vm-ad"
Write-Host ""
$vnetDnsUpdateDeploymentFile = "ARM_Templates\vnet-dns-update.json"
$vnetDnsUpdateDeploymentName = "vnet.dns.update"
New-AzResourceGroupDeployment `
  -Name $vnetDnsUpdateDeploymentName `
  -TemplateUri $vnetDnsUpdateDeploymentFile `
  -ResourceGroupName $rgName `
  -vmADPrivateIp $vmADPrivateIp `
  -vnetName $vnetName `
  -subnetServersName $subnetServersName `
  -subnetClientName $subnetClientName `
  -Verbose

if(!$?){
  Break
}

# Reinicia as VMs para que a alteração anterior entre em vigor
Clear-Host
Write-Host "DNS ATUALIZADO COM SUCESSO!"
Write-Host "** REINICIANDO AS VMs PARA APLICAR A ATUALIZAÇÃO DE DNS"
Write-Host ""
Get-AzVM | Restart-AzVM

if(!$?){
  Break
} 

# Instala a feature de IIS na vm-iis e ingressa ela ao domínio
Clear-Host
Write-Host "VMs REINICIADAS COM SUCESSO"
Write-Host "** INSTALANDO A FEATURE DE IIS NA VM vm-iis E INGRESSANDO ELA NO DOMÍNIO"
Write-Host ""
$vmIisExtensionDeploymentFile = "ARM_Templates\vm-iis-extension.json"
$vmIisExtensionDeploymentName = "vm-iis.extension"
New-AzResourceGroupDeployment `
  -Name $vmIisExtensionDeploymentName `
  -TemplateUri $vmIisExtensionDeploymentFile `
  -ResourceGroupName $rgName `
  -vmIISName $vmIISName `
  -adminUsername $adminUsername `
  -adDomainName $adDomainName `
  -TemplateParameterFile $resourceDeploymentJsonFile `
  -Verbose

if(!$?){
  Break
}

# Após completar, verificar se é possível acessar a página padrão do IIS usando o FQDN da vm-iis (vm-iis.recruitlab.local) Se sim, o lab funcionou

Clear-Host
Write-Host "TODOS OS PASSOS FORAM REALIZADOS COM SUCESSO!"
$cleanAll = Read-Host "CASO QUEIRA DELETAR TODOS OS RECURSOS, PRESSIONE 1"

switch($cleanAll)
{
  1{
    # Limpa todos os recursos, inclusive o Resource Group
    Clear-Host
    Write-Host "** DELETANDO TODOS OS RECURSOS"
    $clearResourcesDeploymentFile = "ARM_Templates\rg-purge.json"
    $clearResourcesDeploymentName = "resourcegroup.purge"
    New-AzResourceGroupDeployment `
      -Name $clearResourcesDeploymentName `
      -TemplateUri $clearResourcesDeploymentFile `
      -ResourceGroupName $rgName `
      -Mode Complete `
      -Force `
      -Verbose

    Remove-AzResourceGroup -Name $rgName -Force
  }
}

if(!$?){
  Break
}

Write-Host "OS RECURSOS FORAM DELETADOS COM SUCESSO"
Get-AzResource | Where-Object {$_.Location -like $rgRegion}