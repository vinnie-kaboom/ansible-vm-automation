# 🚀 GAD Ansible VM Automation

> **VMware vCenter automation for GAD environment with comprehensive CI/CD integration**

| Component | Status | Technology | Link |
|-----------|--------|------------|------|
| 🚀 **VM Provisioning** | ✅ Active | VMware | [GitHub Repository](https://git.cce3.gpc/operations-support/ansible-vm-automation) |
| 🔧 **Ansible** | ✅ 9.12.0 | Automation | [Ansible Official](https://www.ansible.com/) |
| ⚡ **GitHub Actions** | ✅ Workflow | CI/CD | [GitHub Actions](https://github.com/features/actions) |
| 🖥️ **vCenter** | ✅ 7.0.3+ | Enterprise | [VMware vCenter](https://www.vmware.com/products/vcenter-server.html) |

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Configuration](#-configuration)
- [Workflow](#-workflow)
- [Playbooks](#-playbooks)
- [Roles](#-roles)
- [Security](#-security)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

## 🎯 Overview

**GAD Ansible VM Automation** is a comprehensive, enterprise-grade automation solution for VMware vCenter environments. Built with Ansible 9.12.0 and integrated with GitHub Actions, it provides secure, reliable, and scalable VM provisioning capabilities for the GAD infrastructure.

### 🏢 **Target Environment**

- **Organization**: GAD (Government Automation Division)
- **Infrastructure**: VMware vCenter 7.0.3+
- **Datacenter**: DSCADA-HQ-Datacenter
- **Cluster**: GADHQVMES
- **Network Zone**: OLD VA GREEN ZONE

## 🏗️ Architecture

```bash
┌─────────────────────────────────────────────────────────────────┐
│                    GitHub Actions Workflow                      │
├─────────────────────────────────────────────────────────────────┤
│  VM Config Comment  →  vCenter Test  →  Prechecks               │
│                                                                 │
│  VM Provisioning  →  Status Check  →  Cleanup                   │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Ansible Execution Layer                      │
├─────────────────────────────────────────────────────────────────┤
│  Podman Container  →  Python 3.11  →  Ansible                   │
│                                                                 │
│  Vault Decryption  →  Playbook Execution  →  Console Output     │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    VMware vCenter Layer                         │
├─────────────────────────────────────────────────────────────────┤
│  vCenter Connection  →  Template Cloning  →  VM Creation        │
│                                                                 │
│  Guest Customization  →  Network Config  →  Validation          │
└─────────────────────────────────────────────────────────────────┘
```

## ✨ Features

### 🔐 **Security & Compliance**

- **GitHub Secrets Integration** for secure credential management
- **Air-gapped Environment Support** with offline collection installation
- **Self-hosted Runner Integration** for enterprise security requirements
- **Secure Variable Management** with repository and organization secrets

### 🚀 **Automation Capabilities**

- **Template-based VM Provisioning** from VMware templates
- **Intelligent Resource Management** with cluster and datastore validation
- **Network Configuration** with static IP assignment and DHCP support
- **Guest OS Customization** with timezone, packages, and security settings

### 🔄 **CI/CD Integration**

- **GitHub Actions Workflow** with conditional job execution
- **CODEOWNERS Integration** for automatic reviewer assignment
- **Automated PR Comments** with configuration previews
- **Failure Handling** with automatic cleanup and error recovery
- **Multi-environment Support** (Development, Staging, Production)

### 📊 **Monitoring & Validation**

- **Real-time Validation** with comprehensive pre-flight checks
- **Console Output** with detailed VM information and validation results
- **Status Monitoring** with post-deployment health checks

## 📋 Prerequisites

### 🔧 **System Requirements**

- **GitHub Enterprise** with self-hosted runners
- **VMware vCenter** 7.0.3 or higher
- **Python** 3.11+ (Alpine Linux compatible)
- **Podman** for container execution

### 🐍 **Python Dependencies**

```bash
# Core packages
ansible==9.12.0
pyvmomi==8.0.2.0.1
requests
urllib3
six

# Ansible collections
community.vmware
community.general
```

### 🔐 **Required Credentials**

- **vCenter Access**: Username, password, and hostname
- **VM Template**: Pre-configured VMware template
- **Network Access**: vCenter and target network connectivity
- **Storage Access**: Datastore permissions and capacity

## 🚀 Quick Start

### 1. **Clone Repository**

```bash
git clone https://git.cce3.gpc/operations-support/ansible-vm-automation.git
cd ansible-vm-automation
```

### 2. **Configure Environment**

```bash
# Edit inventory configuration with your environment details
vim inventory/group_vars/cce3_gpc.yml
vim inventory/host_vars/specific-hosts-vars.yml
```

### 3. **Set Up GitHub Secrets**

Configure sensitive variables as GitHub repository secrets:

```bash
# Navigate to your repository settings
# Go to Settings → Secrets and variables → Actions → Repository secrets

# Add these required secrets:
VCENTER_HOSTNAME     # vCenter server hostname
VCENTER_USERNAME     # vCenter username (e.g., 'cce3\vcenter-user')
VCENTER_PASSWORD     # vCenter password
VM_ROOT_PASSWORD     # Default VM root password
VM_ANSIBLE_PASSWORD  # Ansible user password for VMs
```

### 4. **Configure CODEOWNERS (Recommended)**

Set up automatic PR reviewer assignment using CODEOWNERS:

```bash
# Edit CODEOWNERS file in repository root
# Replace @manager1 @manager2 with actual GitHub usernames

# Global approvers for all files
* @manager1 @manager2

# Configuration files require manager approval
configs/ @manager1 @manager2

# Workflow files require manager approval
.github/workflows/ @manager1 @manager2
```

**How it works:**
- **Automatic assignment** based on file paths changed in PR
- **Email notifications** sent automatically by GitHub Enterprise
- **No workflow configuration** needed
- **Standard GitHub feature** - works in all environments

**Features:**
- **Automatic assignment** - no custom actions needed
- **Path-based rules** - different reviewers for different areas
- **Email notifications** via GitHub Enterprise
- **No external dependencies** - uses GitHub's built-in system

### 5. **Provision Test VM**

```bash
# Run in dry-run mode first (validation)
ansible-playbook playbooks/provisioning/provision/linux/provision_vm.yml \
  --tags validation

# Run actual provisioning (after PR is approved and merged)
# This will be handled automatically by GitHub Actions workflow
```

## ⚙️ Configuration

### 📁 **Project Structure**

```bash
.github/
└── workflows/
    └── vm-workflow.yml          # 🚀 Main automation workflow

CODEOWNERS                       # 👥 Automatic reviewer assignment

inventory/
├── hosts-back.bak                    # 🎯 Host definitions and groups
├── group_vars/
│   ├── all.yml                 # Global configuration variables
│   ├── cce3_gpc.yml           # Domain and VM provisioning config
│   ├── cce3_gcp_linux.yml     # Linux-specific settings
│   └── cce_gcp_windows.yml   # Windows-specific settings
└── host_vars/
    └── specific-hosts-vars.yml   # Host-specific overrides

playbooks/
├── provisioning/                # VM provisioning and management
│   ├── provision/              # VM creation playbooks
│   ├── testing/                # Validation and testing

│   └── error_handling/         # Error handling and cleanup
└── infrastructure/              # Infrastructure automation (future)

roles/
├── provisioning/                # VM provisioning and management roles
│   ├── vcenter_connection/     # vCenter connectivity
│   │   └── defaults/main.yml   # 🎭 ROLE BEHAVIOR SETTINGS
│   ├── vmware_provisioning/    # VM creation
│   │   └── defaults/main.yml   # 🎭 ROLE BEHAVIOR SETTINGS

│   └── vm_validation/          # VM validation
│       └── defaults/main.yml   # 🎭 ROLE BEHAVIOR SETTINGS
└── infrastructure/              # Infrastructure automation roles (future)
```

**🎯 Key Benefits:**
- **Workflow config**: Controls HOW to run (execution)
- **Role defaults**: Controls WHAT the role does (behavior)
- **Clear separation**: Easy to find and modify settings
- **Flexible overrides**: Can override role defaults in workflow config

### 🔧 **Key Configuration Sections**

#### **Workflow Sections (Execution Control)**

```ini
[workflow]           # Default validation workflow
[vcenter_test]       # vCenter connectivity testing
[provision]          # VM provisioning execution
[status]             # VM status monitoring

[cleanup]            # Error handling and cleanup
```

#### **VM Configuration (Defaults in Role, Overrides in Workflow)**

```yaml
# Default VM settings in roles/provisioning/vmware_provisioning/defaults/main.yml
vmware_vm_config:
  name: "GADVAMSCAP03-test"
  environment: "development"

# Override in inventory when needed:
# inventory/host_vars/specific-hosts-vars.yml
# config_vm_name: "CustomVMName"
# config_vm_environment: "production"
```

#### **Role Configuration (Behavior Settings)**

Detailed configuration is in each role's `defaults/main.yml`:

- **VM Provisioning**: `roles/provisioning/vmware_provisioning/defaults/main.yml`
- **VM Validation**: `roles/provisioning/vm_validation/defaults/main.yml`
- **vCenter Connection**: `roles/provisioning/vcenter_connection/defaults/main.yml`

### 🔐 **Security Configuration**

#### **GitHub Secrets (Secure Storage)**

Configure these secrets in your GitHub repository:

```bash
# Repository Settings → Secrets and variables → Actions → Repository secrets

# vCenter Connection
VCENTER_HOSTNAME=your-vcenter.company.com
VCENTER_USERNAME=cce3\vcenter-user
VCENTER_PASSWORD=your-vcenter-password

# VM Credentials
VM_ROOT_PASSWORD=secure-root-password
VM_ANSIBLE_PASSWORD=secure-ansible-password
```

#### **Non-Sensitive Variables (Repository Files)**

```yaml
# inventory/group_vars/all.yml (public configuration)
vcenter_validate_certs: false
vcenter_datacenter: "DSCADA-HQ-Datacenter"
vcenter_cluster: "GADHQVMES"

# VM Default Settings (non-sensitive)
vm_default_settings:
  ansible_user: "ansible"
  timezone: "America/New_York"
```

## 🔄 Workflow

### 📋 **GitHub Actions Workflow**

```yaml
name: 🧪 VM Provisioning & vCenter Validation

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]
  workflow_dispatch:
    inputs:
      dry_run: boolean
      tags: string
      vm_config: string
```

### 🎯 **Job Flow**

1. **📋 VM Configuration Comment** - Posts configuration preview on PRs
2. **🧪 Test vCenter Environment** - Validates vCenter connectivity
3. **🔍 VM Provisioning Prechecks** - Runs validation and pre-flight checks
4. **🚀 VM Provisioning** - Creates VMs from templates (main branch only)
5. **📊 VM Status Check** - Validates post-deployment health (on success)
6. **🧹 Cleanup on Failure** - Removes failed deployments (on failure)

### **Job Action Flow Example (GitHub)**

![Workflow Diagram](img.png)

### 🔄 **Conditional Execution**

- **PR Events**: Configuration preview, testing, and validation
- **Push to Main**: Full provisioning workflow with status monitoring
- **Push to Develop**: Testing and validation only
- **Manual Dispatch**: Custom execution with user-defined parameters

## 📚 Playbooks

### 🧪 **Testing Playbooks**

- **`provisioning/testing/test_vcenter.yml`** - vCenter connectivity and environment validation
- **`provisioning/testing/check_vm_status.yml`** - VM operational status verification

### 🚀 **Provisioning Playbooks**

- **`provisioning/provision/linux/provision_vm.yml`** - Main VM creation from templates

### 🧹 **Error Handling Playbooks**

- **`provisioning/error_handling/cleanup.yml`** - Failed deployment cleanup and resource recovery

## 🎭 Roles

### 🌐 **provisioning/vcenter_connection**

- **Purpose**: Manages vCenter connectivity and authentication
- **Tasks**: Connection validation, permission verification, environment info
- **Outputs**: Connection status, vCenter version, API compatibility

### 🔍 **provisioning/vm_validation**

- **Purpose**: Comprehensive VM and environment validation
- **Tasks**: Template validation, resource checking, network verification
- **Outputs**: Validation results, resource availability, configuration status

### 🚀 **provisioning/vmware_provisioning**

- **Purpose**: Core VM creation and configuration
- **Tasks**: Template cloning, hardware configuration, guest customization
- **Outputs**: VM creation status, resource allocation, deployment results



## 🔐 Security

### 🗝️ **GitHub Secrets**

- **Encryption**: All sensitive variables stored as encrypted GitHub secrets
- **Access Control**: Repository and organization-level secret management
- **Audit Trail**: Full logging of secret access and usage

### 🌐 **Network Security**

- **Self-hosted Runners**: No external network access required
- **Air-gapped Support**: Offline collection installation capability
- **Secure Communication**: SSH key-based authentication

### 👥 **Access Control**

- **Role-based Permissions**: vCenter user with minimal required access
- **Environment Isolation**: Separate configurations for different environments
- **Audit Logging**: Comprehensive execution logging and reporting

## 🐛 Troubleshooting

### 🔍 **Common Issues**

#### **vCenter Connection Failures**

```bash
# Check connectivity
ansible-playbook playbooks/provisioning/testing/test_vcenter.yml --tags connectivity

# Verify GitHub secrets are configured
# Go to Repository Settings → Secrets and variables → Actions
# Ensure VCENTER_HOSTNAME, VCENTER_USERNAME, VCENTER_PASSWORD are set
```

#### **VM Provisioning Errors**

```bash
# Run validation first
ansible-playbook playbooks/provisioning/provision/linux/provision_vm.yml --tags validation

# Check VM status
ansible-playbook playbooks/provisioning/testing/check_vm_status.yml
```

#### **Workflow Failures**

```bash
# Check workflow logs
# Navigate to Actions tab in GitHub repository
# Review specific job logs for error details
```

### 📊 **Debug Mode**

```bash
# Enable debug logging
ansible-playbook playbooks/provisioning/provision/linux/provision_vm.yml -vvv

# Check specific variable values
ansible-playbook playbooks/provisioning/testing/check_vm_status.yml --tags debug
```

### 📋 **Log Locations**

- **GitHub Actions Logs**: Repository → Actions tab → Workflow run logs
- **Container Output**: Displayed in GitHub Actions job console
- **Ansible Output**: Integrated into workflow job logs

## 🤝 Contributing

### 📝 **Development Workflow**

1. **Fork Repository** - Create your own fork
2. **Create Feature Branch** - `git checkout -b feature/your-feature`
3. **Make Changes** - Implement your improvements
4. **Test Thoroughly** - Run validation and testing
5. **Submit PR** - Create pull request with detailed description

### 🧪 **Testing Requirements**

- **vCenter Tests** - All changes must pass connectivity tests
- **Validation Tests** - Configuration changes must pass validation
- **Integration Tests** - End-to-end workflow testing
- **Security Review** - All changes reviewed for security implications

### 📋 **Code Standards**

- **Ansible**: Follow Ansible best practices and style guide
- **YAML**: Consistent indentation and formatting
- **Documentation**: Update README and inline comments
- **Security**: No hardcoded credentials or sensitive data

### 🆘 **Getting Help**

- **Issues**: Create GitHub issues for bugs or feature requests
- **Documentation**: Review this README and inline code comments
- **Team**: Contact the GAD automation team for enterprise support

### 🔗 **Related Resources**

- [Ansible Documentation](https://docs.ansible.com/)
- [VMware vCenter API](https://code.vmware.com/apis/196/vsphere)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Podman Documentation](https://docs.podman.io/)

---

<div align="center">
**Built with ❤️ by the GAD Automation Team**

[![GAD](https://img.shields.io/badge/GAD-Automation-blue?style=for-the-badge)](https://git.cce3.gpc/operations-support/ansible-vm-automation)

</div>
