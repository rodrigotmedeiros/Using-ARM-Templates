## Objective:

In order to practice some Powershell and ARM Tamplate scripting, I decided to build this simple enviroment based on a friend's job interview lab. The objective of this lab was to deploy an an ADDS server, an IIS server and a client that would access the webserver using its FQDN.

## The environment:

* Three VMs: An Active Directory Domain Service server (vm-ad), an IIS server (vm-iis) and a client server (vm-client), all of them running on Windows Server 2019 Datacenter. I'm limited to use only 4 vCPU as I don't have a Pay-as-you-go account. I could use vNET Peering, but that was not the objective of this lab, maybe next time!;
* One Network Security Group to allow RDP. As we're going to use Standard PIP that denies all inbound connections by default, we need to associate a NSG. We create a NSG rule to allow only connections from the client's public IP address. For that, we collect the user's PIP from ifconfig.me;
* An Azure KeyVault to store the VM's passwords;
* A Powershell script to run the ARM Templates.

All we need to do is to run the code and it'll do all the job on its own no need to manually install the roles or to join the domain. :D
After checking if everythings is ok, we can run the rg-purge.json to delete the resources.

## NOTE

Altough I have left a domain account's password in plain text inside the "IISIngressDomain.ps1" script, it's not recomended! Keep all your secrets inside a KeyVault or any other key store of your choice, not in the code!
