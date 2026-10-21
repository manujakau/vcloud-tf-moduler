# routed_network

Creates one NSX-T routed Org network attached to an edge gateway, with an
optional edge DHCP pool. Instantiate it once per network.

## Owns

| Resource                 | Notes |
|--------------------------|-------|
| `vcd_network_routed_v2`  | The routed network |
| `vcd_nsxt_network_dhcp`  | Only when `dhcp_pool` is set (`count = 1`) |

## Inputs

| Name              | Type   | Default | Description |
|-------------------|--------|---------|-------------|
| `org`             | `string` | — | Organization name |
| `name`            | `string` | — | Network name |
| `description`     | `string` | `null` | Description |
| `edge_gateway_id` | `string` | — | Edge gateway ID |
| `interface_type`  | `string` | `"INTERNAL"` | `INTERNAL`, `DISTRIBUTED`, `SUBINTERFACE`, `NON_DISTRIBUTED` (case-insensitive) |
| `gateway`         | `string` | — | Gateway IP; must be a host address, not the network/broadcast address (precondition) |
| `prefix_length`   | `number` | `24` | |
| `dns1` / `dns2`   | `string` | `null` | DNS servers (also handed out by DHCP) |
| `dns_suffix`      | `string` | `null` | |
| `static_ip_pools` | `list(object({ start_address, end_address }))` | `[]` | |
| `dhcp_pool`       | `object({ start_address, end_address, lease_time = 86400 })` | `null` | Enables edge DHCP |

## Outputs

| Name              | Description |
|-------------------|-------------|
| `network_id`      | Network ID |
| `network_name`    | Network name |
| `network_gateway` | Gateway IP |

## Tests

```bash
terraform init -backend=false && terraform test
```
