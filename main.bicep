param location string
param adminName string
param prefix string
param vmHWType string
param vmCount int

@secure()
param vmPW string

@secure()
param sshKey1 string

@secure()
param sshKey2 string

// Combine Key Vault secrets here (not in .bicepparam — az.getSecret cannot nest in arrays/objects)
var sshPublicKeys = [
  sshKey1
  sshKey2
]

param gwSharedKey string

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
    gwSharedKey: gwSharedKey
    prefix: prefix
  }
  dependsOn: [
    vnet
  ]
}
