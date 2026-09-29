variable "compartment_id" {
  description = "OCI compartment OCID"
  type        = string
}

variable "vcn_id" {
  description = "OCID of the VCN where the Service Gateway will be created"
  type        = string
}

variable "route_table_id" {
  description = "OCID of the route table to add the Service Gateway route rule to"
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
