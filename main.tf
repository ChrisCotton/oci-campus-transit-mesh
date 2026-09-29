# ============================================================
# OCI Campus Transit Mesh — Root Module
#
# Models a production DRG v2 hub-and-spoke transit network,
# zero-secret Instance Principals IAM, and private Service
# Gateway routing for Oracle PaaS services.
#
# Architecture:
#
#   Campus / On-Prem
#        |
#        +--[FastConnect / IPSec VPN]
#        |
#   +----+----+
#   |  DRG v2  |  (Dynamic Routing Gateway — central transit router)
#   +----+----+
#        |
#   +----+--------------+----------------+
#   |                   |                |
#   Hub VCN          Spoke VCN      (future spokes)
#   (security/       (workloads/
#    ingress)         databases)
#   |                   |
#   |              +----+----+
#   |              | Service  |  (private path to OCI services:
#   |              | Gateway  |   Object Storage, Autonomous DB)
#   |              +---------+
#   |
#   Instance Principals + Dynamic Groups
#   (zero-static-credentials automation)
# ============================================================

# -----------------------------------------------------------
# Hub VCN — Campus ingress, security inspection, firewall
# -----------------------------------------------------------

resource "oci_core_vcn" "hub_vcn" {
  compartment_id = var.compartment_ocid
  cidr_block     = var.hub_vcn_cidr
  display_name   = "${var.project_name}-${var.environment}-hub-vcn"
  dns_label      = substr("${var.project_name}hub", 0, 15)

  freeform_tags = {
    Environment = var.environment
    Project     = var.project_name
    Role        = "hub"
    ManagedBy   = "terraform"
  }
}

resource "oci_core_subnet" "hub_subnet" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.hub_vcn.id
  cidr_block     = var.hub_subnet_cidr
  display_name   = "${var.project_name}-${var.environment}-hub-subnet"

  freeform_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Internet Gateway for Hub VCN (campus ingress path)
resource "oci_core_internet_gateway" "hub_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.hub_vcn.id
  display_name   = "${var.project_name}-${var.environment}-hub-igw"

  freeform_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Hub VCN default route table (for internet egress via IGW)
resource "oci_core_default_route_table" "hub_rt" {
  manage_default_resource_id = oci_core_vcn.hub_vcn.default_route_table_id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.hub_igw.id
  }
}

# -----------------------------------------------------------
# Spoke VCN — Workloads, databases, application tier
# -----------------------------------------------------------

resource "oci_core_vcn" "spoke_vcn" {
  compartment_id = var.compartment_ocid
  cidr_block     = var.spoke_vcn_cidr
  display_name   = "${var.project_name}-${var.environment}-spoke-vcn"
  dns_label      = substr("${var.project_name}spoke", 0, 15)

  freeform_tags = {
    Environment = var.environment
    Project     = var.project_name
    Role        = "spoke"
    ManagedBy   = "terraform"
  }
}

resource "oci_core_subnet" "spoke_subnet" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.spoke_vcn.id
  cidr_block     = var.spoke_subnet_cidr
  display_name   = "${var.project_name}-${var.environment}-spoke-subnet"
  prohibit_public_ip = true

  freeform_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Spoke VCN route table — routes to DRG for inter-VCN/campus traffic
# (Service Gateway route rule added by the service_gateway module)
resource "oci_core_route_table" "spoke_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.spoke_vcn.id
  display_name   = "${var.project_name}-${var.environment}-spoke-rt"

  # Default route via DRG for transit to hub and campus
  route_rules {
    destination       = var.hub_vcn_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = module.drg_transit.drg_id
    description       = "Route to Hub VCN via DRG"
  }

  freeform_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Associate spoke subnet with spoke route table
resource "oci_core_route_table_attachment" "spoke_rt_attach" {
  route_table_id = oci_core_route_table.spoke_rt.id
  subnet_id      = oci_core_subnet.spoke_subnet.id
}

# -----------------------------------------------------------
# Module: DRG Transit (hub-and-spoke via DRG v2)
# -----------------------------------------------------------

module "drg_transit" {
  source        = "./modules/drg_transit"
  compartment_id = var.compartment_ocid
  hub_vcn_id    = oci_core_vcn.hub_vcn.id
  spoke_vcn_id  = oci_core_vcn.spoke_vcn.id
  project_name  = var.project_name
  environment   = var.environment
}

# -----------------------------------------------------------
# Module: Service Gateway (private path to OCI PaaS services)
# -----------------------------------------------------------

module "service_gateway" {
  source         = "./modules/service_gateway"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.spoke_vcn.id
  route_table_id = oci_core_route_table.spoke_rt.id
  project_name   = var.project_name
  environment    = var.environment
}

# -----------------------------------------------------------
# Module: Zero-Trust IAM (Instance Principals + Dynamic Groups)
# -----------------------------------------------------------

module "zero_trust_iam" {
  source         = "./modules/zero_trust_iam"
  tenancy_ocid   = var.oci_tenancy_ocid
  compartment_id = var.compartment_ocid
  project_name   = var.project_name
  environment    = var.environment
}
