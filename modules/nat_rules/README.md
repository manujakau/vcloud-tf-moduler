# nat_rules

Manages DNAT and SNAT rules on one NSX-T edge gateway, plus optional named IP
sets that NAT rules can take their addresses from.

## Owns

| Resource / data source                     | Notes |
|--------------------------------------------|-------|
| `vcd_nsxt_ip_set.this`                     | One per `ip_sets` entry |
| `vcd_nsxt_nat_rule.dnat`                   | One per `dnat_rules` entry |
| `vcd_nsxt_nat_rule.snat`                   | One per `snat_rules` entry |
| `data.vcd_nsxt_app_port_profile` (SYSTEM)  | Lookup of built-in profiles referenced by DNAT rules, with `context_id = vdc_id` |

Unlike `vcd_nsxt_firewall`, NAT rules are individual resources, so other
configurations may add NAT rules to the same gateway without conflict.

## IP sets → NAT rules

`vcd_nsxt_nat_rule` has no IP set reference in VCD; its addresses are plain
strings. To keep each address defined once, a rule can name an IP set
(`*_ip_set`) instead of a raw address (`*_address`). The module then puts the
set's address into the rule.

- For each address, set **either** the raw value **or** the IP set key, not both
  (checked by a precondition).
- A set used by a NAT rule must contain **exactly one** IP or CIDR. Sets with
  several entries are still created, e.g. for firewall rules via `ip_set_ids`,
  but can't back a NAT address.
- Renaming a set's key replaces the IP set. Changing its address updates both
  the set and every rule that references it in the same apply.
- IP set names must be unique on the edge gateway. The `firewall_rules` module
  creates sets named `<rule>-src` / `<rule>-dst` on the same gateway, so avoid
  those names.

```hcl
ip_sets = {
  app-net = { ip_addresses = ["10.0.1.0/24"], description = "App network" }
  egw-ip  = { ip_addresses = ["192.0.2.2"] }     # edge gateway allocated IP
  web-vm  = { ip_addresses = ["10.0.1.10"] }
}
dnat_rules = {
  web-dnat = { external_ip_set = "egw-ip", internal_ip_set = "web-vm", app_port_profile = "HTTP" }
}
snat_rules = {
  outbound = { internal_ip_set = "app-net", external_ip_set = "egw-ip" }
}
```

## Inputs

| Name              | Type   | Default | Description |
|-------------------|--------|---------|-------------|
| `org`             | `string` | — | Organization name |
| `vdc_id`          | `string` | — | Org VDC ID, used as context for application port profile lookups |
| `edge_gateway_id` | `string` | — | Edge gateway ID |
| `ip_sets`         | `map(object)` | `{}` | `ip_addresses` (list, at least one entry). Optional: `name` (defaults to the map key), `description` |
| `dnat_rules`      | `map(object)` | `{}` | External address (an edge gateway allocated IP) → internal address (VM): `external_address` **or** `external_ip_set`, and `internal_address` **or** `internal_ip_set`. Optional: `name` (defaults to the map key), `description`, `enabled`, `logging`, `dnat_external_port`, `app_port_profile` (built-in name), `firewall_match`, `priority` |
| `snat_rules`      | `map(object)` | `{}` | Internal address (source CIDR) → external address (an edge gateway allocated IP): `internal_address` **or** `internal_ip_set`, and `external_address` **or** `external_ip_set`. Optional: `snat_destination_address` **or** `snat_destination_ip_set`, `name`, `description`, `enabled`, `logging`, `firewall_match`, `priority` |

## Outputs

| Name         | Description |
|--------------|-------------|
| `dnat_ids`   | Map of DNAT rule key → ID |
| `snat_ids`   | Map of SNAT rule key → ID |
| `ip_set_ids` | Map of `ip_sets` key → IP set ID |

## Tests

```bash
terraform init -backend=false && terraform test
```
