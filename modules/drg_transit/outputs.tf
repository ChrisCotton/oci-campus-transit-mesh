output "drg_id" {
  description = "OCID of the DRG v2 transit router"
  value       = oci_core_drg.campus_transit_drg.id
}

output "hub_attachment_id" {
  description = "OCID of the Hub VCN DRG attachment"
  value       = oci_core_drg_attachment.hub_attachment.id
}

output "spoke_attachment_id" {
  description = "OCID of the Spoke VCN DRG attachment"
  value       = oci_core_drg_attachment.spoke_attachment.id
}

output "spoke_route_table_id" {
  description = "OCID of the DRG route table for spoke traffic"
  value       = oci_core_drg_route_table.spokes_rt.id
}

output "route_distribution_id" {
  description = "OCID of the DRG route distribution for import"
  value       = oci_core_drg_route_distribution.import_to_spokes.id
}
