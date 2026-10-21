# nat_rules

Manages DNAT and SNAT rules on one NSX-T edge gateway.

## Owns

| Resource / data source                     | Notes |
|--------------------------------------------|-------|
| `vcd_nsxt_nat_rule.dnat`                   | One per `dnat_rules` entry |
| `vcd_nsxt_nat_rule.snat`                   | One per `snat_rules` entry |
| `data.vcd_nsxt_app_port_profile` (SYSTEM)  | Lookup of built-in profiles referenced by DNAT rules, with `context_id = vdc_id` |

Unlike `vcd_nsxt_firewall`, NAT rules are individual resources, so other
configurations may add NAT rules to the same gateway without conflict.

## Inputs

| Name              | Type   | Default | Description |
|-------------------|--------|---------|-------------|
| `org`             | `string` | — | Organization name |
| `vdc_id`          | `string` | — | Org VDC ID, used as context for application port profile lookups |
| `edge_gateway_id` | `string` | — | Edge gateway ID |
| `dnat_rules`      | `map(object)` | `{}` | `external_address` (an edge gateway allocated IP) → `internal_address` (VM). Optional: `name` (defaults to the map key), `description`, `enabled`, `logging`, `dnat_external_port`, `app_port_profile` (built-in name), `firewall_match`, `priority` |
| `snat_rules`      | `map(object)` | `{}` | `internal_address` (source CIDR) → `external_address` (an edge gateway allocated IP). Optional: `name`, `description`, `enabled`, `logging`, `snat_destination_address`, `firewall_match`, `priority` |

## Outputs

| Name       | Description |
|------------|-------------|
| `dnat_ids` | Map of DNAT rule key → ID |
| `snat_ids` | Map of SNAT rule key → ID |

## Tests

```bash
terraform init -backend=false && terraform test
```
