Param (
    [string]$domain,
    [string]$pass
)
Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools

$securePassword = ConvertTo-SecureString $pass -AsPlainText -Force
$domain = "fabrikan.local"
$netbiosName = $domain.Split(".")
$netbiosName = $netbiosName[0].ToUpper()

Install-ADDSForest -DomainName $domain -DomainNetBIOSName $netbiosName -InstallDNS -SafeModeAdministratorPassword $securePassword -NoRebootOnCompletion -Force