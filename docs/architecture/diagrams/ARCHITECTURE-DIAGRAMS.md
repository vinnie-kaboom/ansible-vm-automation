# Architecture Diagrams (Mermaid Format)

These diagrams can be rendered in GitHub, GitLab, or any Mermaid-compatible viewer.

---

## 1. High-Level Infrastructure Overview

```mermaid
flowchart TB
    subgraph External["External Network (DMZ)"]
        ContentSources["Content Sources<br/>Red Hat Registry<br/>Ansible Galaxy<br/>PyPI"]
    end

    subgraph Transfer["Air-Gap Transfer"]
        Sneakernet["Sneakernet<br/>USB/DVD/Secure Copy"]
    end

    subgraph Internal["Internal Air-Gapped Network"]
        subgraph Management["Management Zone"]
            Bastion["Bastion Hosts"]
            GHE["GitHub Enterprise"]
            Nexus["Nexus Registry"]
            Satellite["Red Hat Satellite"]
        end

        subgraph K8sCluster["Kubernetes Cluster (RKE2)"]
            subgraph ControlPlane["Control Plane (3 nodes)"]
                Master1["Master-1<br/>etcd, API, Scheduler"]
                Master2["Master-2<br/>etcd, API, Scheduler"]
                Master3["Master-3<br/>etcd, API, Scheduler"]
            end

            subgraph Workers["Worker Nodes"]
                Worker1["Worker-1"]
                Worker2["Worker-2"]
                Worker3["Worker-N"]
            end

            subgraph Namespaces["Key Namespaces"]
                AAP["aap<br/>Ansible Automation Platform"]
                Istio["istio-system<br/>Service Mesh"]
                Operators["foundation-cluster-operators<br/>PostgreSQL, Redis"]
                ZeroTrust["foundation-cluster-zerotrust<br/>Conjur, Keycloak"]
                ArgoCD["argocd<br/>GitOps"]
            end
        end

        subgraph DataZone["Data Zone"]
            PostgreSQL["PostgreSQL<br/>Patroni HA"]
            Redis["Redis Cluster"]
            Minio["Minio<br/>Object Storage"]
        end
    end

    ContentSources --> Sneakernet
    Sneakernet --> Nexus
    Sneakernet --> Satellite

    Bastion --> K8sCluster
    GHE --> ArgoCD
    Nexus --> Workers

    AAP --> PostgreSQL
    AAP --> Redis
    Operators --> PostgreSQL
    Operators --> Redis
    Operators --> Minio
```

---

## 2. AAP Controller Architecture

```mermaid
flowchart TB
    subgraph Users["Users & Systems"]
        WebUI["Web UI Users"]
        API["API Clients"]
        GHActions["GitHub Actions"]
    end

    subgraph Ingress["Ingress Layer"]
        NGINX["Ingress-NGINX<br/>Load Balancer"]
        Istio["Istio Gateway<br/>mTLS Termination"]
    end

    subgraph AAP["AAP Controller Cluster"]
        subgraph Controllers["Controller Pods (3+)"]
            Ctrl1["Controller-1<br/>Web, API, Dispatcher"]
            Ctrl2["Controller-2<br/>Web, API, Dispatcher"]
            Ctrl3["Controller-3<br/>Web, API, Dispatcher"]
        end

        subgraph Hub["Private Automation Hub"]
            HubAPI["Hub API"]
            HubContent["Content Service"]
            HubWorker["Worker"]
        end
    end

    subgraph Execution["Execution Layer"]
        EE1["Execution Environment 1<br/>RHEL UBI + Collections"]
        EE2["Execution Environment 2<br/>Custom + VMware"]
        EE3["Execution Environment N"]
    end

    subgraph Backend["Backend Services"]
        PG["PostgreSQL<br/>Patroni HA"]
        RedisCache["Redis<br/>Job Queue"]
        Conjur["Conjur<br/>Secrets"]
    end

    subgraph Targets["Managed Infrastructure"]
        VMs["Virtual Machines"]
        Network["Network Devices"]
        Cloud["Cloud Resources"]
    end

    WebUI --> NGINX
    API --> NGINX
    GHActions --> NGINX

    NGINX --> Istio
    Istio --> Ctrl1
    Istio --> Ctrl2
    Istio --> Ctrl3

    Ctrl1 --> EE1
    Ctrl2 --> EE2
    Ctrl3 --> EE3

    Controllers --> PG
    Controllers --> RedisCache
    Controllers --> Conjur
    Hub --> PG

    EE1 --> VMs
    EE2 --> Network
    EE3 --> Cloud
```

---

## 3. GitOps Deployment Flow

```mermaid
flowchart LR
    subgraph Dev["Development"]
        Developer["Developer"]
        LocalTest["Local Testing"]
    end

    subgraph Git["GitHub Enterprise"]
        Repo["Git Repository<br/>Infrastructure Code"]
        PR["Pull Request"]
        Main["Main Branch"]
    end

    subgraph CI["CI Pipeline"]
        Lint["Ansible Lint"]
        Validate["Syntax Validation"]
        DryRun["Dry Run Test"]
    end

    subgraph CD["ArgoCD"]
        App["ArgoCD Application"]
        Sync["Sync Process"]
        Health["Health Check"]
    end

    subgraph K8s["Kubernetes"]
        Helm["Helm Release"]
        Resources["K8s Resources"]
        Pods["Running Pods"]
    end

    Developer --> LocalTest
    LocalTest --> Repo
    Repo --> PR
    PR --> Lint
    Lint --> Validate
    Validate --> DryRun
    DryRun --> Main
    Main --> App
    App --> Sync
    Sync --> Helm
    Helm --> Resources
    Resources --> Pods
    Health --> Pods
```

---

## 4. Security Architecture

```mermaid
flowchart TB
    subgraph External["External Access"]
        User["User"]
        Service["External Service"]
    end

    subgraph Layer1["Layer 1: Network"]
        FW["Firewall"]
        WAF["Web Application Firewall"]
    end

    subgraph Layer2["Layer 2: Ingress"]
        Ingress["Ingress-NGINX"]
        IstioGW["Istio Gateway"]
    end

    subgraph Layer3["Layer 3: Identity"]
        Keycloak["Keycloak/Zitadel"]
        LDAP["Enterprise LDAP"]
        MFA["MFA Provider"]
    end

    subgraph Layer4["Layer 4: Service Mesh"]
        mTLS["Istio mTLS"]
        AuthZ["Authorization Policy"]
        RateLimit["Rate Limiting"]
    end

    subgraph Layer5["Layer 5: Secrets"]
        Conjur["CyberArk Conjur"]
        K8sSecrets["K8s Secrets<br/>(encrypted)"]
        Rotation["Auto Rotation"]
    end

    subgraph Layer6["Layer 6: Policy"]
        Kyverno["Kyverno Policies"]
        PodSecurity["Pod Security Standards"]
        ImageSign["Image Signing"]
    end

    subgraph Workload["Protected Workload"]
        App["Application Pod"]
    end

    User --> FW
    Service --> FW
    FW --> WAF
    WAF --> Ingress
    Ingress --> IstioGW
    IstioGW --> Keycloak
    Keycloak --> LDAP
    Keycloak --> MFA
    IstioGW --> mTLS
    mTLS --> AuthZ
    AuthZ --> RateLimit
    RateLimit --> App
    App --> Conjur
    Conjur --> K8sSecrets
    K8sSecrets --> Rotation
    Kyverno --> App
    PodSecurity --> App
    ImageSign --> App
```

---

## 5. Multi-Site Architecture

```mermaid
flowchart TB
    subgraph SiteA["Site A (Primary)"]
        subgraph K8sA["Kubernetes Cluster A"]
            AAPA["AAP Controller"]
            PGA["PostgreSQL Primary"]
            InfinispanA["Infinispan"]
        end
        GLBA["Global Load Balancer"]
    end

    subgraph SiteB["Site B (Secondary)"]
        subgraph K8sB["Kubernetes Cluster B"]
            AAPB["AAP Controller"]
            PGB["PostgreSQL Replica"]
            InfinispanB["Infinispan"]
        end
        GLBB["Global Load Balancer"]
    end

    subgraph DNS["DNS/Traffic Management"]
        GSLB["Global Server Load Balancer"]
    end

    subgraph Users["Users"]
        Client["Client"]
    end

    Client --> GSLB
    GSLB --> GLBA
    GSLB --> GLBB

    PGA <-->|"Streaming Replication"| PGB
    InfinispanA <-->|"Cross-Site Replication<br/>ASYNC"| InfinispanB

    GLBA --> AAPA
    GLBB --> AAPB
    AAPA --> PGA
    AAPA --> InfinispanA
    AAPB --> PGB
    AAPB --> InfinispanB
```

---

## 6. Backup & Recovery Flow

```mermaid
flowchart TB
    subgraph Sources["Backup Sources"]
        etcd["etcd Snapshots"]
        PG["PostgreSQL<br/>pg_dump + WAL"]
        K8sRes["K8s Resources<br/>Velero"]
        Secrets["Conjur Secrets"]
        Objects["Minio Objects"]
    end

    subgraph Velero["Velero Controller"]
        Schedule["Backup Schedule"]
        Hooks["Pre/Post Hooks"]
    end

    subgraph Storage["Backup Storage"]
        S3["S3-Compatible<br/>Object Storage"]
        Offsite["Offsite Copy<br/>(Air-Gap Transfer)"]
    end

    subgraph Recovery["Recovery Options"]
        FullRestore["Full Cluster Restore"]
        PartialRestore["Namespace Restore"]
        DBRestore["Database PITR"]
    end

    etcd --> Schedule
    PG --> Schedule
    K8sRes --> Schedule
    Secrets --> Schedule
    Objects --> Schedule

    Schedule --> Hooks
    Hooks --> S3
    S3 --> Offsite

    S3 --> FullRestore
    S3 --> PartialRestore
    S3 --> DBRestore
```

---

## 7. Deployment Decision Flowchart

```mermaid
flowchart TD
    Start["Start Deployment"] --> NewDeploy{"New Deployment?"}

    NewDeploy -->|Yes| GitOps{"GitOps Required?"}
    NewDeploy -->|No| Upgrade["Upgrade Existing"]

    GitOps -->|Yes| ArgoCD["Use ArgoCD"]
    GitOps -->|No| Helm["Use Helm CLI"]

    ArgoCD --> MultiSite{"Multi-Site?"}
    Helm --> MultiSite

    MultiSite -->|Yes| SiteA["Deploy Site A First"]
    MultiSite -->|No| SingleSite["Single Site Deploy"]

    SiteA --> SiteB["Deploy Site B"]
    SiteB --> CrossSite["Configure Cross-Site"]

    SingleSite --> Verify["Verify Deployment"]
    CrossSite --> Verify

    Upgrade --> UpgradeType{"Upgrade Type?"}
    UpgradeType -->|Minor| RollingUpgrade["Rolling Upgrade"]
    UpgradeType -->|Major| BlueGreen["Blue-Green Deploy"]

    RollingUpgrade --> Verify
    BlueGreen --> Verify

    Verify --> Success{"Success?"}
    Success -->|Yes| Complete["Deployment Complete"]
    Success -->|No| Rollback["Rollback"]
    Rollback --> Troubleshoot["Troubleshoot"]
```

---

## 8. Troubleshooting Decision Tree

```mermaid
flowchart TD
    Issue["Issue Detected"] --> Category{"Issue Category?"}

    Category -->|Pod| PodIssue["Pod Issue"]
    Category -->|Network| NetIssue["Network Issue"]
    Category -->|Auth| AuthIssue["Auth Issue"]
    Category -->|Job| JobIssue["Job Failure"]
    Category -->|Sync| SyncIssue["Sync Issue"]

    PodIssue --> PodCheck["kubectl describe pod<br/>kubectl logs"]
    PodCheck --> PodCause{"Cause?"}
    PodCause -->|Image| ImagePull["Check Registry Access"]
    PodCause -->|Resources| ResourceQuota["Check Resource Limits"]
    PodCause -->|Crash| CrashLoop["Check App Logs"]

    NetIssue --> NetCheck["istioctl analyze<br/>kubectl get svc"]
    NetCheck --> NetCause{"Cause?"}
    NetCause -->|DNS| DNSFix["Check CoreDNS"]
    NetCause -->|mTLS| mTLSFix["Check Istio Certs"]
    NetCause -->|Ingress| IngressFix["Check Ingress Config"]

    AuthIssue --> AuthCheck["Check Keycloak<br/>Check LDAP"]
    AuthCheck --> AuthCause{"Cause?"}
    AuthCause -->|Token| TokenFix["Refresh Token"]
    AuthCause -->|RBAC| RBACFix["Check Permissions"]
    AuthCause -->|Secret| SecretFix["Check Conjur"]

    JobIssue --> JobCheck["Check EE Image<br/>Check Credentials"]
    JobCheck --> JobCause{"Cause?"}
    JobCause -->|EE| EEFix["Pull/Update EE"]
    JobCause -->|Creds| CredsFix["Update Credentials"]
    JobCause -->|Target| TargetFix["Check Target Access"]

    SyncIssue --> SyncCheck["argocd app get<br/>Check Git"]
    SyncCheck --> SyncCause{"Cause?"}
    SyncCause -->|Git| GitFix["Check Git Creds"]
    SyncCause -->|Helm| HelmFix["Check Helm Repo"]
    SyncCause -->|Values| ValuesFix["Validate Values"]
```

---

## 9. Component Priority Matrix

```mermaid
quadrantChart
    title Component Priority vs Complexity
    x-axis Low Complexity --> High Complexity
    y-axis Low Priority --> High Priority
    quadrant-1 Critical - Needs Expert
    quadrant-2 Critical - Standard
    quadrant-3 Support - Standard
    quadrant-4 Support - Needs Expert

    AAP Controller: [0.7, 0.95]
    PostgreSQL HA: [0.8, 0.9]
    etcd Cluster: [0.6, 0.85]
    Istio Mesh: [0.85, 0.8]
    Keycloak: [0.5, 0.75]
    ArgoCD: [0.4, 0.7]
    Prometheus: [0.3, 0.5]
    Grafana: [0.2, 0.45]
    Velero: [0.35, 0.4]
    Minio: [0.4, 0.35]
```

---

## 10. Data Flow Diagram

```mermaid
flowchart LR
    subgraph Input["Input Sources"]
        User["User Request"]
        Schedule["Scheduled Job"]
        Webhook["Webhook Trigger"]
    end

    subgraph AAP["AAP Processing"]
        Queue["Job Queue<br/>(Redis)"]
        Dispatcher["Dispatcher"]
        EE["Execution Environment"]
    end

    subgraph Secrets["Secrets Resolution"]
        Conjur["Conjur"]
        Vault["Credential Store"]
    end

    subgraph Targets["Target Systems"]
        VM["Virtual Machines"]
        Net["Network Devices"]
        Cloud["Cloud APIs"]
    end

    subgraph Output["Output"]
        Logs["Job Logs"]
        Facts["Gathered Facts"]
        Callback["Callback URL"]
    end

    User --> Queue
    Schedule --> Queue
    Webhook --> Queue

    Queue --> Dispatcher
    Dispatcher --> EE
    EE --> Conjur
    Conjur --> Vault
    Vault --> EE

    EE --> VM
    EE --> Net
    EE --> Cloud

    VM --> Facts
    Net --> Facts
    Cloud --> Facts

    EE --> Logs
    Facts --> Logs
    Logs --> Callback
```

---

## Usage Notes

1. **GitHub/GitLab**: These diagrams render automatically in markdown files
2. **VS Code**: Install "Markdown Preview Mermaid Support" extension
3. **Export**: Use [Mermaid Live Editor](https://mermaid.live) for PNG/SVG export
4. **Documentation**: Embed in Confluence using Mermaid macro
