Param (
    [string]$user,
    [string]$pass,
    [string]$domain
)

Install-WindowsFeature -Name Web-Server -IncludeManagementTools

$username = "$user@$domain"

$password = ConvertTo-SecureString $pass -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username,$password

# Na hora que essa Extension começa a ser executada, a vm-ad ainda não estará contactável para ingressar no domínio. Por isso, o do/while executará até que essa VM consiga ingressar no domínio.
do{
    Add-Computer -DomainName $domain -DomainCredential $Credential -ErrorAction 'silentlycontinue'
    if($?){
        $adJoinSucceded = $true
        Break
    }else{
        $adJoinSucceded = $false
    }
}while($adJoinSucceded -ne $true)
