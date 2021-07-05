## Objetivo

* Realizar o deploy de recursos básicos do Azure utilizando ARM Templates e PowerShell;
* Praticar o deploy de recursos utilizando IaC com ARM Template e também praticar PowerShell;
* Praticar o uso do VCS (Version Control Software) Git, bem como do VCS remoto, o GitHub;
* Sem qualquer interação além da execução inicial do script, montar todo o ambiente, executar as Extensions e ser capaz de, ao término, acessar o FQDN da VM do IIS, vm-iis, logo após ela ter ingressado no domínio, via browser a partir da vm-ad e conseguir visualizar a página padrão do IIS.

## O ambiente

O ambiente é composto por:

* Um KeyVault, cujo nome será gerado randomicamente e que contará com dois Secrets, um para a senha de administrador das VMs (vmPass), que serão iguais para todas as VMs e um para a senha de recuperação do Active Directory (addsRecovery). Ambos os nomes podem ser alterados por meio das variáveis "$keyvaultPassSecret" e "$keyvaultADDSRecoverySecret";
* Uma VNET (vnet-lab), que irá contar com apenas uma subnet (subnet-servers);
* Um Network Security Group (NSG), que permitirá o tráfego de entrada para a subnet associada nas portas 80 (http) para acessar o IIS e RDP (3389) para acessar as VMs. Vale ressaltar que as boas práticas não recomendam que o PIP (Public IP) seja vinculado à VM, mas sim para um appliance ou serviço que faça o forwarding, como o Azure Firewall, o Application Gateway ou o Load Balancer. Nesse caso, utilizei o PIP direto na VM para acelerar o processo. Além disso, o NSG utilizará o IP público de quem estiver rodando o script para criar uma regra de inbound com base nele. Com isso, somente o executor do script terá acesso via RDP às VMs;
* Duas VMs, sendo uma para Active Directory Domain Services e outra para IIS;
* Tanto a feature de ADDS quanto de IIS são instaladas nas VMs por meio de Extensions. Não é preciso instalar nenhum desses serviços manualmente;
* O arquivo "powershell.ps1" é o script principal, é a partir dele que todo o resto é puxado. Para fazer tudo funcionar, basta executá-lo. Lembrando que é preciso descomentar o primeiro comando, que irá se conectar à conta do Azure, no tenant definido.

## Passos da execução do script:

1. Conecta-se à conta vinculada ao Azure;
2. As variáveis são criadas, bem como o nome randômico do KeyVault e também, o IP público do executor é coletado para que uma regra no NSG seja criada posteriormente
3. Cria-se o Resource Group
4. Cria-se o KeyVault, bem como os Secrets para armazenar as chaves de admin das VMs e de recuperação do ADDS;
5. Ao criar as VMs, será usado um documento de parâmetros para o ARM Template "resourcesDeploy.json" que irá referenciar o KeyVault. Esse arquivo é populado utilizando os dados do KeyVault, como nome (gerado randomicamente) e o nome dos Secrets. Isso é feito tanto para recuperar as chaves das VMs quanto para recuperar a chave de recuperação do ADDS e acontece entre as linhas 92 e 102;
6. Os recursos são criados;
7. O IP privado da vm-ad é definido como estático dentro do Azure;
8. A função do ADDS é instalada por meio de uma Extension, executando outro script PowerShell (adConfig.ps1);
9. O DNS da VNET é atualizado com base no IP privado da vm-ad, coletado a partir do output do ARM-Template que fez o deploy dos recursos;
10. As VMs são reiniciadas para que a alteração do DNS seja aplicada;
11. A Extension que instalará o IIS e ingressará a vm-iis ao domínio é executada. Como a vm-ad estará em processo de configuração pós reboot, foi criado um loop de do/while dentro do iisConfig.ps1 (script responsável por esse processo) para que execute até que a vm-iis consiga ingressar no domínio.;
12. Por fim, uma credencial é criada usando cmdkey.exe para acessar a vm-ad e verificar se todos os processos foram bem sucedidos. A sessão de RDP é aberta automaticamente.

## Observações

* Esse script foi desenvolvido unica e exclusivamente para fins de estudos, possíveis bugs podem aparecer;
* Pretendo utilizar esse mesmo ambiente futuramente para aplicar outros conhecimentos, como incluir um Scale Set para o IIS atrás de um Load Balancer.