# OCI Campus Transit Mesh

> Production-grade Terraform blueprint for hybrid campus-to-cloud transit networking, zero-trust identity federation, and credential-less automation on Oracle Cloud Infrastructure (OCI).

This repository models the enterprise-scale architecture that research institutions and large enterprises need when running OCI alongside AWS: a Dynamic Routing Gateway (DRG v2) hub-and-spoke transit network, Instance Principals for zero-secret CI/CD, and Service Gateway routing for private PaaS access.

## The Three Problems This Solves

### 1. Campus-to-Cloud Transit Networking

**Problem:** Connecting campus networks, AWS VPCs, and multiple OCI VCNs without managing complex point-to-point peerings.

**Solution:** DRG v2 as a centralized transit router. The DRG handles VCN attachments, FastConnect virtual circuits, and IPSec VPN tunnels using distinct DRG Route Tables and import distributions. This is OCI's equivalent of AWS Transit Gateway.

In early OCI, you were stuck with 1:1 Local Peering Gateways (LPGs). Modern OCI uses DRG v2 route tables and import distributions to create a hub-and-spoke model where the DRG is the single transit point for all attached networks.

```
                    Campus / On-Prem
                         |
              +----------+----------+
              |  FastConnect / IPSec |
              +----------+----------+
                         |
                    +----+----+
                    |  DRG v2  |   Central transit router
                    +----+----+
                         |
              +----------+----------+
              |                     |
        +-----+-----+         +-----+-----+
        |  Hub VCN  |         | Spoke VCN  |
        | (security |         | (workloads |
        |  ingress) |         |  databases)|
        +-----------+         +-----+-----+
                                    |
                              +-----+-----+
                              |  Service  |  Private path to
                              |  Gateway  |  OCI PaaS services
                              +-----------+
```

### 2. Zero-Trust Identity Federation

**Problem:** CI/CD pipelines and compute instances need to interact with OCI APIs without storing hardcoded API keys in code, files, or environment variables.

**Solution:** Instance Principals combined with Dynamic Groups. Instances authenticate automatically using cryptographic certificates issued through instance metadata, bound to an IAM policy. No static credentials. No key rotation. No secret management overhead.

The module also establishes a SAML 2.0 trust with the institutional IdP (e.g., Shibboleth, Okta) and maps IdP directory groups directly into OCI Identity Domain Groups, keeping account lifecycle management tied to the central campus directory.

### 3. Private Service Access Without Egress Fees

**Problem:** Backend databases and internal applications need to reach Object Storage or Autonomous Databases without exposing public IPs or paying egress fees through a NAT Gateway.

**Solution:** A Service Gateway inside the VCN routes the `all-services` Oracle Services Network (OSN) CIDR block through a private conduit. Traffic never touches the public internet. No egress charges. No public IP exposure.

## Repository Structure

```
oci-campus-transit-mesh/
├── README.md
├── versions.tf              # Provider requirements (OCI ~> 6.0)
├── variables.tf             # Root variables (credentials, networking, identity)
├── terraform.tfvars.example # Example configuration (copy to terraform.tfvars)
├── main.tf                  # Root module: provisions Hub VCN, Spoke VCN, calls modules
└── modules/
    ├── drg_transit/          # DRG v2 hub-and-spoke transit router
    │   ├── main.tf           # DRG, VCN attachments, route tables, import distributions
    │   ├── variables.tf
    │   └── outputs.tf
    ├── service_gateway/      # Private access to OCI PaaS services
    │   ├── main.tf           # Service Gateway + OSN route rule
    │   ├── variables.tf
    │   └── outputs.tf
    └── zero_trust_iam/       # Instance Principals + Dynamic Groups + SAML federation
        ├── main.tf           # Dynamic group, least-privilege policy, SAML IdP, group mapping
        ├── variables.tf
        └── outputs.tf
```

## Module Reference

### `drg_transit` — DRG v2 Hub-and-Spoke

| Resource | Purpose |
|----------|---------|
| `oci_core_drg` | The DRG v2 transit router itself |
| `oci_core_drg_attachment` (hub) | Attaches the Hub VCN (security/ingress) to the DRG |
| `oci_core_drg_attachment` (spoke) | Attaches the Spoke VCN (workloads) to the DRG |
| `oci_core_drg_route_distribution` | IMPORT distribution to pull routes from hub + on-prem |
| `oci_core_drg_route_distribution_statement` | Accept rule matching hub attachment |
| `oci_core_drg_route_table` | Route table for spoke traffic, linked to import distribution |

### `service_gateway` — Private PaaS Access

| Resource | Purpose |
|----------|---------|
| `oci_core_services` (data) | Looks up the OSN CIDR for all Oracle services in region |
| `oci_core_service_gateway` | The Service Gateway itself (private conduit) |
| `oci_core_route_table` (sgw) | Route table with OSN CIDR routed through the Service Gateway |

### `zero_trust_iam` — Credential-Less Automation

| Resource | Purpose |
|----------|---------|
| `oci_identity_dynamic_group` | Captures any VM in the target compartment automatically |
| `oci_identity_policy` (automation) | Least-privilege: read secrets, emit metrics, read objects |
| `oci_identity_saml2_identity_provider` | SAML 2.0 trust with institutional IdP |
| `oci_identity_group` | OCI group mapped from IdP for infra engineers |
| `oci_identity_policy` (infra) | Grants network + compute management to federated engineers |

## Quick Start

```bash
# 1. Copy the example tfvars and fill in your OCI credentials
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your tenancy OCID, compartment OCID, etc.

# 2. Initialize Terraform
terraform init

# 3. Review the plan
terraform plan

# 4. Apply
terraform apply
```

## Interview Trap Questions This Repo Answers

**Q: How do you connect campus networks and AWS VPCs to multiple OCI VCNs without managing complex point-to-point peerings?**

In early OCI, you were stuck with 1:1 Local Peering Gateways (LPGs). In modern OCI, you use DRG v2 as a centralized transit router. The DRG handles VCN attachments, FastConnect virtual circuits, and IPSec VPN tunnels using distinct DRG Route Tables and import distributions.

**Q: How do your CI/CD pipelines or compute instances interact with OCI APIs without storing hardcoded API keys?**

Never use static user API keys. Use Instance Principals combined with Dynamic Groups. Instances authenticate automatically using cryptographic certificates issued through instance metadata, bound to an IAM policy. This eliminates the entire class of credential leakage risks.

**Q: How do backend databases reach Object Storage or Autonomous Databases without exposing public IPs or paying egress fees?**

Configure a Service Gateway inside the VCN and route the `all-services` OSN CIDR block through it. Traffic to Oracle PaaS services never touches the public internet, and there are no data egress charges.

## Operational Discussion Points

- **FastConnect vs. IPSec VPN:** For high-bandwidth campus connectivity, terminate FastConnect virtual circuits into the DRG v2. For failover or branch locations, use policy-based or route-based IPSec VPN attachments into the same DRG fabric.

- **Identity Domains vs. Legacy IDCS:** In current OCI architectures, enterprise IAM is managed via OCI Identity Domains. Establish a SAML 2.0 or OIDC trust with the institutional IdP (Okta/Shibboleth) and map IdP directory groups directly into OCI Domain Groups.

- **Cost Governance:** Service Gateways eliminate data egress fees when transferring high volumes of backups to OCI Object Storage compared to routing that traffic through a NAT Gateway.

## Acronym Glossary

- **DRG** (Dynamic Routing Gateway): Virtual routing device acting as a transit router for VCN-to-VCN and VCN-to-on-prem connectivity.
- **LPG** (Local Peering Gateway): Legacy point-to-point VCN peering within the same region (superseded by DRG v2 for multi-VCN topologies).
- **OSN** (Oracle Services Network): Reserved network for Oracle PaaS services (Object Storage, Autonomous DB, Streaming).
- **IdP** (Identity Provider): System that creates and manages identity information and provides authentication (Okta, Shibboleth, Ping).
- **OIDC** (OpenID Connect): Identity authentication protocol built on OAuth 2.0.
- **CIDR** (Classless Inter-Domain Routing): IP address allocation and routing method.
- **BGP** (Border Gateway Protocol): Exterior gateway protocol for exchanging routing information across autonomous systems.

## Related Work

- [oci-aws-iac-patterns](https://github.com/ChrisCotton/oci-aws-iac-patterns) — Companion repo: dual-cloud AWS + OCI Terraform IaC abstraction patterns (VPC/VCN, EC2/OCI compute, security groups/lists).

## License

MIT
