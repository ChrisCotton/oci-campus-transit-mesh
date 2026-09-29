output "dynamic_group_name" {
  description = "Name of the dynamic group for automation instances"
  value       = oci_identity_dynamic_group.automation_instances.name
}

output "automation_policy_id" {
  description = "OCID of the least-privilege IAM policy for automation instances"
  value       = oci_identity_policy.automation_least_privilege.id
}

output "saml_idp_id" {
  description = "OCID of the SAML identity provider (empty if not configured)"
  value       = length(oci_identity_saml2_identity_provider.campus_idp) > 0 ? oci_identity_saml2_identity_provider.campus_idp[0].id : ""
}

output "infra_engineer_group_name" {
  description = "Name of the OCI group for infrastructure engineers (mapped from IdP)"
  value       = oci_identity_group.campus_infra_engineers.name
}

output "infra_engineer_policy_id" {
  description = "OCID of the IAM policy for infrastructure engineers"
  value       = oci_identity_policy.infra_engineer_access.id
}
