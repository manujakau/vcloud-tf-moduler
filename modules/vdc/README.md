# vdc

Creates an Org VDC (datacenter) inside an existing organization.

## Owns

| Resource      | Notes |
|---------------|-------|
| `vcd_org_vdc` | One Org VDC, including its compute capacity and storage profiles |

## Inputs

| Name                       | Type   | Default | Description |
|----------------------------|--------|---------|-------------|
| `org`                      | `string` | — | Organization name |
| `name`                     | `string` | — | VDC name |
| `description`              | `string` | `null` | Description |
| `provider_vdc_name`        | `string` | — | Provider VDC to allocate from |
| `allocation_model`         | `string` | — | `AllocationVApp`, `AllocationPool`, `ReservationPool` or `Flex` (not validated by the module) |
| `network_pool_name`        | `string` | — | Network pool (NSX-T Geneve pool) |
| `cpu_allocated`            | `number` | — | CPU allocation in MHz |
| `memory_allocated`         | `number` | — | Memory allocation in MB |
| `storage_profile`          | `list(object({ name, limit, default, enabled }))` | — | All four fields are **required** per entry |
| `enable_thin_provisioning` | `bool`   | `false` | |
| `enable_fast_provisioning` | `bool`   | `false` | |
| `nic_quota`                | `number` | `0` | `0` = unlimited |
| `network_quota`            | `number` | `10` | `0` = **no** networks can be created |
| `vm_quota`                 | `number` | `0` | `0` = unlimited |
| `memory_guaranteed`        | `number` | `null` | AllocationVApp/AllocationPool/Flex only |
| `cpu_guaranteed`           | `number` | `null` | AllocationVApp/AllocationPool/Flex only |
| `enabled`                  | `bool`   | `true` | |
| `delete_force`             | `bool`   | `false` | Delete the VDC even if it contains objects |
| `delete_recursive`         | `bool`   | `false` | Delete the VDC's contents recursively |

> The pre-catalog root module defaulted `delete_force` / `delete_recursive` to
> `true` and made `storage_profile[*].default` / `enabled` optional (`true`).
> Callers migrating from it must pass those values explicitly.

## Outputs

| Name       | Description |
|------------|-------------|
| `vdc_id`   | Org VDC ID (consumed as `owner_id` by `edge_gateway`, and as `vdc_id` by `firewall_rules` / `nat_rules`) |
| `vdc_name` | Org VDC name |

## Tests

```bash
terraform init -backend=false && terraform test
```
