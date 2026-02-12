#!/bin/bash
# Validates that known syntax and path bugs are fixed.
# Exit code 0 = all tests pass, non-zero = failures detected.

PASS=0
FAIL=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

pass() { echo "  ✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Running syntax and path validation tests ==="
echo ""

# --- Test 1: site.yml references only files that exist ---
echo "Test: playbooks/site.yml import_playbook paths resolve to existing files"
while IFS= read -r line; do
    path=$(echo "$line" | sed 's/.*import_playbook: *//' | sed 's/ *$//')
    full_path="$REPO_ROOT/playbooks/$path"
    if [ -f "$full_path" ]; then
        pass "import_playbook '$path' exists"
    else
        fail "import_playbook '$path' does NOT exist (expected at $full_path)"
    fi
done < <(grep '^\- import_playbook:' "$REPO_ROOT/playbooks/site.yml" | grep -v '^ *#')

echo ""

# --- Test 2: Dockerfile has no form feed characters ---
echo "Test: Dockerfile has no form feed (\\f) characters"
if grep -P '\f' "$REPO_ROOT/Dockerfile" > /dev/null 2>&1; then
    fail "Dockerfile contains form feed character"
else
    pass "Dockerfile has no form feed characters"
fi

echo ""

# --- Test 3: provision_windows_vm.yml has no 'fa lse' typo ---
echo "Test: provision_windows_vm.yml has no 'fa lse' typo"
if grep -q 'fa lse' "$REPO_ROOT/playbooks/provisioning/provision/windows/provision_windows_vm.yml"; then
    fail "provision_windows_vm.yml contains 'fa lse' typo"
else
    pass "provision_windows_vm.yml has correct 'false' spelling"
fi

echo ""

# --- Test 4: hosts.yaml tags have proper YAML list syntax (space after dash) ---
echo "Test: inventory/hosts.yaml list items have space after dash"
if grep -P '^ +\-[^ ]' "$REPO_ROOT/inventory/hosts.yaml" > /dev/null 2>&1; then
    fail "hosts.yaml has list items missing space after dash"
else
    pass "hosts.yaml list items all have proper spacing"
fi

echo ""

# --- Test 5: verify_permissions.yml has no trailing dash on notify lines ---
echo "Test: verify_permissions.yml notify lines have no trailing syntax errors"
if grep -P 'failure\s+-\s*$' "$REPO_ROOT/roles/provisioning/vcenter_connection/tasks/verify_permissions.yml" > /dev/null 2>&1; then
    fail "verify_permissions.yml has trailing dash on notify line"
else
    pass "verify_permissions.yml notify lines are clean"
fi

echo ""

# --- Test 6: All handlers notified in validate_vars.yml exist in handlers/main.yml ---
echo "Test: handlers referenced by validate_vars.yml exist"
HANDLER_FILE="$REPO_ROOT/roles/provisioning/vcenter_connection/handlers/main.yml"
TASK_FILE="$REPO_ROOT/roles/provisioning/vcenter_connection/tasks/validate_vars.yml"
while IFS= read -r handler_name; do
    handler_name=$(echo "$handler_name" | sed 's/^ *- *//' | sed 's/ *$//')
    [ -z "$handler_name" ] && continue
    if grep -qF "$handler_name" "$HANDLER_FILE"; then
        pass "handler '$handler_name' exists"
    else
        fail "handler '$handler_name' is missing from handlers/main.yml"
    fi
done < <(grep -A1 'notify:' "$TASK_FILE" | grep '^ *-' | sed 's/^ *- *//')

echo ""

# --- Summary ---
echo "=== Results: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -gt 0 ]; then
    exit 1
else
    exit 0
fi
