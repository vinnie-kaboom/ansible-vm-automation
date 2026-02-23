#!/bin/bash
# Validates YAML syntax and cross-file references for common bugs.
# Exit code 0 = all tests pass, non-zero = failures detected.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0
TESTS=0

pass() {
  TESTS=$((TESTS + 1))
  echo "  PASS: $1"
}

fail() {
  TESTS=$((TESTS + 1))
  FAILURES=$((FAILURES + 1))
  echo "  FAIL: $1"
}

echo "=== Dockerfile Tests ==="

# Test 1: No form-feed characters in Dockerfile line continuations
if grep -P '\\f' "$REPO_ROOT/Dockerfile" >/dev/null 2>&1; then
  fail "Dockerfile contains \\f (form feed) instead of \\ for line continuation"
else
  pass "Dockerfile line continuations are correct"
fi

# Test 2: All RUN lines with backslash continuations end with just backslash
# Check that every line ending with \ inside RUN blocks doesn't have stray chars
if grep -E '\\[^\\[:space:]]$' "$REPO_ROOT/Dockerfile" | grep -v '^#' >/dev/null 2>&1; then
  fail "Dockerfile has lines with invalid continuation characters"
else
  pass "Dockerfile continuation characters are valid"
fi

echo ""
echo "=== Windows Provisioning Playbook Tests ==="

# Test 3: Windows provisioning has hostname in module_defaults
if grep -A5 'group/vmware:' "$REPO_ROOT/playbooks/provisioning/vm-operations/windows/provision_windows_vm.yml" | grep -q 'hostname:'; then
  pass "Windows provisioning playbook has hostname in module_defaults"
else
  fail "Windows provisioning playbook missing hostname in module_defaults"
fi

# Test 4: Linux provisioning has hostname in module_defaults (baseline check)
if grep -A5 'group/vmware:' "$REPO_ROOT/playbooks/provisioning/vm-operations/linux/provision_linux_vm.yml" | grep -q 'hostname:'; then
  pass "Linux provisioning playbook has hostname in module_defaults"
else
  fail "Linux provisioning playbook missing hostname in module_defaults"
fi

echo ""
echo "=== Domain Join tasks_from Reference Tests ==="

# Test 5: Windows domain join playbook references an existing tasks file
TASKS_FROM=$(grep 'tasks_from:' "$REPO_ROOT/playbooks/provisioning/domain-operations/join_domain/windows/join_windows_vm.yml" | awk '{print $2}')
TASKS_DIR="$REPO_ROOT/roles/domain/join_domain/tasks"
if [ -f "$TASKS_DIR/${TASKS_FROM}.yml" ]; then
  pass "Windows domain join tasks_from '$TASKS_FROM' resolves to existing file"
else
  fail "Windows domain join tasks_from '$TASKS_FROM' does not match any file in $TASKS_DIR"
fi

# Test 6: Linux domain join playbook references an existing tasks file
TASKS_FROM_LINUX=$(grep 'tasks_from:' "$REPO_ROOT/playbooks/provisioning/domain-operations/join_domain/linux/join_linux_vm.yml" | awk '{print $2}')
if [ -f "$TASKS_DIR/${TASKS_FROM_LINUX}.yml" ]; then
  pass "Linux domain join tasks_from '$TASKS_FROM_LINUX' resolves to existing file"
else
  fail "Linux domain join tasks_from '$TASKS_FROM_LINUX' does not match any file in $TASKS_DIR"
fi

echo ""
echo "=== YAML Syntax Tests ==="

# Test 7: verify_permissions.yml has no trailing garbage on notify handler names
if grep -E '^\s+-\s+\S+\s+-\s*$' "$REPO_ROOT/roles/provision/vcenter_connection/tasks/verify_permissions.yml" >/dev/null 2>&1; then
  fail "verify_permissions.yml has trailing characters on handler notify lines"
else
  pass "verify_permissions.yml handler notify lines are clean"
fi

echo ""
echo "=== Workflow Reference Tests ==="

# Test 8: test.yml references the correct inventory file extension
INVENTORY_REF=$(grep -oP 'inventory/hosts\.\w+' "$REPO_ROOT/.github/workflows/test.yml" | head -1)
if [ "$INVENTORY_REF" = "inventory/hosts.ini" ]; then
  pass "test.yml references correct inventory file (hosts.ini)"
else
  fail "test.yml references '$INVENTORY_REF' but inventory file is hosts.ini"
fi

echo ""
echo "=== Module Defaults Consistency Tests ==="

# Test 9: All provisioning playbooks with group/vmware defaults include all 4 required keys
for playbook in "$REPO_ROOT"/playbooks/provisioning/vm-operations/*/provision_*.yml; do
  name=$(basename "$(dirname "$playbook")")/$(basename "$playbook")
  for key in hostname username password validate_certs; do
    if ! grep -A10 'group/vmware:' "$playbook" | grep -q "$key:"; then
      fail "$name missing '$key' in group/vmware module_defaults"
    fi
  done
  pass "$name has all required keys in group/vmware module_defaults"
done

echo ""
echo "==========================================="
echo "Results: $TESTS tests, $FAILURES failures"
echo "==========================================="

exit $FAILURES
