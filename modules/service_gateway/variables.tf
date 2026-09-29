variable "compartment_id" {
  description = "OCI compartment OCID"
  type        = string
}

variable "vcn_id" {
  description = "OCID of the VCN where the Service Gateway will be created"
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
