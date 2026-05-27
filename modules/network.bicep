param location string
param prefix string



param subnets array = ['gateway','vm']


resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: '${prefix}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
    subnets: [for name in subnets: {
      name: '${name}Subnet'
      properties: {
        addressPrefix: '10.2.${indexOf(subnets,name)}.0/24'
      }
    }]
  } 
}

resource subs 'Microsoft.Network/virtualNetworks/subnets@2019-11-01' existing = [for name in subnets: {
  parent: virtualNetwork
  name: '${name}Subnet'
}]


var subnetInfo = [for (name, i) in subnets: {
  name: '${name}Subnet'
  subnetID: subs[i].id
}]

output subnetInfo array = subnetInfo

// name-keyed map so consumers can use subnetIds['gatewaySubnet'] without array index
output subnetIds object = toObject(subnetInfo, item => item.name, item => item.subnetID)


