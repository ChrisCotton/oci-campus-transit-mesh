output "service_gateway_id" {
  description = "OCID of the Service Gateway"
  value       = oci_core_service_gateway.sgw.id
}

output "osn_cidr_block" {
  description = "CIDR block for the Oracle Services Network (all services)"
  value       = data.oci_core_services.all_oci_services.services[0].cidr_block
}

output "sgw_route_table_id" {
  description = "OCID of the route table containing the Service Gateway route rule"
  value       = oci_core_route_table.sgw_route_table.id
}
