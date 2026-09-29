# ============================================================
# Zero-Trust IAM Module: Instance Principals + Dynamic Groups
#
# Eliminates long-lived static API credentials from CI/CD pipelines
# and compute instances. Instead of storing API keys in environment
# variables, vaults, or files, instances authenticate to OCI APIs
# using cryptographic certificates issued through instance metadata.
#
# Flow:
#   1. Instance boots in the target compartment
#   2. Instance metadata provides a signed certificate
#   3. Instance presents cert to OCI API endpoints
#   4. Dynamic Group matches the instance by compartment ID
#   5. IAM policy grants least-privilege access
#
# This pattern is equivalent to AWS Instance Profiles / IAM Roles
# for EC2, implemented through OCI's native identity primitives.
# ============================================================

# --- Dynamic Group ---
# A dynamic group automatically captures any compute instance
# running inside the specified compartment. No manual instance
# registration required — instances are members by virtue of
# their compartment placement.

resource "oci_identity_dynamic_group" "automation_instances" {
  compartment_id = var.tenancy_ocid
  name           = "${var.project_name}-${var.environment}-automation-workloads"
  description    = "Dynamic group for Jenkins runners, CI/CD instances, and automated workload instances in the ${var.environment} compartment"
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_id}', tag.${var.project_name}.role = 'automation'}"

  freeform_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# --- Least-Privilege IAM Policy ---
# Grants the dynamic group read access to secrets and metrics
# without exposing broader tenancy permissions.

resource "oci_identity_policy" "automation_least_privilege" {
  compartment_id = var.compartment_id
  name           = "${var.project_name}-${var.environment}-workload-access-policy"
  description    = "Allows automation instances to read secrets and emit metrics without static API keys"

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.automation_instances.name} to read secret-bundles in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.automation_instances.name} to use metrics in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.automation_instances.name} to read object-family in compartment id ${var.compartment_id}",
  ]

  freeform_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# --- SAML Identity Provider Federation ---
# Establishes a SAML 2.0 trust with the institutional IdP
# (e.g., Stanford Shibboleth, Okta). Enterprise users authenticate
# through the campus directory instead of OCI-local credentials.
#
# In production, this creates a SAML IdP in the OCI Identity Domain
# and maps IdP groups to OCI groups for authorization.

resource "oci_identity_identity_provider" "campus_idp" {
  count          = var.saml_metadata_xml != "" ? 1 : 0
  compartment_id = var.tenancy_ocid
  name           = "${var.project_name}-${var.environment}-${var.idp_name}"
  description    = "SAML 2.0 federation with institutional IdP: ${var.idp_name}"
  protocol       = "SAML2"
  metadata       = var.saml_metadata_xml  # URL or inline metadata XML

  freeform_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Purpose     = "identity-federation"
  }
}

resource "oci_identity_idp_group_mapping" "infra_engineers_mapping" {
  count              = var.saml_metadata_xml != "" ? 1 : 0
  identity_provider_id = oci_identity_identity_provider.campus_idp[0].id
  group_id             = oci_identity_group.campus_infra_engineers.id
  idp_group_name       = "infra-engineers" # This should be a variable in a real implementation
}


# --- Identity Domain Group Mapping ---
# Maps a group from the institutional IdP to an OCI local group.
# In production, this ties campus directory groups (e.g.,
# "infra-engineers") to OCI IAM groups with specific compartment
# permissions.

resource "oci_identity_group" "campus_infra_engineers" {
  compartment_id = var.tenancy_ocid
  name           = "${var.project_name}-${var.environment}-infra-engineers"
  description    = "OCI group mapped from institutional IdP for infrastructure engineers"

  freeform_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Policy granting the mapped group infrastructure management access
resource "oci_identity_policy" "infra_engineer_access" {
  compartment_id = var.compartment_id
  name           = "${var.project_name}-${var.environment}-infra-engineer-access"
  description    = "Grants infra engineers network and compute management access"

  statements = [
    "Allow group ${oci_identity_group.campus_infra_engineers.name} to manage virtual-network-family in compartment id ${var.compartment_id}",
    "Allow group ${oci_identity_group.campus_infra_engineers.name} to manage instance-family in compartment id ${var.compartment_id}",
    "Allow group ${oci_identity_group.campus_infra_engineers.name} to read volume-family in compartment id ${var.compartment_id}",
  ]

  freeform_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}
