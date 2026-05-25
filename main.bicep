param location string
param adminName string
param prefix string
param vmHWType string
param vmCount int

@secure()
param vmPW string

param gwSharedKey string

module vnet './modules/network.bicep' = {
  name: 'vnetDeployment'
  params:{
    location:location
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
  }
  dependsOn: [
    vnet
  ]
}

module gateway './modules/gateway.bicep' = {
  name: 'gatewayDeployment'
  params: {
    gwSharedKey: gwSharedKey
  }
  dependsOn: [
    vnet
  ]
}
