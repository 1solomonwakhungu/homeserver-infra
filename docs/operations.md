# Operations Runbook

## Add A VM

1. Pick the rack where the VM should live.
2. Reserve a VMID range that does not overlap existing Terraform-managed or manually-managed VMs.
3. Add an entry to the rack `vms` map.
4. Run validation and plan from that rack.

```bash
cd infra/racks/top-rack
terragrunt hclfmt
terragrunt plan
```

Example entry:

```hcl
"dns-primary" = {
  instance_count = 1
  node           = "pvetop"
  vmid_start     = 230
  name           = "dns-primary"
  cpu            = 2
  memory         = 2048
  disk_gb        = 24
  template       = "ubuntu-2404-cloudinit"
  ciuser         = "solomon"
  ipconfig0      = "ip=192.0.2.53/24,gw=192.0.2.1"
  tags           = ["rack=top", "role=dns", "env=lab"]
  onboot         = true
}
```

## Scale A VM Group

Increase `instance_count` and make sure the VMID range is still free.

```hcl
"api-workers" = {
  instance_count = 3
  vmid_start     = 310
  name           = "api-worker"
}
```

Terraform will derive names like `api-worker-0` and VMIDs like `310`, `311`, and `312`.

## Credentials

Preferred API token environment variables:

```bash
export PM_API_URL="https://pve.example.invalid:8006/api2/json"
export PM_API_TOKEN_ID="terraform@pve!homeserver"
export PM_API_TOKEN_SECRET="<redacted-token-secret>"
export PM_TLS_INSECURE="false"
```

Set `PM_TLS_INSECURE="true"` only when the target Proxmox API uses a self-signed certificate and the operator explicitly accepts bypassing TLS certificate verification for that session.

Password authentication is available for bootstrap work only:

```bash
export PM_USER="terraform@pve"
export PM_PASS="<redacted-password>"
```

Rotate tokens from Proxmox, update the local or CI secret store, and rerun `terragrunt plan` to confirm provider authentication.

## State Locks

Terraform Cloud locks state during runs. If a run is interrupted:

1. Check the workspace run history in Terraform Cloud.
2. Confirm no active apply is running.
3. Unlock from Terraform Cloud only when the run is known to be dead.
4. Re-run `terragrunt plan` before any apply.

## Validation

Run these before pushing:

```bash
terraform -chdir=infra/modules/vm fmt -check
terraform -chdir=infra/modules/vm validate
terragrunt hclfmt --terragrunt-check
for rack in infra/racks/*; do (cd "$rack" && terragrunt init -backend=false -input=false -lockfile=readonly && terraform fmt -check && terragrunt validate-inputs && terragrunt validate); done
```

## Provider Lockfiles

Live rack lockfiles are committed under `infra/racks/*/.terraform.lock.hcl`. When provider constraints change, refresh them intentionally:

```bash
for rack in infra/racks/*; do (cd "$rack" && terragrunt init -backend=false -input=false -upgrade); done
```

Review and commit the resulting lockfile diffs with the provider constraint change. Routine validation uses `-lockfile=readonly` so CI fails if generated rack stacks would select provider versions that are not already locked.

Run these when installed:

```bash
tflint --recursive
trivy config --exit-code 1 --severity HIGH,CRITICAL .
terraform-docs markdown table infra/modules/vm
```

## Troubleshooting

- Template not found: confirm the `template` name exists on the target Proxmox node.
- VMID conflict: inspect Proxmox and Terraform state, then reserve a new range.
- Cloud-init networking issue: confirm `ipconfig0` syntax and that the template has cloud-init installed.
- Guest IP output is empty: confirm QEMU guest agent is installed in the template and `agent = 1`.
- Terraform Cloud auth failure: run `terraform login` or update CI `TF_API_TOKEN`.
