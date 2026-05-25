param vnetGatewayName string = 'js-vpn-gw'
param location string = 'eastus'
param gwSharedKey string


module vnet './network.bicep' ={
  name: 'network'
}

var gatewaySubnetId = vnet.outputs.subnetIds.gatewaySubnet

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'js-gw-pip${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    publicIPAllocationMethod: 'static'
    dnsSettings: {
      domainNameLabel: 'js-gw-pip${uniqueString(resourceGroup().id)}'
    }
  }
  sku: {
    name: 'Standard'
  }
}


resource virtualNetworkGateway 'Microsoft.Network/virtualNetworkGateways@2025-05-01' = {
  name: vnetGatewayName
  location: 'eastus'
  properties: {
    enablePrivateIpAddress: false
    virtualNetworkGatewayMigrationStatus: {
      state: 'None'
      phase: 'None'
    }
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress.id
          }
          subnet: {
            id: gatewaySubnetId
          }
        }
      }
    ]
    natRules: []
    virtualNetworkGatewayPolicyGroups: []
    enableBgpRouteTranslationForNat: false
    disableIPSecReplayProtection: false
    sku: {
      name: 'Basic'
      tier: 'Basic'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    enableHighBandwidthVpnGateway: false
    activeActive: false
    vpnGatewayGeneration: 'Generation1'
    allowRemoteVnetTraffic: false
    allowVirtualWanTraffic: false
  }
}


resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2019-11-01' = {
  name: 'js-localgw-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }
    gatewayIpAddress: '141.152.229.55'
  }
}

resource vpnVnetConnection 'Microsoft.Network/connections@2020-11-01' = {
  name: 'udmS2Sconnection'
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: virtualNetworkGateway.id
      properties:{}
    }
    localNetworkGateway2: {
      id: localNetworkGateway.id
      properties:{}
    }
    connectionType: 'IPsec'
    routingWeight: 0
    sharedKey: gwSharedKey
  }
}


