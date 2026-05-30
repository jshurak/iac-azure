
@description('location for our resources')
param location string

@description('default admin name for vms')
param adminName string

@description('prefix to assist in naming resources')
param prefix string

@description('vm sku name')
param vmHWType string

@description('vm count.  Also manages vNic count')
param vmCount int


@description('Our subscription.  Provided via github actions. Required for pulling from keyvault during deployment')
param subscription string

@description('Our Key Vault Resource Group.  Provided via github actions. Required for pulling from keyvault during deployment')
param keyVaultResourceGroupName string

@description('Key Vault Name. Provided via github actions. Required for pulling from keyvault during deployment')
param keyVaultName string

@description('Vm admin password.  Stored in Key vault.')
@secure()
param vmPW string

@description('Vm admin ssh public key.  Stored in Key vault.')
@secure()
param adminSSHKey string

@description('Gateway connection shared key.  Stored in Key vault.')
@secure()
param gwSharedKey string


@description('This creates an array for public keys to add to vms if additional keys are required.')
var sshPublicKeys = [
  adminSSHKey
  //SSHKey2
  //SSHKey3
]


module vnet './modules/network.bicep' = {
  name: 'vnetDeployment'
  params:{
    location:location
    prefix: prefix
  }

}

module compute './modules/compute.bicep' = {
  name: 'computeDeployment'
  params: {
    adminName: adminName
    vmPW: vmPW
    location: location
    prefix: prefix
    vmCount: vmCount
    vmHWType: vmHWType
    sshPublicKeys: sshPublicKeys
  }
  dependsOn: [
    vnet
  ]
}

module gateway './modules/gateway.bicep' = {
  name: 'gatewayDeployment'
  params: {
    prefix: prefix
    gwSharedKey: gwSharedKey
  }
  dependsOn: [
    vnet
  ]
}
