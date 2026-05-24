param virtualNetworkGateways_js_vpn_gw_name string = 'js-vpn-gw'
param virtualNetworks_js_vnet_externalid string = '/subscriptions/01884496-61d8-43f9-af5a-dc218de550e1/resourceGroups/iac-infra-rg/providers/Microsoft.Network/virtualNetworks/js-vnet'
param location string = 'eastus'
param gwSharedKey string

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
  name: virtualNetworkGateways_js_vpn_gw_name
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
            id: '${virtualNetworks_js_vnet_externalid}/subnets/gatewaySubnet'
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


