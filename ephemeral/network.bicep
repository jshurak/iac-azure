param location string = 'eastus'


resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'js-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'gatewaySubnet'
        properties: {
          addressPrefix: '10.2.0.0/24'
        }
      }
      {
        name: 'vmSubnet'
        properties:{
          addressPrefix: '10.2.1.0/24'
        }
      }
    ]
  }
}
