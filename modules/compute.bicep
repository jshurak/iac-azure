param location string 
param vmCount int
param prefix string
param adminName string
param vmHWType string

@secure()
param vmPW string

module vnet './network.bicep' ={
  name: 'network'
}

var computeSubnetId = vnet.outputs.subnetIds.vmSubnet

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-11-01' = [for i in range(1,vmCount):{
  name: '${prefix}-nic-0${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'name'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: computeSubnetId
          }
        }
      }
    ]
  }
}]


resource ansibleVMs 'Microsoft.Compute/virtualMachines@2020-12-01' = [for i in range(0,vmCount): {
  name: '${prefix}-vm-0${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmHWType
    }
    osProfile: {
      computerName: '${prefix}0${i}'
      adminUsername: adminName
      adminPassword: vmPW
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-26_04-lts'
        sku: 'server'
        version: '26.04.202604210'
      }
      osDisk: {
        name: '${prefix}-disk-0${i}'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface[i].id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}]
