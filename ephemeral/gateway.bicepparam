using './gateway.bicep'



param gwSharedKey = az.getSecret('01884496-61d8-43f9-af5a-dc218de550e1','js-infra-aa-rg','js-kv-infra','gw-shared-key')


