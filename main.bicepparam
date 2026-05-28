using './main.bicep'


param location = 'eastus'
param vmCount = 3
param prefix = 'js'
param adminName = 'js-admin'
param vmPW = az.getSecret(subscription,keyVaultResourceGroupName,keyVaultName,'vm-pw')
param vmHWType = 'Standard_B1ls'

param subscription = ''
param keyVaultResourceGroupName = ''
param keyVaultName = ''


param gwSharedKey = az.getSecret(subscription,keyVaultResourceGroupName,keyVaultName,'gw-shared-key')
param adminSSHKey = az.getSecret(subscription, keyVaultResourceGroupName, keyVaultName, 'ssh-jssvr01')


