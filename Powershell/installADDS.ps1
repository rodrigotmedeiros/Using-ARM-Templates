Param (
    [string]$pass
)

New-Item -Path "C:\" -Name "testfile1.txt" -ItemType "file" -Value $pass

Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools

$securePassword = ConvertTo-SecureString $pass -AsPlainText -Force

Install-ADDSForest -DomainName recruitlab.local -DomainNetBIOSName RECRUITLAB -InstallDNS -SafeModeAdministratorPassword $securePassword -NoRebootOnCompletion -Force