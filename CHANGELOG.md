# Changelog

All notable changes to the module catalog are documented here. Versions follow
[Semantic Versioning](https://semver.org/); the git tag `vX.Y.Z` is what
consumers pin with `?ref=vX.Y.Z`.

## [1.1.0] - unreleased

Backward compatible: existing `dnat_rules` / `snat_rules` inputs plan with no changes.

### Added
- `nat_rules`: `ip_sets` input creates named `vcd_nsxt_ip_set` resources on the edge gateway.
- `nat_rules`: rules can take an address from an IP set instead of a raw value:
  `external_ip_set`, `internal_ip_set` (DNAT and SNAT), `snat_destination_ip_set` (SNAT).
  A referenced set must contain exactly one IP or CIDR (checked by preconditions).
- `nat_rules`: `ip_set_ids` output.

### Changed
- `nat_rules`: `external_address` / `internal_address` are now optional, but each
  address still needs either the raw value or an IP set reference.

## [1.0.0] - 2026-10-21

First versioned release of the catalog. Module code is unchanged from the
single-root-module layout (commit `b492773`), so existing state maps 1:1 onto
the module resources.

### Added
- Per-module offline tests (`modules/<name>/tests/*.tftest.hcl`, `mock_provider "vcd"`).
- Per-module READMEs (inputs, outputs, owned resources).

### Removed
- `tests/plan.tftest.hcl` (root-module test that depended on `terraform.tfvars`).

### Deprecated
- Root `main.tf`, `variables.tf`, `outputs.tf`. They stay until the state
  migration to the Terragrunt live repo is complete, then they are removed in a
  later major release.

### Modules
`org`, `vdc`, `edge_gateway`, `routed_network`, `firewall_rules`, `nat_rules`.
All require Terraform `>= 1.3` and `vmware/vcd ~> 3.14`. Running the tests needs Terraform `>= 1.7` (`mock_provider`).
