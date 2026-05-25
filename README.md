# Azure Infrastructure (Bicep)

Infrastructure-as-code for an Azure environment with a virtual network, VPN gateway (site-to-site), and Linux VMs. Templates are written in [Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/overview) and organized into reusable modules.

## Architecture

```mermaid
flowchart TB
  subgraph vnet["js-vnet (10.2.0.0/16)"]
    gwSubnet["gatewaySubnet<br/>10.2.0.0/24"]
    vmSubnet["vmSubnet<br/>10.2.1.0/24"]
  end

  subgraph gateway["VPN Gateway"]
    pip["Public IP"]
    vng["Virtual Network Gateway"]
    lng["Local Network Gateway"]
    conn["Site-to-Site Connection"]
  end

  subgraph compute["Compute"]
    nic["Network Interfaces"]
    vm["Ubuntu VMs"]
  end

  pip --> vng
  vng --> gwSubnet
  vng --> conn
  lng --> conn
  nic --> vmSubnet
  vm --> nic
```

| Component | Purpose |
|-----------|---------|
| **Virtual network** | `js-vnet` with dynamically declared subnets |
| **VPN gateway** | Route-based IPsec VPN to an on-premises/local endpoint (`10.10.0.0/16`) |
| **Virtual machines** | Ubuntu 26.04 LTS VMs on `vmSubnet`, sized via parameters |

## Repository layout

```
azure/
├── main.bicep              # Orchestrates network, compute, and gateway modules
├── main.bicepparam         # Parameters for full-stack deployment (includes Key Vault secrets)
└── modules/
    ├── rg.bicep            # Subscription-scoped: creates resource group
    ├── network.bicep       # VNet and subnets; exports subnet IDs
    ├── gateway.bicep       # VPN gateway, local gateway, and connection
    ├── compute.bicep       # NICs and VMs
    ├── gateway.bicepparam  # Standalone gateway deployment params
    └── compute.bicepparam  # Standalone compute deployment params
```

## Modules

### `network.bicep`

Creates `js-vnet` (`10.2.0.0/16`) and subnets from the `subnets` parameter (default: `['gateway', 'vm']`). Subnet names follow `{name}Subnet` (e.g. `gatewaySubnet`, `vmSubnet`). Address prefixes are assigned as `10.2.{index}.0/24` based on position in the array.

**Outputs:**

| Output | Type | Description |
|--------|------|-------------|
| `subnetInfo` | `array` | `{ name, subnetID }` per subnet |
| `subnetIds` | `object` | Name-keyed map for lookup without array indexes |

Example consumer lookup:

```bicep
module vnet './network.bicep' = { name: 'network' }

var gatewaySubnetId = vnet.outputs.subnetIds.gatewaySubnet
var vmSubnetId = vnet.outputs.subnetIds.vmSubnet
```

`subnetIds` is built with `toObject()` inside the network module so callers can reference subnets by name. Filtering module output arrays in a parent `var` with a `for`-expression is not supported (BCP178).

To add a subnet, append to the `subnets` array in `network.bicep`; a new entry appears in both outputs automatically.

### `gateway.bicep`

Deploys:

- Standard public IP for the gateway
- Virtual network gateway (Basic SKU, route-based VPN) on `gatewaySubnet`
- Local network gateway (peer `10.10.0.0/16`, fixed public IP in template)
- Site-to-site IPsec connection (`udmS2Sconnection`)

Embeds the network module and resolves the gateway subnet via `vnet.outputs.subnetIds.gatewaySubnet`.

### `compute.bicep`

Deploys a configurable count of VMs (`vmCount`) with matching NICs on `vmSubnet`. Default image: Canonical Ubuntu 26.04 LTS (`server` SKU). Also embeds the network module for standalone use.

### `rg.bicep`

Subscription-scoped template that creates the `iac-infra-rg` resource group. Deploy this first if the target group does not exist.

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) with Bicep support (`az bicep install`)
- An Azure subscription and rights to deploy networking, compute, and Key Vault–backed secrets
- For parameterized deployments: a Key Vault (`js-kv-infra` in `js-infra-aa-rg`) with secrets referenced in `*.bicepparam` files

## Secrets and parameters

Sensitive values are loaded from Key Vault in parameter files, not stored in the repo:

| Secret (Key Vault) | Used for |
|--------------------|----------|
| `vm-pw` | VM admin password |
| `gw-shared-key` | VPN IPsec shared key |

Example from `main.bicepparam`:

```bicep
param vmPW = az.getSecret('<subscriptionId>', 'js-infra-aa-rg', 'js-kv-infra', 'vm-pw')
param gwSharedKey = az.getSecret('<subscriptionId>', 'js-infra-aa-rg', 'js-kv-infra', 'gw-shared-key')
```

Replace `<subscriptionId>` with your subscription ID. Deploying with `*.bicepparam` requires appropriate Key Vault access (e.g. RBAC **Key Vault Secrets User** on the vault).

### Main deployment parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `location` | Azure region | `eastus` |
| `vmCount` | Number of VMs | `3` |
| `prefix` | Name prefix for VMs, NICs, disks | `js` |
| `adminName` | VM admin username | `js-admin` |
| `vmHWType` | VM size | `Standard_B1ls` |
| `vmPW` | Admin password (secure) | From Key Vault |
| `gwSharedKey` | VPN shared key (secure) | From Key Vault |

## Deployment

### 1. Create the resource group (if needed)

```bash
az deployment sub create \
  --location eastus \
  --template-file modules/rg.bicep
```

### 2. Full stack (recommended entry point)

Deploys network, compute, and gateway from `main.bicep`:

```bash
az deployment group create \
  --resource-group iac-infra-rg \
  --template-file main.bicep \
  --parameters main.bicepparam
```

`compute` and `gateway` modules declare `dependsOn: [ vnet ]` so the root network module completes first.

> **Note:** `compute.bicep` and `gateway.bicep` each include their own `network.bicep` module for standalone deployments. When invoked from `main.bicep`, they still nest a network module internally. For a single shared VNet in production, pass `subnetIds` from the root `vnet` module into compute/gateway and remove the nested network modules.

### 3. Deploy individual modules

Useful for testing or partial updates. Target resource group `iac-infra-rg`:

```bash
# Network only
az deployment group create \
  --resource-group iac-infra-rg \
  --template-file modules/network.bicep

# Gateway only (requires existing VNet/subnets or accepts nested network deploy)
az deployment group create \
  --resource-group iac-infra-rg \
  --template-file modules/gateway.bicep \
  --parameters modules/gateway.bicepparam

# Compute only
az deployment group create \
  --resource-group iac-infra-rg \
  --template-file modules/compute.bicep \
  --parameters modules/compute.bicepparam
```

### Validate templates locally

```bash
az bicep build --file main.bicep
az bicep build --file modules/network.bicep
az bicep build --file modules/gateway.bicep
az bicep build --file modules/compute.bicep
```

## What gets created (default)

| Resource | Name / pattern |
|----------|----------------|
| Virtual network | `js-vnet` |
| Subnets | `gatewaySubnet`, `vmSubnet` |
| Public IP | `js-gw-pip{uniqueString}` |
| VPN gateway | `js-vpn-gw` |
| Local network gateway | `js-localgw-{uniqueString}` |
| Connection | `udmS2Sconnection` |
| NICs | `{prefix}-nic-0{n}` |
| VMs | `{prefix}-vm-0{n}` |

## Customization

- **Subnets:** Edit the `subnets` array in `modules/network.bicep` and reference new keys on `subnetIds` in other modules (e.g. `subnetIds.dbSubnet`).
- **VPN peer:** Update `localNetworkGateway` properties in `modules/gateway.bicep` (address space, `gatewayIpAddress`).
- **VM image/size:** Adjust `storageProfile.imageReference` and `vmHWType` in compute templates/params.
- **Region:** Set `location` in `main.bicepparam` and ensure child modules use the same region consistently.

## Related documentation

- [Bicep modules](https://learn.microsoft.com/azure/azure-resource-manager/bicep/modules)
- [Bicep parameters files](https://learn.microsoft.com/azure/azure-resource-manager/bicep/parameter-files)
- [Use Key Vault secrets in parameter files](https://learn.microsoft.com/azure/azure-resource-manager/bicep/key-vault-parameter)
- [Azure VPN Gateway](https://learn.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpngateways)
