targetScope = 'subscription'
param location string = 'eastus'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'iac-infra-rg'
  location: location
}

resource ephemeralRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'iac-ephem-rg'
  location: location
}

