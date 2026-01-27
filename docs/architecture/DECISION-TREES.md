# Operational Decision Trees

Quick reference for common operational decisions in the AAP air-gapped HA environment.

---

## 1. Deployment Method Selection

```
START: New Foundation Deployment
│
├─► Is GitOps/ArgoCD required for compliance?
│   │
│   ├─► YES ──► ArgoCD-Based Deployment
│   │           │
│   │           ├─► 1. Commit values to Git repository
│   │           ├─► 2. Create ArgoCD Application manifest
│   │           ├─► 3. Apply Application to cluster
│   │           └─► 4. Monitor sync status
│   │
│   └─► NO ───► Helm-Based Deployment
│               │
│               ├─► 1. helm repo add foundation <repo-url>
│               ├─► 2. helm install (in dependency order)
│               └─► 3. Verify pod status
│
├─► Is this a Multi-Site deployment?
│   │
│   ├─► YES ──► Multi-Site Procedure
│   │           │
│   │           ├─► 1. Deploy Site-A completely first
│   │           ├─► 2. Verify Site-A health
│   │           ├─► 3. Deploy Site-B with cross-site config
│   │           ├─► 4. Configure Infinispan cross-site replication
│   │           └─► 5. Test failover
│   │
│   └─► NO ───► Single-Site Standard Deploy
│
└─► END: Verify deployment health
```

---

## 2. Air-Gap Content Sync Decision

```
START: Content needs to be synced to air-gapped environment
│
├─► What type of content?
│   │
│   ├─► Container Images
│   │   │
│   │   ├─► Source: registry.redhat.io, quay.io, docker.io
│   │   ├─► Tool: skopeo copy --all
│   │   ├─► Export: skopeo copy docker://source dir:./images
│   │   ├─► Transfer: USB/DVD/Secure file transfer
│   │   └─► Import: skopeo copy dir:./images docker://nexus.internal/...
│   │
│   ├─► Ansible Collections
│   │   │
│   │   ├─► Source: galaxy.ansible.com, console.redhat.com
│   │   ├─► Tool: ansible-galaxy collection download
│   │   ├─► Export: tar.gz files
│   │   ├─► Transfer: USB/DVD/Secure file transfer
│   │   └─► Import: ansible-galaxy collection publish to Private Hub
│   │
│   ├─► Helm Charts
│   │   │
│   │   ├─► Source: Various Helm repositories
│   │   ├─► Tool: helm pull --untar
│   │   ├─► Export: Chart directories or .tgz files
│   │   ├─► Transfer: USB/DVD/Secure file transfer
│   │   └─► Import: helm push to Nexus Helm hosted repo
│   │
│   ├─► Python Packages
│   │   │
│   │   ├─► Source: pypi.org
│   │   ├─► Tool: pip download -d ./packages
│   │   ├─► Export: .whl and .tar.gz files
│   │   ├─► Transfer: USB/DVD/Secure file transfer
│   │   └─► Import: Upload to Nexus PyPI hosted repo
│   │
│   └─► RPM Packages
│       │
│       ├─► Source: Red Hat CDN
│       ├─► Tool: reposync, subscription-manager
│       ├─► Export: RPM files + repodata
│       ├─► Transfer: USB/DVD/Secure file transfer
│       └─► Import: Sync to Red Hat Satellite
│
└─► END: Verify content availability in internal repos
```

---

## 3. Troubleshooting Decision Tree

### 3.1 Pod Not Running

```
START: Pod is not in Running state
│
├─► What is the pod status?
│   │
│   ├─► Pending
│   │   │
│   │   ├─► Check: kubectl describe pod <name>
│   │   ├─► Look for: Events section
│   │   │
│   │   ├─► "Insufficient cpu/memory"
│   │   │   └─► Action: Scale cluster or adjust resource requests
│   │   │
│   │   ├─► "No nodes match selector"
│   │   │   └─► Action: Check nodeSelector/affinity rules
│   │   │
│   │   ├─► "PersistentVolumeClaim not bound"
│   │   │   └─► Action: Check storage class and PV availability
│   │   │
│   │   └─► "ImagePullBackOff" (in events)
│   │       └─► Go to ImagePullBackOff section
│   │
│   ├─► ImagePullBackOff / ErrImagePull
│   │   │
│   │   ├─► Check: kubectl describe pod <name>
│   │   ├─► Look for: Image name and pull error
│   │   │
│   │   ├─► "unauthorized" or "access denied"
│   │   │   └─► Action: Check imagePullSecrets, verify registry credentials
│   │   │
│   │   ├─► "not found" or "manifest unknown"
│   │   │   └─► Action: Verify image exists in registry, check tag
│   │   │
│   │   └─► "connection refused" or "timeout"
│   │       └─► Action: Check network to registry, DNS resolution
│   │
│   ├─► CrashLoopBackOff
│   │   │
│   │   ├─► Check: kubectl logs <pod> --previous
│   │   ├─► Look for: Application errors, stack traces
│   │   │
│   │   ├─► "OOMKilled" in describe output
│   │   │   └─► Action: Increase memory limits
│   │   │
│   │   ├─► Application configuration error
│   │   │   └─► Action: Check ConfigMaps, Secrets, environment variables
│   │   │
│   │   ├─► Database connection failure
│   │   │   └─► Action: Check DB service, credentials, network policies
│   │   │
│   │   └─► Liveness probe failure
│   │       └─► Action: Adjust probe timing or fix application health endpoint
│   │
│   └─► Error / Failed
│       │
│       ├─► Check: kubectl describe pod <name>
│       ├─► Look for: Exit code, termination message
│       │
│       └─► Action: Review logs, check init containers, verify secrets
│
└─► END: Pod should be Running
```

### 3.2 Network Connectivity Issues

```
START: Service-to-service communication failing
│
├─► Is DNS resolving correctly?
│   │
│   ├─► Check: kubectl exec <pod> -- nslookup <service>
│   │
│   ├─► NO ──► DNS Issue
│   │          │
│   │          ├─► Check CoreDNS pods: kubectl -n kube-system get pods -l k8s-app=kube-dns
│   │          ├─► Check CoreDNS logs: kubectl -n kube-system logs -l k8s-app=kube-dns
│   │          └─► Verify service exists: kubectl get svc <service> -n <namespace>
│   │
│   └─► YES ─► Continue to next check
│
├─► Is the service endpoint healthy?
│   │
│   ├─► Check: kubectl get endpoints <service> -n <namespace>
│   │
│   ├─► Empty endpoints
│   │   └─► Action: Check pod labels match service selector
│   │
│   └─► Endpoints exist ─► Continue to next check
│
├─► Is Istio mTLS causing issues?
│   │
│   ├─► Check: istioctl analyze -n <namespace>
│   ├─► Check: kubectl get peerauthentication -A
│   │
│   ├─► mTLS mismatch
│   │   └─► Action: Ensure both pods have Istio sidecar, check PeerAuthentication
│   │
│   └─► No mTLS issues ─► Continue to next check
│
├─► Are NetworkPolicies blocking traffic?
│   │
│   ├─► Check: kubectl get networkpolicy -n <namespace>
│   │
│   ├─► Restrictive policy exists
│   │   └─► Action: Add ingress/egress rules for required traffic
│   │
│   └─► No blocking policies ─► Continue to next check
│
└─► Check application-level issues
    │
    ├─► Verify port numbers match
    ├─► Check application logs for connection errors
    └─► Test with kubectl port-forward for direct access
```

### 3.3 Authentication Failures

```
START: User or service authentication failing
│
├─► What type of authentication?
│   │
│   ├─► User Login (Web UI)
│   │   │
│   │   ├─► Check Keycloak/Zitadel status
│   │   │   └─► kubectl -n foundation-cluster-zerotrust get pods -l app=keycloak
│   │   │
│   │   ├─► Check LDAP connectivity
│   │   │   └─► Test LDAP bind from Keycloak pod
│   │   │
│   │   ├─► "Invalid credentials"
│   │   │   └─► Verify user exists in LDAP, check password
│   │   │
│   │   ├─► "User not found"
│   │   │   └─► Check LDAP user search base, sync users
│   │   │
│   │   └─► "Session expired"
│   │       └─► Check token lifetime settings, refresh token
│   │
│   ├─► Service Account (API)
│   │   │
│   │   ├─► Check ServiceAccount exists
│   │   │   └─► kubectl get sa <name> -n <namespace>
│   │   │
│   │   ├─► Check RBAC permissions
│   │   │   └─► kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<sa>
│   │   │
│   │   └─► Token issues
│   │       └─► Check token expiry, regenerate if needed
│   │
│   └─► Conjur Secrets
│       │
│       ├─► Check Conjur connectivity
│       │   └─► kubectl -n foundation-cluster-zerotrust get pods -l app=conjur
│       │
│       ├─► "Permission denied"
│       │   └─► Check Conjur policy, verify host identity
│       │
│       └─► "Secret not found"
│           └─► Verify secret path, check policy grants
│
└─► END: Authentication should succeed
```

### 3.4 AAP Job Failures

```
START: Ansible job failed
│
├─► Where did the job fail?
│   │
│   ├─► Job didn't start
│   │   │
│   │   ├─► Check Execution Environment
│   │   │   └─► Verify EE image exists in registry
│   │   │
│   │   ├─► Check job queue
│   │   │   └─► Redis connectivity, queue depth
│   │   │
│   │   └─► Check controller logs
│   │       └─► kubectl -n aap logs -l app=automation-controller
│   │
│   ├─► Job started but failed during execution
│   │   │
│   │   ├─► Check job output in AAP UI
│   │   │
│   │   ├─► "Host unreachable"
│   │   │   │
│   │   │   ├─► Check network connectivity to target
│   │   │   ├─► Verify SSH/WinRM credentials
│   │   │   └─► Check firewall rules
│   │   │
│   │   ├─► "Permission denied"
│   │   │   │
│   │   │   ├─► Check credential in AAP
│   │   │   ├─► Verify sudo/become configuration
│   │   │   └─► Check target user permissions
│   │   │
│   │   ├─► "Module not found"
│   │   │   │
│   │   │   ├─► Verify collection is in EE
│   │   │   ├─► Check collection version compatibility
│   │   │   └─► Rebuild EE with required collections
│   │   │
│   │   └─► Task-specific error
│   │       │
│   │       ├─► Review task output
│   │       ├─► Check module documentation
│   │       └─► Test playbook locally with -vvv
│   │
│   └─► Job completed with failures
│       │
│       ├─► Review failed hosts
│       ├─► Check host-specific issues
│       └─► Consider retry with --limit @retry_file
│
└─► END: Job should complete successfully
```

---

## 4. Upgrade Decision Tree

```
START: Upgrade required
│
├─► What type of upgrade?
│   │
│   ├─► Patch version (e.g., 2.4.1 → 2.4.2)
│   │   │
│   │   ├─► Risk: Low
│   │   ├─► Method: Rolling upgrade
│   │   ├─► Downtime: None expected
│   │   │
│   │   └─► Procedure:
│   │       ├─► 1. Review release notes
│   │       ├─► 2. Backup current state
│   │       ├─► 3. Update Helm values with new version
│   │       ├─► 4. helm upgrade or ArgoCD sync
│   │       └─► 5. Verify health
│   │
│   ├─► Minor version (e.g., 2.4 → 2.5)
│   │   │
│   │   ├─► Risk: Medium
│   │   ├─► Method: Rolling upgrade with validation
│   │   ├─► Downtime: Brief during pod restarts
│   │   │
│   │   └─► Procedure:
│   │       ├─► 1. Review upgrade guide thoroughly
│   │       ├─► 2. Test in non-prod environment
│   │       ├─► 3. Full backup (Velero + DB)
│   │       ├─► 4. Schedule maintenance window
│   │       ├─► 5. Upgrade in dependency order
│   │       ├─► 6. Run post-upgrade validation
│   │       └─► 7. Monitor for 24 hours
│   │
│   └─► Major version (e.g., 2.x → 3.x)
│       │
│       ├─► Risk: High
│       ├─► Method: Blue-Green or parallel deployment
│       ├─► Downtime: Planned cutover window
│       │
│       └─► Procedure:
│           ├─► 1. Detailed planning and testing
│           ├─► 2. Deploy new version in parallel
│           ├─► 3. Migrate data/configuration
│           ├─► 4. Validate new environment
│           ├─► 5. DNS/LB cutover
│           ├─► 6. Keep old environment for rollback
│           └─► 7. Decommission old after validation period
│
├─► Is this a Multi-Site environment?
│   │
│   ├─► YES
│   │   │
│   │   ├─► Upgrade Site-B (secondary) first
│   │   ├─► Validate Site-B health
│   │   ├─► Failover traffic to Site-B
│   │   ├─► Upgrade Site-A (primary)
│   │   ├─► Validate Site-A health
│   │   └─► Restore normal traffic distribution
│   │
│   └─► NO ─► Standard single-site upgrade
│
└─► END: Upgrade complete, monitor for issues
```

---

## 5. Incident Response Decision Tree

```
START: Incident detected
│
├─► Severity assessment
│   │
│   ├─► P1 - Critical (Production down)
│   │   │
│   │   ├─► Immediate actions:
│   │   │   ├─► Page on-call team
│   │   │   ├─► Start incident bridge
│   │   │   ├─► Begin troubleshooting
│   │   │   └─► Consider failover if multi-site
│   │   │
│   │   ├─► RTO: < 15 minutes
│   │   └─► Escalation: Immediate to management
│   │
│   ├─► P2 - High (Degraded service)
│   │   │
│   │   ├─► Immediate actions:
│   │   │   ├─► Alert on-call team
│   │   │   ├─► Begin investigation
│   │   │   └─► Assess impact scope
│   │   │
│   │   ├─► RTO: < 1 hour
│   │   └─► Escalation: Within 30 minutes if no progress
│   │
│   ├─► P3 - Medium (Non-critical issue)
│   │   │
│   │   ├─► Actions:
│   │   │   ├─► Create incident ticket
│   │   │   ├─► Investigate during business hours
│   │   │   └─► Plan remediation
│   │   │
│   │   ├─► RTO: < 4 hours
│   │   └─► Escalation: If SLA at risk
│   │
│   └─► P4 - Low (Minor issue)
│       │
│       ├─► Actions:
│       │   ├─► Log issue
│       │   └─► Schedule fix in next maintenance
│       │
│       └─► RTO: Next business day
│
├─► Is failover needed?
│   │
│   ├─► YES (Multi-site available)
│   │   │
│   │   ├─► 1. Verify secondary site health
│   │   ├─► 2. Update DNS/GSLB to secondary
│   │   ├─► 3. Confirm traffic shift
│   │   ├─► 4. Continue troubleshooting primary
│   │   └─► 5. Plan failback after resolution
│   │
│   └─► NO ─► Continue troubleshooting
│
├─► Resolution
│   │
│   ├─► Document root cause
│   ├─► Implement fix
│   ├─► Verify resolution
│   ├─► Update runbooks if needed
│   └─► Schedule post-incident review
│
└─► END: Incident resolved
```

---

## Quick Reference Commands

### Health Checks
```bash
# Overall cluster health
kubectl get nodes
kubectl get pods -A | grep -v Running

# AAP health
kubectl -n aap get pods
kubectl -n aap exec deploy/automation-controller -- awx-manage check

# Database health
kubectl -n foundation-cluster-operators exec postgres-0 -- patronictl list

# ArgoCD sync status
argocd app list
```

### Common Fixes
```bash
# Restart stuck pod
kubectl -n <namespace> delete pod <pod-name>

# Force ArgoCD sync
argocd app sync <app-name> --force

# Clear Redis cache
kubectl -n aap exec deploy/automation-controller -- redis-cli FLUSHALL

# Rotate certificates
kubectl -n istio-system delete secret istio-ca-secret
kubectl -n istio-system rollout restart deploy/istiod
```
