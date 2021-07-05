## Objetivo

* Realizar o deploy de recursos básicos do Azure utilizando ARM Templates e PowerShell;
* Praticar o deploy de recursos utilizando IaC com ARM Template e também praticar PowerShell;
* Praticar o uso do VCS (Version Control Software) Git, bem como do VCS remoto, o GitHub;
* Sem qualquer interação além da execução inicial do script, montar todo o ambiente, executar as Extensions e ser capaz de, ao término, acessar o FQDN da VM do IIS, vm-iis, após esta ter ingressado no domínio, via browser a partir da vm-ad e conseguir visualizar a página padrão do IIS.

## O ambiente

O ambiente é composto por:

* Um KeyVault, cujo nome será gerado randomicamente e que contará com dois Secrets, um para a senha de administrador das VMs (vmPass), que serão iguais para todas as VMs e um para a senha de recuperação do Active Directory (addsRecovery). Ambos os nomes podem ser alterados por meio das variáveis "$keyvaultPassSecret" e "$keyvaultADDSRecoverySecret";
* Uma VNET (vnet-lab), que irá contar com apenas uma subnet (subnet-servers);
* Um Network Security Group (NSG), que permitirá o tráfego de entrada para a subnet associada nas portas 80 (http) para acessar o IIS e RDP (3389) para acessar as VMs. Vale ressaltar que as boas práticas não recomendam que o PIP (Public IP) seja vinculado à VM, mas sim para um appliance ou serviço que faça o forwarding, como o Azure Firewall, o Application Gateway ou o Load Balancer. Nesse caso, utilizei o PIP direto na VM para acelerar o processo. Além disso, o NSG utilizará o IP público de quem estiver rodando o script para criar uma regra de inbound com base nele. Com isso, somente o executor do script terá acesso via RDP às VMs;
* Duas VMs, sendo uma para Active Directory Domain Services e outra para IIS;
* Tanto a feature de ADDS quanto de IIS são instaladas nas VMs por meio de Extensions. Não é preciso instalar nenhum desses serviços manualmente.

## Observações

* Esse script foi desenvolvido unica e exclusivamente para fins de estudos, possíveis bugs podem aparecer;
* Pretendo utilizar esse mesmo ambiente futuramente para aplicar outros conhecimentos, como incluir um Scale Set para o IIS atrás de um Load Balancer.