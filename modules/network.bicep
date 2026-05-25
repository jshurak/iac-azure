param location string = 'eastus'



param subnets array = ['gateway','vm']


resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'js-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
  /*  subnets: [
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
    ]*/
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2025-05-01' = [for name in subnets: {
  parent:virtualNetwork
  name: '${name}Subnet'
  properties: {
    addressPrefix: '10.2.${indexOf(subnets,name)}.0/24'
  }
}]


var subnetInfo = [for name in subnets: {
  name: '${name}Subnet'
  subnetID: subnet[indexOf(subnets, name)].id
}]

output subnetInfo array = subnetInfo

// name-keyed map so consumers can use subnetIds['gatewaySubnet'] without array index
output subnetIds object = toObject(subnetInfo, item => item.name, item => item.subnetID)


