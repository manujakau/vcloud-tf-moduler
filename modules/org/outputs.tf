output "org_id" {
  description = "ID of the organization."
  value       = vcd_org.this.id
}

output "org_name" {
  description = "Name of the organization."
  value       = vcd_org.this.name
}
