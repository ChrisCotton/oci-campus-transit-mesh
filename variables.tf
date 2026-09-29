# ============================================================
# OCI Campus Transit Mesh — Root Variables
# ============================================================

# --- OCI Provider ---

variable "oci_tenancy_ocid" {
  description = "OCI tenancy OCID"
  type        = string
}

variable "oci_user_ocid" {
  description = "OCI user OCID (not required when using instance principals)"
  type        = string
  default     = ""
}

variable "oci_fingerprint" {
  description = "OCI API key fingerprint (not required when using instance principals)"
  type        = string
  default     = ""
}

variable "oci_private_key_path" {
  description = "Path to OCI API private key (not required when using instance principals)"
  type        = string
  default     = ""
}

variable "oci_region" {
  description = "OCI home region"
  type        = string
  default     = "us-sanjose-1"
}

# --- Compartment ---

variable "compartment_ocid" {
  description = "OCI compartment OCID for all resource placement"
  type        = string
}

# --- Networking ---

variable "hub_vcn_cidr" {
  description = "CIDR block for the Hub VCN (campus ingress / security inspection)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "spoke_vcn_cidr" {
  description = "CIDR block for the Spoke VCN (workloads / databases)"
  type        = string
  default     = "10.1.0.0/16"
}

variable "hub_subnet_cidr" {
  description = "CIDR block for the Hub VCN subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "spoke_subnet_cidr" {
  description = "CIDR block for the Spoke VCN subnet"
  type        = string
  default     = "10.1.1.0/24"
}

# --- Identity Federation ---

variable "idp_name" {
  description = "Name of the identity provider (e.g., Okta, Shibboleth, Azure AD)"
  type        = string
  default     = "institutional-idp"
}

variable "saml_metadata_url" {
  description = "SAML metadata document URL from the institutional IdP"
  type        = string
  default     = ""
}

# --- Tags ---

variable "project_name" {
  description = "Project name for resource tagging and naming"
  type        = string
  default     = "campus-transit-mesh"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}
