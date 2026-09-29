# ============================================================
# OCI Service Gateway Module
#
# Creates a Service Gateway inside the VCN that provides private,
# internet-free access to Oracle PaaS services (Object Storage,
# Autonomous Database, Streaming, etc).
#
# Traffic to the Oracle Services Network (OSN) is routed through
# the Service Gateway instead of a NAT Gateway, eliminating:
#   - Public IP exposure for private workloads
#   - Data egress charges on service-bound traffic
#
# This is the production pattern for backup workflows, database
# connections to Autonomous DB, and Object Storage integrations.
# ============================================================

# --- Lookup the All Services OSN CIDR ---
# The data source fetches the service CIDR for all Oracle services
# in the region's Oracle Services Network (OSN).

data "oci_core_services" "all_oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

# --- Service Gateway ---

resource "oci_core_service_gateway" "sgw" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${var.project_name}-${var.environment}-service-gateway"

  services {
    service_id = data.oci_core_services.all_oci_services.services[0].id
  }

  freeform_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Purpose     = "private-paas-access"
  }
}

# --- Route Rule: Direct OSN traffic through the Service Gateway ---
# Adds a route rule to the specified route table so that traffic
# destined for Oracle services (OSN CIDR) goes through the SGW
# instead of the NAT Gateway or Internet Gateway.

resource "oci_core_route_table" "sgw_route_table" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${var.project_name}-${var.environment}-sgw-rt"

  # Route Oracle services through the Service Gateway
  route_rules {
    destination       = data.oci_core_services.all_oci_services.services[0].cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.sgw.id
    description       = "Private routing for Object Storage, Autonomous DB, and PaaS services"
  }

  freeform_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
