# AAP Air-Gapped HA Infrastructure Architecture Documentation

## Overview

This documentation set provides a complete infrastructure architecture reference for deploying Red Hat Ansible Automation Platform (AAP) in an air-gapped, highly available enterprise environment based on Foundation 24R11.

## Document Index

| Document | Description | Audience |
|----------|-------------|----------|
| [AAP-INFRASTRUCTURE-ARCHITECTURE.md](./AAP-INFRASTRUCTURE-ARCHITECTURE.md) | Main architecture document with component details, network design, security model | Architects, Engineers |
| [DECISION-TREES.md](./DECISION-TREES.md) | Operational decision trees for deployment, troubleshooting, upgrades | Operations, SRE |
| [diagrams/ARCHITECTURE-DIAGRAMS.md](./diagrams/ARCHITECTURE-DIAGRAMS.md) | Mermaid diagrams for visual architecture representation | All |

## Quick Links by Topic

### Architecture
- [System Priority Classification](./AAP-INFRASTRUCTURE-ARCHITECTURE.md#2-system-priority-classification)
- [Network Architecture](./AAP-INFRASTRUCTURE-ARCHITECTURE.md#3-network-architecture)
- [Component Architecture](./AAP-INFRASTRUCTURE-ARCHITECTURE.md#4-component-architecture)
- [Kubernetes Cluster](./AAP-INFRASTRUCTURE-ARCHITECTURE.md#5-kubernetes-cluster-architecture-rke2)

### Operations
- [Deployment Order](./AAP-INFRASTRUCTURE-ARCHITECTURE.md#10-deployment-order--dependencies)
- [Monitoring](./AAP-INFRASTRUCTURE-ARCHITECTURE.md#11-monitoring--observability)
- [Backup & DR](./AAP-INFRASTRUCTURE-ARCHITECTURE.md#12-backup--disaster-recovery)
- [Runbooks](./AAP-INFRASTRUCTURE-ARCHITECTURE.md#13-operational-runbooks)

### Decision Trees
- [Deployment Method](./DECISION-TREES.md#1-deployment-method-selection)
- [Air-Gap Sync](./DECISION-TREES.md#2-air-gap-content-sync-decision)
- [Troubleshooting](./DECISION-TREES.md#3-troubleshooting-decision-tree)
- [Upgrades](./DECISION-TREES.md#4-upgrade-decision-tree)
- [Incident Response](./DECISION-TREES.md#5-incident-response-decision-tree)

### Diagrams
- [High-Level Overview](./diagrams/ARCHITECTURE-DIAGRAMS.md#1-high-level-infrastructure-overview)
- [AAP Controller](./diagrams/ARCHITECTURE-DIAGRAMS.md#2-aap-controller-architecture)
- [GitOps Flow](./diagrams/ARCHITECTURE-DIAGRAMS.md#3-gitops-deployment-flow)
- [Security Layers](./diagrams/ARCHITECTURE-DIAGRAMS.md#4-security-architecture)
- [Multi-Site](./diagrams/ARCHITECTURE-DIAGRAMS.md#5-multi-site-architecture)

## Environment Summary

| Attribute | Value |
|-----------|-------|
| Platform | Foundation 24R11 |
| Kubernetes | RKE2 |
| Container Runtime | containerd |
| Service Mesh | Istio |
| GitOps | ArgoCD |
| Registry | Nexus |
| Secrets | CyberArk Conjur |
| Identity | Keycloak/Zitadel + LDAP |
| Monitoring | Prometheus + Grafana |
| Backup | Velero |

## Priority Tiers Summary

### P1 - Mission Critical (RTO < 15 min)
- AAP Controller Cluster
- PostgreSQL (Patroni HA)
- etcd Cluster
- RKE2 Control Plane
- Istio Control Plane
- Container Registry

### P2 - Business Critical (RTO < 1 hour)
- Private Automation Hub
- GitHub Enterprise
- ArgoCD
- Identity Provider
- Session Cache

### P3 - Operational Support (RTO < 4 hours)
- Monitoring Stack
- Logging Stack
- Backup System
- Object Storage

## Getting Started

1. **New Deployment**: Start with [Deployment Method Selection](./DECISION-TREES.md#1-deployment-method-selection)
2. **Understanding Architecture**: Read [Main Architecture Document](./AAP-INFRASTRUCTURE-ARCHITECTURE.md)
3. **Troubleshooting**: Use [Troubleshooting Decision Trees](./DECISION-TREES.md#3-troubleshooting-decision-tree)
4. **Visual Reference**: Review [Architecture Diagrams](./diagrams/ARCHITECTURE-DIAGRAMS.md)

## Related Documentation

- Foundation 24R11 Installation Guide (PDF)
- Red Hat AAP Documentation
- RKE2 Documentation
- Istio Documentation

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01 | Initial release |
