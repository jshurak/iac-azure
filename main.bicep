param location string
param adminName string
param prefix string
param vmHWType string
param vmCount int

param subscription string
param keyVaultResourceGroupName string
param keyVaultName string


@secure()
param vmPW string

@secure()
param sshKey1 string

@secure()
param sshKey2 string

@secure()
param gwSharedKey string

var sshPublicKeys = [
  sshKey1
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
