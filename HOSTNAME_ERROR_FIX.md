# Fix: "Hostname parameter is missing" Error

## Problem
```
"msg": "Hostname parameter is missing. Please specify this parameter in task or export environment variable like 'export VMWARE_HOST=ESXI_HOSTNAME'"
```

## Root Cause
The `module_defaults` were initially placed in **role directories** (`roles/*/module_defaults/main.yml`), which Ansible does not recognize. Module defaults **must** be defined at the **play level** in playbooks.

Additionally, the wrong group name was used: `group/community.vmware.vmware` instead of the correct `group/vmware`.

## Solution

### ✅ Correct Implementation

Module defaults are now defined at the play level in all playbooks using the correct group name:

```yaml
---
- name: "Linux VM Provisioning from Template"
  hosts: "{{ ansible_host | default('all') }}"
  connection: local

  module_defaults:
    group/vmware:
      hostname: "{{ vcenter_host }}"
      username: "{{ vcenter_user }}"
      password: "{{ vcenter_user_password }}"
      validate_certs: "{{ vcenter_validate_certs }}"

  roles:
    - provisioning/vmware_provisioning
```

### Why `group/vmware` Works

According to [Ansible documentation](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_module_defaults.html#module-defaults-groups), `group/vmware` is a **predefined action group** that includes:

- `community.vmware.vmware` modules
- All modules in the community.vmware collection

This means ALL VMware modules automatically inherit these connection parameters:
- ✅ `vmware_guest`
- ✅ `vmware_guest_powerstate`
- ✅ `vmware_guest_info`
- ✅ `vmware_about_info`
- ✅ `vmware_datacenter_info`
- ✅ `vmware_cluster_info`
- ✅ `vmware_datastore_info`
- ✅ And all other community.vmware modules

## Files Updated

All playbooks that use VMware modules now have `module_defaults` configured:

| File | Status |
|------|--------|
| `playbooks/provisioning/provision/linux/provision_vm.yml` | ✅ Fixed |
| `playbooks/provisioning/provision/windows/provision_windows_vm.yml` | ✅ Fixed |
| `playbooks/provisioning/testing/test_vcenter.yml` | ✅ Fixed |
| `playbooks/provisioning/testing/check_vm_status.yml` | ✅ Fixed |
| `playbooks/provisioning/error_handling/cleanup.yml` | ✅ Fixed |

## Verification

Check that all playbooks have the correct module_defaults:

```bash
grep -A 5 "module_defaults:" playbooks/provisioning/provision/linux/provision_vm.yml
```

Expected output:
```yaml
  module_defaults:
    group/vmware:
      hostname: "{{ vcenter_host }}"
      username: "{{ vcenter_user }}"
      password: "{{ vcenter_user_password }}"
      validate_certs: "{{ vcenter_validate_certs }}"
```

## What Changed in Tasks

Tasks no longer need to specify connection parameters:

### Before (Redundant)
```yaml
- name: "Clone VM from template"
  community.vmware.vmware_guest:
    hostname: "{{ vcenter_host }}"
    username: "{{ vcenter_user }}"
    password: "{{ vcenter_user_password }}"
    validate_certs: "{{ vcenter_validate_certs }}"
    name: "{{ config_vm_name }}"
    template: "{{ config_vm_template }}"
    # ... other params
```

### After (Clean)
```yaml
- name: "Clone VM from template"
  community.vmware.vmware_guest:
    name: "{{ config_vm_name }}"
    template: "{{ config_vm_template }}"
    # ... other params
    # Connection params inherited from module_defaults
```

## Testing

To verify the fix works:

1. **Syntax Check:**
   ```bash
   ansible-playbook --syntax-check playbooks/site.yml
   ```

2. **Dry Run:**
   ```bash
   ansible-playbook playbooks/site.yml --check
   ```

3. **Test vCenter Connection:**
   ```bash
   ansible-playbook playbooks/provisioning/testing/test_vcenter.yml
   ```

4. **Provision Test VM:**
   ```bash
   ansible-playbook playbooks/provisioning/provision/linux/provision_vm.yml --limit test_host
   ```

## Key Takeaways

1. ✅ `module_defaults` must be at **play level**, not in role directories
2. ✅ Use `group/vmware` for all community.vmware modules
3. ✅ Variables like `{{ vcenter_host }}` are resolved from inventory at runtime
4. ✅ All tasks in the play (including roles) inherit the defaults
5. ✅ Individual tasks can still override defaults if needed

## References

- [Ansible Module Defaults Documentation](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_module_defaults.html)
- [Module Defaults Groups](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_module_defaults.html#module-defaults-groups)
- [Community VMware Collection](https://docs.ansible.com/ansible/latest/collections/community/vmware/index.html)
