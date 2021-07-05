Param (
    [string]$user,
    [string]$pass,
    [string]$domain
)

Install-WindowsFeature -Name Web-Server -IncludeManagementTools

$username = "$user@$domain"

$password = ConvertTo-SecureString $pass -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username,$password
$adJoin = $null

do{
    Add-Computer -DomainName $domain -DomainCredential $Credential -ErrorAction 'silentlycontinue'
    if($?){
        $adJoinSucceded = $true
    }else{
        $adJoinSucceded = $false
    }
}while($adJoinSucceded -ne $true)
