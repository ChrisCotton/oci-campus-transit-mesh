# ============================================================
# DRG v2 Hub-and-Spoke Transit Module
#
# Implements a centralized transit router using OCI's Dynamic
# Routing Gateway v2. The DRG acts as the transit hub between:
#   - Hub VCN (campus ingress / security inspection)
#   - Spoke VCN (workloads / databases)
#   - FastConnect / IPSec VPN (on-prem campus networks)
#
# Modern OCI uses DRG v2 route tables and import distributions
# instead of legacy 1:1 Local Peering Gateways (LPGs).
# ============================================================

# --- DRG v2: Central Transit Router ---

resource "oci_core_drg" "campus_transit_drg" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}-${var.environment}-transit-drg-v2"

  freeform_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# --- Hub VCN Attachment ---

resource "oci_core_drg_attachment" "hub_attachment" {
  drg_id       = oci_core_drg.campus_transit_drg.id
  display_name = "${var.project_name}-${var.environment}-hub-vcn-attachment"

  network_details {
    id   = var.hub_vcn_id
    type = "VCN"
  }

  freeform_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# --- Spoke VCN Attachment ---

resource "oci_core_drg_attachment" "spoke_attachment" {
  drg_id       = oci_core_drg.campus_transit_drg.id
  display_name = "${var.project_name}-${var.environment}-spoke-vcn-attachment"

  network_details {
    id   = var.spoke_vcn_id
    type = "VCN"
  }

  freeform_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# --- DRG Route Distribution (IMPORT) ---
# Imports routes from the Hub VCN attachment (and future on-prem
# FastConnect / IPSec attachments) into the Spoke route table.

resource "oci_core_drg_route_distribution" "import_to_spokes" {
  drg_id            = oci_core_drg.campus_transit_drg.id
  distribution_type = "IMPORT"
  display_name      = "${var.project_name}-${var.environment}-import-hub-and-campus"

  freeform_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Route distribution statement: accept routes from Hub attachment
resource "oci_core_drg_route_distribution_statement" "hub_rule" {
  drg_route_distribution_id = oci_core_drg_route_distribution.import_to_spokes.id
  action                    = "ACCEPT"
  priority                  = 1

  match_criteria {
    match_type        = "DRG_ATTACHMENT_ID"
    drg_attachment_id = oci_core_drg_attachment.hub_attachment.id
  }
}

# --- DRG Route Table for Spoke Traffic ---
# Applies the import distribution so the Spoke VCN learns routes
# from the Hub VCN and on-prem campus networks.

resource "oci_core_drg_route_table" "spokes_rt" {
  drg_id                            = oci_core_drg.campus_transit_drg.id
  display_name                      = "${var.project_name}-${var.environment}-spokes-drg-rt"
  import_drg_route_distribution_id  = oci_core_drg_route_distribution.import_to_spokes.id

  freeform_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Associate the spoke DRG route table with the spoke attachment
resource "oci_core_drg_attachment" "spoke_attachment_route_table" {
  count               = 0  # Placeholder for future route table association updates
  drg_id              = oci_core_drg.campus_transit_drg.id
  display_name        = "spoke-rt-association"
  network_details {
    id   = var.spoke_vcn_id
    type = "VCN"
  }
}
