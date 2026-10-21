# org

Creates a VMware Cloud Director organization. Requires System Administrator
credentials (provider `org = "System"`).

## Owns

| Resource  | Notes            |
|-----------|------------------|
| `vcd_org` | One organization |

## Inputs

| Name          | Type     | Default | Description |
|---------------|----------|---------|-------------|
| `name`        | `string` | —       | Organization name |
| `full_name`   | `string` | `""`    | Display name. **Always set this**: the provider requires a non-empty value, so the `""` default is not usable in practice |
| `description` | `string` | `""`    | Description |
| `is_enabled`  | `bool`   | `true`  | Whether the organization is enabled |

## Outputs

| Name       | Description |
|------------|-------------|
| `org_id`   | Organization ID |
| `org_name` | Organization name |

## Tests

```bash
terraform init -backend=false && terraform test
```
