# firewall_rules

Manages the NSX-T firewall of one edge gateway from a plain, ordered rule list.

> `vcd_nsxt_firewall` owns the **entire** rule list of the edge gateway.
> Use exactly one instance of this module per edge gateway, and do not manage
> that gateway's firewall rules anywhere else. They would overwrite each other.
> Traffic that matches no rule hits the gateway's default deny rule.

## Owns

| Resource / data source                | Notes |
|---------------------------------------|-------|
| `vcd_nsxt_firewall`                   | The full ordered rule list (`count = 0` when `rules = []`) |
| `vcd_nsxt_ip_set`                     | One per non-empty rule side, keyed `<rule>-src` / `<rule>-dst` |
| `vcd_nsxt_app_port_profile` (TENANT)  | One per rule with `custom_ports`, named `<rule>-ports` |
| `data.vcd_nsxt_app_port_profile` (SYSTEM) | Lookup of built-in profiles (`SSH`, `HTTP`, `HTTPS`, `ICMP ALL`, …) by name with `context_id = vdc_id` |

## Inputs

| Name              | Type   | Default | Description |
|-------------------|--------|---------|-------------|
| `org`             | `string` | — | Organization name |
| `vdc_id`          | `string` | — | Org VDC ID, used as context for application port profiles |
| `edge_gateway_id` | `string` | — | Edge gateway ID |
| `rules`           | `list(object)` | `[]` | Ordered rules, evaluated top to bottom. See below |

Rule fields: `name` (unique, required), `action` (`ALLOW`\* / `DROP` / `REJECT`),
`direction` (`IN` / `OUT` / `IN_OUT`\*), `ip_protocol` (`IPV4`\* / `IPV6` / `IPV4_IPV6`),
`enabled` (`true`\*), `logging` (`false`\*), `source_ip_addresses`,
`destination_ip_addresses`, `app_port_profiles` (built-in names),
`custom_ports` (`[{ protocol, ports? }]`). Empty lists mean "any". \* = default.

Renaming a rule replaces its IP sets and custom profile, because they are keyed by rule name.

## Outputs

| Name         | Description |
|--------------|-------------|
| `rule_ids`   | Map of rule name → firewall rule ID |
| `ip_set_ids` | Map of IP set name → ID |

## Tests

```bash
terraform init -backend=false && terraform test
```
