@description('Location of the resources')
param location string 

@description('Number of vms to create')
param vmCount int

@description('Prefix for resources')
param prefix string

@description('admin account for vms')
param adminName string

@description('VM hardware type')
param vmHWType string


@description('Password for vm admin accounts. Pulled from Keyvault.')
@secure()
param vmPW string

param sshPublicKeys array

module vnet './network.bicep' ={
  name: 'network'
  params:{
    location:location
    prefix: prefix
  }
}

var computeSubnetId = vnet.outputs.subnetIds.vmSubnet

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-11-01' = [for i in range(0,vmCount):{
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
      linuxConfiguration: {
        ssh: {
          publicKeys: [for key in sshPublicKeys: {
            path: '/home/${adminName}/.ssh/authorized_keys'
            keyData: key
          }]
        }
      }
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
