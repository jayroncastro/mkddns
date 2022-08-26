# mkddns
Script RouterOS para atualização de DNS dinâmico DynDNS

## IMPORTANTE!!!
Este script consegue trabalhar de forma autônoma em equipamentos que possuem somente um link de internet, para equipamentos com mais de um link de internet e que utilizem a tecnologia PPPoE, é pré requisito ogrigatório à utilização do script [**pppoemarkmangle**](https://github.com/jayroncastro/pppoemarkmangle).

## Apresentação
A ideia de criar este script nasceu da necessidade de usar o DDNS para acessar um Mikrotik de forma externa à rede, sendo que o dispositivo possua mais de um link de internet com ip privado ou público.

Poderão ser criados vários hosts remotos nos sites que disponibilizam a tecnologia de DDNS e cada link poderá ter o seu ***nome de dns próprio***.

Na internet existem vários scripts com a mesma finalidade aqui abordada, mas todos servem para atualizar somente um host remoto e possuem a saída única pelo gateway padrão da tabela de roteamento.

O objetivo desse repositório é centralizar os scripts com tal finalidade, sendo segmentados por sites.

## Tabela de scripts

| Site | Script |
| --- | --- |
| DynDns | tal |

## Definição
As variáveis de controle estão listadas abaixo:

```
:global ddnsuser        "user";
:global ddnspwd         "password";
:global ddnshost        "qualquer.dnsalias.org";
:global localInterface  "ether1";
```

**ddnsuser:** variável que recebe o nome de usuário responsável pela conexão no site;
**ddnspwd:** variavel que recebe a senha do usuário;
**ddnshost:** variável que recebe o nome do host remoto para ser atualizado;
**localInterface:** variável que recebe o nome da interface do Mikrotik em que o link está chegando.

## Compatibilidade
Este script foi homologado para a versão 6.48.6 do RouterOS.

## Como usar
O administrador de rede deverá realizar previamente o cadastro junto ao site que possua a tecnologia ddns e que tenha o script disponibilizado na tabela de scripts.

Em posterior deverá fazer o download do código fonte e copiar para seu dispositivo Mikrotik, no caminho:

```
/system script add
```

Poderá ser criado um script por link de internet que o administrador necessite atualizar o ddns, o nome do script ficará a cargo do administrador, podendo ser qualquer nome aceito pelo sistema RouterOS.

As variáveis de controle deverão ser substituídas conforme cada cenário adotado.

## Segurança
Por razão de segurança no equipamento Mikrotik, o script deverá ter explicitamente as permissões abaixo:

- [ ] ftp
- [x] read
- [ ] policy
- [ ] password
- [ ] sensitive
- [ ] dude
- [ ] reboot
- [x] write
- [x] test
- [ ] sniff
- [ ] romon

## Sugestões e Melhorias
Sugestões, Bugs e melhorias podem ser informadas ou solicitadas via [Issues](https://github.com/jayroncastro/mkddns/issues)