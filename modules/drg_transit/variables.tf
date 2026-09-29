variable "compartment_id" {
  description = "OCI compartment OCID"
  type        = string
}

variable "hub_vcn_id" {
  description = "OCID of the Hub VCN (campus ingress / security)"
  type        = string
}

variable "spoke_vcn_id" {
  description = "OCID of the Spoke VCN (workloads / databases)"
  type        = string
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
