using './compute.bicep'

param location = 'eastus'
param vmCount = 3
param prefix = 'js'
param adminName = 'js-admin'
param vmPW = az.getSecret('01884496-61d8-43f9-af5a-dc218de550e1','js-infra-aa-rg','js-kv-infra','vm-pw')
//param subnetID = '/subscriptions/01884496-61d8-43f9-af5a-dc218de550e1/resourceGroups/iac-infra-rg/providers/Microsoft.Network/virtualNetworks/js-vnet/subnets/vmSubnet'
param vmHWType = 'Standard_B1ls'

