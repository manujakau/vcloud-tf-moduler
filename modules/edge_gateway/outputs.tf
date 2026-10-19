output "gateway_id" {
  value = vcd_nsxt_edgegateway.this.id
}

output "gateway_name" {
  value = vcd_nsxt_edgegateway.this.name
}

output "primary_ip" {
  value = vcd_nsxt_edgegateway.this.primary_ip
}
