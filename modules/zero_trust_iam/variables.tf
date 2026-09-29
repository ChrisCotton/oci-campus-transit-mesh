variable "tenancy_ocid" {
  description = "OCI tenancy OCID (required for dynamic groups and IdP resources)"
  type        = string
}

variable "compartment_id" {
  description = "OCI compartment OCID where automation instances run"
  type        = string
}

variable "idp_name" {
  description = "Name of the institutional identity provider"
  type        = string
  default     = "stanford-idp"
}

variable "saml_metadata_url" {
  description = "SAML metadata URL or inline XML from the institutional IdP"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "campus-transit-mesh"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}
