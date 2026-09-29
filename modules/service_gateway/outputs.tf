output "service_gateway_id" {
  description = "OCID of the Service Gateway"
  value       = oci_core_service_gateway.sgw.id
}

output "osn_cidr_block" {
  description = "CIDR block for the Oracle Services Network (all services)"
  value       = data.oci_core_services.all_oci_services.services[0].cidr_block
}


