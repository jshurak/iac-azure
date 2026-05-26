using './main.bicep'


param location = 'eastus'
param vmCount = 2
param prefix = 'js'
param adminName = 'js-admin'
param vmPW = az.getSecret('01884496-61d8-43f9-af5a-dc218de550e1','js-infra-aa-rg','js-kv-infra','vm-pw')
param vmHWType = 'Standard_B1ls'
param gwSharedKey = az.getSecret('01884496-61d8-43f9-af5a-dc218de550e1','js-infra-aa-rg','js-kv-infra','gw-shared-key')
param sshKey1 = az.getSecret('01884496-61d8-43f9-af5a-dc218de550e1', 'js-infra-aa-rg', 'js-kv-infra', 'ssh-ICE')
param sshKey2 = az.getSecret('01884496-61d8-43f9-af5a-dc218de550e1', 'js-infra-aa-rg', 'js-kv-infra', 'ssh-jssvr01')
