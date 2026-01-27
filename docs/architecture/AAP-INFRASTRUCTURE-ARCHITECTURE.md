# Ansible Automation Platform - Air-Gapped HA Infrastructure Architecture

## Document Information

| Attribute | Value |
|-----------|-------|
| Version | 1.0 |
| Platform | Foundation 24R11 |
| Environment | Air-Gapped, Highly Available |
| Last Updated | 2026-01 |

---

## 1. Executive Summary

This document defines the infrastructure architecture for Red Hat Ansible Automation Platform (AAP) deployed in an air-gapped, highly available enterprise environment. The architecture integrates with GitHub Enterprise, Kubernetes (RKE2), Helm, and follows zero-trust security principles.

### Key Architecture Principles

1. **Air-Gap First** - All components operate without internet connectivity
2. **High Availability** - No single point of failure for P1 systems
3. **GitOps-Driven** - Infrastructure as Code via ArgoCD
4. **Zero-Trust Security** - mTLS, Conjur secrets, Istio service mesh
5. **Multi-Site Capable** - Active-passive or active-active configurations

---

## 2. System Priority Classification

### Priority 1 (P1) - Mission Critical
**RTO: < 15 minutes | RPO: < 5 minutes**

| Component | Purpose | HA Requirement |
|-----------|---------|----------------|
| AAP Controller Cluster | Job execution orchestration | 3+ nodes, active-active |
| PostgreSQL (Patroni) | Controller database | 3-node cluster with streaming replication |
| etcd Cluster | Kubernetes state | 3+ nodes, Raft consensus |
| RKE2 Control Plane | Kubernetes API | 3+ master nodes |
| Istio Control Plane | Service mesh | 3 replicas istiod |
| Container Registry (Nexus) | Image distribution | HA with shared storage |

### Priority 2 (P2) - Business Critical
**RTO: < 1 hour | RPO: < 15 minutes**

| Component | Purpose | HA Requirement |
|-----------|---------|----------------|
| Private Automation Hub | Execution environments, collections | 2+ replicas |
| GitHub Enterprise | Source control, CI/CD triggers | HA pair |
| ArgoCD | GitOps deployment | 3 replicas |
| Keycloak/Zitadel | Identity management | 2+ replicas |
| Redis/Infinispan | Session cache | Clustered mode |

### Priority 3 (P3) - Operational Support
**RTO: < 4 hours | RPO: < 1 hour**

| Component | Purpose | HA Requirement |
|-----------|---------|----------------|
| Monitoring Stack | Prometheus, Grafana, Alertmanager | 2 replicas |
| Logging Stack | Elasticsearch, Fluentd | Clustered |
| Velero | Backup/restore | Single + storage backend |
| Minio | Object storage | Distributed mode |

---

## 3. Network Architecture

### 3.1 Network Zones

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MANAGEMENT ZONE (Grey)                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Bastion   │  │  Ansible    │  │   GitHub    │  │   Nexus     │        │
│  │   Hosts     │  │  Controller │  │  Enterprise │  │  Registry   │        │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                              ┌───────┴───────┐
                              │   Firewall    │
                              └───────┬───────┘
                                      │
┌─────────────────────────────────────────────────────────────────────────────┐
│                          APPLICATION ZONE (Green)                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Kubernetes Cluster (RKE2)                         │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐        │   │
│  │  │  Master1  │  │  Master2  │  │  Master3  │  │  Worker*  │        │   │
│  │  └───────────┘  └───────────┘  └───────────┘  └───────────┘        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                              ┌───────┴───────┐
                              │   Firewall    │
                              └───────┬───────┘
                                      │
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DATA ZONE (Orange)                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ PostgreSQL  │  │   Redis     │  │ Infinispan  │  │   Minio     │        │
│  │  Cluster    │  │  Cluster    │  │  Cluster    │  │  Cluster    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Required Firewall Rules

| Source Zone | Dest Zone | Port | Protocol | Purpose |
|-------------|-----------|------|----------|---------|
| Management | Application | 6443 | TCP | Kubernetes API |
| Management | Application | 22 | TCP | SSH (Ansible) |
| Application | Data | 5432 | TCP | PostgreSQL |
| Application | Data | 6379 | TCP | Redis |
| Application | Application | 443 | TCP | Service mesh (mTLS) |
| Management | Management | 443 | TCP | GitHub, Nexus |

---

## 4. Component Architecture

### 4.1 AAP Controller Cluster (P1)

```
┌─────────────────────────────────────────────────────────────────┐
│                    AAP Controller Cluster                        │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Controller-1 │  │ Controller-2 │  │ Controller-3 │          │
│  │   (Active)   │  │   (Active)   │  │   (Active)   │          │
│  │              │  │              │  │              │          │
│  │ - Web UI     │  │ - Web UI     │  │ - Web UI     │          │
│  │ - API        │  │ - API        │  │ - API        │          │
│  │ - Dispatcher │  │ - Dispatcher │  │ - Dispatcher │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                 │                   │
│         └────────────┬────┴────────────────┘                   │
│                      │                                          │
│              ┌───────▼───────┐                                  │
│              │  Load Balancer │                                  │
│              │  (Ingress-NGINX)│                                 │
│              └───────┬───────┘                                  │
└──────────────────────┼──────────────────────────────────────────┘
                       │
               ┌───────▼───────┐
               │   PostgreSQL   │
               │   (Patroni)    │
               │   3-node HA    │
               └───────────────┘
```

**Sizing Requirements:**

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 4 cores | 8 cores |
| Memory | 16 GB | 32 GB |
| Storage | 40 GB | 100 GB SSD |
| Replicas | 3 | 3-5 |

### 4.2 Private Automation Hub (P2)

```
┌─────────────────────────────────────────────────────────────────┐
│                   Private Automation Hub                         │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐     │
│  │                    Hub Services                         │     │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │     │
│  │  │   Hub API   │  │  Content    │  │   Worker    │    │     │
│  │  │  (2 pods)   │  │  (2 pods)   │  │  (2 pods)   │    │     │
│  │  └─────────────┘  └─────────────┘  └─────────────┘    │     │
│  └────────────────────────────────────────────────────────┘     │
│                              │                                   │
│  ┌───────────────────────────┼───────────────────────────┐      │
│  │                    Storage Layer                       │      │
│  │  ┌─────────────┐  ┌──────▼──────┐  ┌─────────────┐   │      │
│  │  │  PostgreSQL │  │    Redis    │  │   S3/Minio  │   │      │
│  │  │  (shared)   │  │   Cache     │  │  (artifacts)│   │      │
│  │  └─────────────┘  └─────────────┘  └─────────────┘   │      │
│  └───────────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────────┘

Content Flow (Air-Gapped):
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  External    │───▶│   Sneakernet │───▶│   Internal   │
│  Galaxy      │    │   Transfer   │    │   Hub        │
└──────────────┘    └──────────────┘    └──────────────┘
```

### 4.3 Execution Environment Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│              Execution Environment Lifecycle                     │
│                                                                  │
│  BUILD PHASE (External/DMZ)                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ansible-builder                                         │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │  │ Base EE     │  │ Collections │  │ Python Deps │     │   │
│  │  │ Image       │+ │ (galaxy)    │+ │ (pip)       │     │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  │                         │                                │   │
│  │                         ▼                                │   │
│  │              ┌─────────────────────┐                    │   │
│  │              │  Custom EE Image    │                    │   │
│  │              │  (podman build)     │                    │   │
│  │              └─────────────────────┘                    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│                    ┌─────────▼─────────┐                        │
│                    │  Export (tar.gz)  │                        │
│                    └─────────┬─────────┘                        │
│                              │                                   │
│  DEPLOY PHASE (Air-Gapped)  │                                   │
│  ┌───────────────────────────▼─────────────────────────────┐   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │   │
│  │  │   Import    │─▶│   Nexus     │─▶│   AAP       │     │   │
│  │  │   (skopeo)  │  │  Registry   │  │  Controller │     │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Kubernetes Cluster Architecture (RKE2)

### 5.1 Cluster Topology

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         RKE2 Kubernetes Cluster                              │
│                                                                              │
│  CONTROL PLANE (3 nodes minimum)                                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │    Master-1     │  │    Master-2     │  │    Master-3     │             │
│  │  ┌───────────┐  │  │  ┌───────────┐  │  │  ┌───────────┐  │             │
│  │  │ kube-api  │  │  │  │ kube-api  │  │  │  │ kube-api  │  │             │
│  │  │ scheduler │  │  │  │ scheduler │  │  │  │ scheduler │  │             │
│  │  │ ctrl-mgr  │  │  │  │ ctrl-mgr  │  │  │  │ ctrl-mgr  │  │             │
│  │  │ etcd      │  │  │  │ etcd      │  │  │  │ etcd      │  │             │
│  │  └───────────┘  │  │  └───────────┘  │  │  └───────────┘  │             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
│           │                   │                   │                         │
│           └───────────────────┼───────────────────┘                         │
│                               │                                              │
│                       ┌───────▼───────┐                                     │
│                       │ VIP/LB (6443) │                                     │
│                       └───────────────┘                                     │
│                                                                              │
│  WORKER NODES (scalable)                                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │  Worker-1   │  │  Worker-2   │  │  Worker-3   │  │  Worker-N   │       │
│  │  ┌───────┐  │  │  ┌───────┐  │  │  ┌───────┐  │  │  ┌───────┐  │       │
│  │  │kubelet│  │  │  │kubelet│  │  │  │kubelet│  │  │  │kubelet│  │       │
│  │  │kube-  │  │  │  │kube-  │  │  │  │kube-  │  │  │  │kube-  │  │       │
│  │  │proxy  │  │  │  │proxy  │  │  │  │proxy  │  │  │  │proxy  │  │       │
│  │  └───────┘  │  │  └───────┘  │  │  └───────┘  │  │  └───────┘  │       │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘       │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Node Sizing

| Role | CPU | Memory | Storage | Count |
|------|-----|--------|---------|-------|
| Control Plane | 4 cores | 16 GB | 100 GB SSD | 3 |
| Worker (General) | 8 cores | 32 GB | 200 GB SSD | 3+ |
| Worker (AAP) | 16 cores | 64 GB | 200 GB SSD | 3+ |

---

## 6. GitOps Workflow (ArgoCD)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          GitOps Deployment Flow                              │
│                                                                              │
│  ┌──────────────┐         ┌──────────────┐         ┌──────────────┐        │
│  │   Developer  │────────▶│   GitHub     │────────▶│   ArgoCD     │        │
│  │   Commits    │         │  Enterprise  │         │   Sync       │        │
│  └──────────────┘         └──────────────┘         └──────┬───────┘        │
│                                                           │                 │
│                                                           ▼                 │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        Kubernetes Cluster                            │   │
│  │                                                                      │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                 │   │
│  │  │ foundation- │  │ foundation- │  │ application │                 │   │
│  │  │ base        │  │ apps        │  │ workloads   │                 │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘                 │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  Sync Strategy:                                                             │
│  ├── Auto-sync: Disabled (manual approval required)                        │
│  ├── Prune: Enabled with finalizers                                        │
│  └── Self-heal: Enabled for drift correction                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 7. Air-Gap Content Synchronization

### 7.1 Content Transfer Process

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Air-Gap Content Synchronization                           │
│                                                                              │
│  EXTERNAL NETWORK                    │           INTERNAL NETWORK            │
│  (Internet Connected)                │           (Air-Gapped)                │
│                                      │                                       │
│  ┌──────────────────┐               │          ┌──────────────────┐        │
│  │  Content Sources │               │          │  Internal Repos  │        │
│  │  ┌────────────┐  │               │          │  ┌────────────┐  │        │
│  │  │ Red Hat    │  │               │          │  │   Nexus    │  │        │
│  │  │ Registry   │  │               │          │  │  Registry  │  │        │
│  │  ├────────────┤  │    ┌──────┐  │  ┌──────┐│  ├────────────┤  │        │
│  │  │ Ansible    │──┼───▶│ USB/ │──┼─▶│Import││  │ Automation │  │        │
│  │  │ Galaxy     │  │    │ DVD  │  │  │Server││  │    Hub     │  │        │
│  │  ├────────────┤  │    └──────┘  │  └──────┘│  ├────────────┤  │        │
│  │  │ PyPI       │  │               │          │  │   Helm     │  │        │
│  │  │ Mirror     │  │               │          │  │   Repo     │  │        │
│  │  └────────────┘  │               │          │  └────────────┘  │        │
│  └──────────────────┘               │          └──────────────────┘        │
│                                      │                                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 7.2 Required Artifacts

| Artifact Type | Source | Internal Location | Sync Frequency |
|---------------|--------|-------------------|----------------|
| Container Images | registry.redhat.io | nexus.internal/redhat | Monthly |
| Ansible Collections | galaxy.ansible.com | automation-hub.internal | Monthly |
| Python Packages | pypi.org | nexus.internal/pypi-proxy | As needed |
| Helm Charts | Various | nexus.internal/helm-hosted | Per release |
| RPM Packages | Red Hat CDN | satellite.internal | Monthly |
| Execution Environments | registry.redhat.io | nexus.internal/ee | Per release |

---

## 8. Security Architecture

### 8.1 Zero-Trust Model

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Zero-Trust Security Layers                           │
│                                                                              │
│  Layer 1: Network Segmentation                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Istio Service Mesh (mTLS everywhere)                                │   │
│  │  ├── Automatic certificate rotation                                  │   │
│  │  ├── Service-to-service authentication                               │   │
│  │  └── Traffic encryption in transit                                   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  Layer 2: Identity & Access                                                 │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Keycloak/Zitadel + LDAP Integration                                 │   │
│  │  ├── SAML/OIDC authentication                                        │   │
│  │  ├── RBAC enforcement                                                │   │
│  │  └── MFA required for privileged access                              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  Layer 3: Secrets Management                                                │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  CyberArk Conjur                                                     │   │
│  │  ├── Dynamic secret injection                                        │   │
│  │  ├── Credential rotation                                             │   │
│  │  └── Audit logging                                                   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  Layer 4: Policy Enforcement                                                │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Kyverno Policies                                                    │   │
│  │  ├── Pod security standards                                          │   │
│  │  ├── Image signature verification                                    │   │
│  │  └── Resource quotas                                                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 8.2 Certificate Hierarchy

```
                    ┌─────────────────────┐
                    │     Root CA         │
                    │  (Offline/HSM)      │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
    ┌─────────▼─────────┐ ┌────▼────┐ ┌────────▼────────┐
    │  Intermediate CA  │ │ Istio   │ │  CertManager    │
    │  (Infrastructure) │ │   CA    │ │      CA         │
    └─────────┬─────────┘ └────┬────┘ └────────┬────────┘
              │                │                │
    ┌─────────▼─────────┐ ┌────▼────┐ ┌────────▼────────┐
    │  Server Certs     │ │ Workload│ │  Ingress Certs  │
    │  (PostgreSQL,etc) │ │  mTLS   │ │  (*.domain.com) │
    └───────────────────┘ └─────────┘ └─────────────────┘
```

---

## 9. Decision Trees

### 9.1 Deployment Method Selection

```
                        ┌─────────────────────────┐
                        │  New Foundation Deploy? │
                        └───────────┬─────────────┘
                                    │
                        ┌───────────▼───────────┐
                        │  GitOps Required?     │
                        └───────────┬───────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │ YES           │               │ NO
                    ▼               │               ▼
        ┌───────────────────┐      │   ┌───────────────────┐
        │  ArgoCD-Based     │      │   │   Helm-Based      │
        │  Deployment       │      │   │   Deployment      │
        └─────────┬─────────┘      │   └─────────┬─────────┘
                  │                │             │
                  ▼                │             ▼
        ┌───────────────────┐      │   ┌───────────────────┐
        │ 1. Commit values  │      │   │ 1. helm repo add  │
        │    to Git repo    │      │   │ 2. helm install   │
        │ 2. Create ArgoCD  │      │   │    (in order)     │
        │    Application    │      │   │ 3. Verify pods    │
        │ 3. Sync & monitor │      │   └───────────────────┘
        └───────────────────┘      │
                                   │
                        ┌──────────▼──────────┐
                        │  Multi-Site?        │
                        └──────────┬──────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │ YES          │              │ NO
                    ▼              │              ▼
        ┌───────────────────┐     │   ┌───────────────────┐
        │ Deploy Site-A     │     │   │ Single-Site       │
        │ first, then       │     │   │ Standard Deploy   │
        │ Site-B with       │     │   └───────────────────┘
        │ cross-site config │     │
        └───────────────────┘     │
```

### 9.2 Air-Gap Content Sync Decision

```
                    ┌─────────────────────────────┐
                    │  Content Type to Sync?      │
                    └─────────────┬───────────────┘
                                  │
        ┌─────────────┬───────────┼───────────┬─────────────┐
        │             │           │           │             │
        ▼             ▼           ▼           ▼             ▼
   ┌─────────┐  ┌─────────┐ ┌─────────┐ ┌─────────┐  ┌─────────┐
   │Container│  │ Ansible │ │  Helm   │ │ Python  │  │   RPM   │
   │ Images  │  │Collections│ │ Charts │ │Packages │  │Packages │
   └────┬────┘  └────┬────┘ └────┬────┘ └────┬────┘  └────┬────┘
        │            │           │           │            │
        ▼            ▼           ▼           ▼            ▼
   ┌─────────┐  ┌─────────┐ ┌─────────┐ ┌─────────┐  ┌─────────┐
   │ skopeo  │  │ansible- │ │helm pull│ │pip      │  │reposync │
   │ copy    │  │galaxy   │ │--untar  │ │download │  │         │
   │ --all   │  │collection│ │        │ │         │  │         │
   └────┬────┘  │download │ └────┬────┘ └────┬────┘  └────┬────┘
        │       └────┬────┘      │           │            │
        │            │           │           │            │
        └────────────┴───────────┴───────────┴────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │  Transfer via Sneakernet │
                    │  (USB/DVD/Secure Copy)   │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │  Import to Internal     │
                    │  Nexus/Hub/Satellite    │
                    └─────────────────────────┘
```

### 9.3 Troubleshooting Decision Tree

```
                        ┌─────────────────────────┐
                        │  Issue Category?        │
                        └───────────┬─────────────┘
                                    │
    ┌───────────────┬───────────────┼───────────────┬───────────────┐
    │               │               │               │               │
    ▼               ▼               ▼               ▼               ▼
┌───────┐      ┌───────┐       ┌───────┐       ┌───────┐       ┌───────┐
│ Pod   │      │Network│       │ Auth  │       │ Job   │       │ Sync  │
│ Crash │      │ Issue │       │ Fail  │       │ Fail  │       │ Fail  │
└───┬───┘      └───┬───┘       └───┬───┘       └───┬───┘       └───┬───┘
    │              │               │               │               │
    ▼              ▼               ▼               ▼               ▼
┌─────────┐   ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│kubectl  │   │kubectl  │    │Check    │    │Check EE │    │argocd   │
│logs     │   │get svc  │    │Keycloak │    │image    │    │app get  │
│describe │   │istioctl │    │LDAP     │    │pull     │    │--refresh│
│events   │   │analyze  │    │Conjur   │    │creds    │    │         │
└────┬────┘   └────┬────┘    └────┬────┘    └────┬────┘    └────┬────┘
     │             │              │              │              │
     ▼             ▼              ▼              ▼              ▼
┌─────────┐   ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│Check:   │   │Check:   │    │Check:   │    │Check:   │    │Check:   │
│-Resources│  │-DNS     │    │-Token   │    │-Registry│    │-Git creds│
│-Liveness│   │-mTLS    │    │-RBAC    │    │-Network │    │-Helm repo│
│-Image   │   │-Ingress │    │-Secrets │    │-Timeout │    │-Values  │
└─────────┘   └─────────┘    └─────────┘    └─────────┘    └─────────┘
```

### 9.4 HA Failover Decision

```
                    ┌─────────────────────────────┐
                    │  Component Failure Detected │
                    └─────────────┬───────────────┘
                                  │
                    ┌─────────────▼───────────────┐
                    │  Is it a P1 Component?      │
                    └─────────────┬───────────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    │ YES         │             │ NO
                    ▼             │             ▼
        ┌───────────────────┐    │   ┌───────────────────┐
        │ Automatic         │    │   │ Manual            │
        │ Failover          │    │   │ Intervention      │
        │ (< 15 min RTO)    │    │   │ (per SLA)         │
        └─────────┬─────────┘    │   └───────────────────┘
                  │              │
        ┌─────────▼─────────┐    │
        │ Component Type?   │    │
        └─────────┬─────────┘    │
                  │              │
    ┌─────────────┼─────────────┐
    │             │             │
    ▼             ▼             ▼
┌───────┐    ┌───────┐    ┌───────┐
│K8s    │    │ AAP   │    │  DB   │
│Master │    │ Ctrl  │    │(Patroni)│
└───┬───┘    └───┬───┘    └───┬───┘
    │            │            │
    ▼            ▼            ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│etcd     │ │Pod      │ │Automatic│
│leader   │ │reschedule│ │leader   │
│election │ │to healthy│ │election │
│         │ │node     │ │         │
└─────────┘ └─────────┘ └─────────┘
```

---

## 10. Deployment Order & Dependencies

### 10.1 Foundation Base Installation Order

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Foundation Base Deployment Sequence                       │
│                                                                              │
│  Phase 1: Prerequisites                                                     │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  1. kyverno-rancher-crds    ──▶  Policy CRDs, Rancher CRDs         │   │
│  │  2. foundation-policies-certs ──▶  Kyverno policies, Cert-manager  │   │
│  │  3. zero-trust-operator     ──▶  Conjur integration operator       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                      │                                       │
│                                      ▼                                       │
│  Phase 2: Service Mesh                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  4. istio-prep              ──▶  Istio namespace, secrets          │   │
│  │  5. istiod                  ──▶  Istio control plane               │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                      │                                       │
│                                      ▼                                       │
│  Phase 3: Operators & Monitoring                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  6. foundation-operators    ──▶  PostgreSQL, Redis, Infinispan     │   │
│  │  7. monitoring-apps         ──▶  Prometheus, Grafana, Alertmanager │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                      │                                       │
│                                      ▼                                       │
│  Phase 4: Ingress & Security                                                │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  8. k8s-ingress-nginx       ──▶  Ingress controller                │   │
│  │  9. zerotrust-apps          ──▶  Conjur, Keycloak/Zitadel          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                      │                                       │
│                                      ▼                                       │
│  Phase 5: Backup & Tools                                                    │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  10. velero                 ──▶  Backup/restore                    │   │
│  │  11. foundation-cluster-tools ──▶  Utilities, dashboards           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 10.2 Dependency Matrix

| Component | Depends On | Required By |
|-----------|------------|-------------|
| kyverno-rancher-crds | - | All policies |
| foundation-policies-certs | kyverno-rancher-crds | All workloads |
| zero-trust-operator | foundation-policies-certs | zerotrust-apps |
| istio-prep | foundation-policies-certs | istiod |
| istiod | istio-prep | All mesh workloads |
| foundation-operators | istiod | Database consumers |
| monitoring-apps | foundation-operators | Alerting |
| k8s-ingress-nginx | istiod | External access |
| zerotrust-apps | zero-trust-operator, foundation-operators | AAP, Apps |
| velero | foundation-operators | Backup jobs |
| foundation-cluster-tools | All above | - |

---

## 11. Monitoring & Observability

### 11.1 Metrics Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Observability Stack                                  │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         Grafana Dashboards                           │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐        │   │
│  │  │ K8s       │  │ AAP       │  │ Istio     │  │ PostgreSQL│        │   │
│  │  │ Overview  │  │ Jobs      │  │ Mesh      │  │ Metrics   │        │   │
│  │  └───────────┘  └───────────┘  └───────────┘  └───────────┘        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                      │                                       │
│                          ┌───────────▼───────────┐                          │
│                          │      Prometheus       │                          │
│                          │   (HA: 2 replicas)    │                          │
│                          └───────────┬───────────┘                          │
│                                      │                                       │
│         ┌────────────────────────────┼────────────────────────────┐         │
│         │                            │                            │         │
│  ┌──────▼──────┐  ┌──────────────────▼──────────────────┐  ┌─────▼─────┐  │
│  │ Node        │  │           ServiceMonitors           │  │ Alertmgr  │  │
│  │ Exporter    │  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐  │  │ (HA)      │  │
│  │ (DaemonSet) │  │  │ AAP │ │Istio│ │ PG  │ │Redis│  │  └───────────┘  │
│  └─────────────┘  │  └─────┘ └─────┘ └─────┘ └─────┘  │                  │
│                   └───────────────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 11.2 Key Metrics by Priority

**P1 Metrics (Alert immediately):**
- etcd cluster health
- Kubernetes API latency > 1s
- PostgreSQL replication lag > 30s
- AAP controller pod restarts
- Certificate expiry < 7 days

**P2 Metrics (Alert within 15 min):**
- Job queue depth > 100
- Memory utilization > 85%
- Disk utilization > 80%
- Failed authentication attempts > 10/min

**P3 Metrics (Daily review):**
- Resource utilization trends
- Job success/failure rates
- API request patterns

---

## 12. Backup & Disaster Recovery

### 12.1 Backup Strategy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Backup Architecture                                  │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Velero Backup Controller                          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                      │                                       │
│         ┌────────────────────────────┼────────────────────────────┐         │
│         │                            │                            │         │
│  ┌──────▼──────┐            ┌────────▼────────┐           ┌──────▼──────┐  │
│  │ Kubernetes  │            │   PostgreSQL    │           │    Minio    │  │
│  │ Resources   │            │   pg_dump       │           │   Objects   │  │
│  │ (etcd snap) │            │   (streaming)   │           │   (sync)    │  │
│  └──────┬──────┘            └────────┬────────┘           └──────┬──────┘  │
│         │                            │                            │         │
│         └────────────────────────────┼────────────────────────────┘         │
│                                      │                                       │
│                          ┌───────────▼───────────┐                          │
│                          │   S3-Compatible       │                          │
│                          │   Object Storage      │                          │
│                          │   (Minio/External)    │                          │
│                          └───────────────────────┘                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 12.2 Backup Schedule

| Component | Frequency | Retention | Method |
|-----------|-----------|-----------|--------|
| etcd | Every 6 hours | 7 days | Snapshot |
| PostgreSQL | Every 4 hours | 14 days | pg_dump + WAL |
| Kubernetes Resources | Daily | 30 days | Velero |
| Secrets (Conjur) | Daily | 90 days | Export |
| Minio Objects | Continuous | 30 days | Replication |

### 12.3 Recovery Procedures

| Scenario | RTO | RPO | Procedure |
|----------|-----|-----|-----------|
| Single pod failure | < 5 min | 0 | Automatic reschedule |
| Node failure | < 15 min | 0 | Automatic reschedule |
| Database corruption | < 1 hour | < 4 hours | Restore from backup |
| Complete cluster loss | < 4 hours | < 6 hours | Full restore |
| Multi-site failover | < 30 min | < 5 min | DNS failover + sync |

---

## 13. Operational Runbooks

### 13.1 Daily Operations Checklist

```
┌─────────────────────────────────────────────────────────────────┐
│                    Daily Operations Checklist                    │
├─────────────────────────────────────────────────────────────────┤
│ □ Review Alertmanager for overnight alerts                      │
│ □ Check Grafana dashboards for anomalies                        │
│ □ Verify backup completion status                               │
│ □ Review AAP job success rates                                  │
│ □ Check certificate expiration dates                            │
│ □ Verify ArgoCD sync status for all applications                │
│ □ Review security scan results                                  │
│ □ Check disk utilization on all nodes                           │
└─────────────────────────────────────────────────────────────────┘
```

### 13.2 Common Commands Reference

```bash
# Kubernetes Health
kubectl get nodes -o wide
kubectl get pods -A | grep -v Running
kubectl top nodes
kubectl top pods -A --sort-by=memory

# AAP Controller
kubectl -n aap get pods
kubectl -n aap logs -l app=automation-controller -f
kubectl -n aap exec -it deploy/automation-controller -- awx-manage check

# ArgoCD Status
argocd app list
argocd app get foundation-base --refresh
argocd app sync foundation-base --prune

# Istio Mesh
istioctl analyze -A
istioctl proxy-status
kubectl -n istio-system logs -l app=istiod -f

# PostgreSQL (Patroni)
kubectl -n foundation-cluster-operators exec -it postgres-0 -- patronictl list
kubectl -n foundation-cluster-operators exec -it postgres-0 -- psql -c "SELECT * FROM pg_stat_replication;"

# Velero Backups
velero backup get
velero backup describe <backup-name>
velero restore create --from-backup <backup-name>
```

---

## 14. Appendix

### A. Port Reference

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| Kubernetes API | 6443 | TCP | Cluster management |
| etcd | 2379-2380 | TCP | Cluster state |
| Kubelet | 10250 | TCP | Node agent |
| NodePort Range | 30000-32767 | TCP | Service exposure |
| Istio Pilot | 15010-15012 | TCP | Mesh control |
| PostgreSQL | 5432 | TCP | Database |
| Redis | 6379 | TCP | Cache |
| Infinispan | 11222 | TCP | Distributed cache |
| AAP Controller | 443 | TCP | Web UI/API |
| Automation Hub | 443 | TCP | Content |

### B. Namespace Reference

| Namespace | Purpose | Priority |
|-----------|---------|----------|
| kube-system | Kubernetes core | P1 |
| istio-system | Service mesh | P1 |
| foundation-cluster-operators | Operators | P1 |
| foundation-cluster-zerotrust | Security | P1 |
| foundation-cluster-monitoring | Observability | P2 |
| aap | Ansible Automation Platform | P1 |
| argocd | GitOps | P2 |
| velero | Backup | P3 |

### C. Glossary

| Term | Definition |
|------|------------|
| AAP | Ansible Automation Platform |
| EE | Execution Environment |
| mTLS | Mutual TLS |
| RKE2 | Rancher Kubernetes Engine 2 |
| RTO | Recovery Time Objective |
| RPO | Recovery Point Objective |
| WAL | Write-Ahead Log |

---

## Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01 | Infrastructure Team | Initial release |
