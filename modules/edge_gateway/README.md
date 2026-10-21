# edge_gateway

Creates an NSX-T edge gateway (Tier-1) in an Org VDC, uplinked to a Tier-0
backed external network.

## Owns

| Resource / data source             | Notes |
|------------------------------------|-------|
| `vcd_nsxt_edgegateway`             | One edge gateway |
| `data.vcd_external_network_v2`     | Looks up the external network by name (read-only, needs VCD access at plan time) |

## Inputs

| Name                        | Type   | Default | Description |
|-----------------------------|--------|---------|-------------|
| `org`                       | `string` | — | Organization name |
| `owner_id`                  | `string` | — | ID of the owning Org VDC (or VDC group) |
| `name`                      | `string` | — | Edge gateway name |
| `description`               | `string` | `null` | Description |
| `external_network_name`     | `string` | — | NSX-T Tier-0 backed external network name |
| `subnets`                   | `list(object({ gateway, prefix_length, primary_ip?, allocated_ips = list({ start_address, end_address }) }))` | — | Uplink subnets. `primary_ip` must fall inside `allocated_ips` |
| `dedicate_external_network` | `bool`   | `false` | Dedicate the Tier-0 to this gateway |
| `edge_cluster_id`           | `string` | `null` | NSX-T edge cluster; inherited from the external network when `null` |

## Outputs

| Name           | Description |
|----------------|-------------|
| `gateway_id`   | Edge gateway ID (consumed by `routed_network`, `firewall_rules`, `nat_rules`) |
| `gateway_name` | Edge gateway name |
| `primary_ip`   | Primary uplink IP |

## Tests

```bash
terraform init -backend=false && terraform test
```
