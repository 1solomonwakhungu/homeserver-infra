# homeserver-infra

Terraform and Terragrunt infrastructure for managing cloud-init Proxmox VMs in a small home server cluster. The repository is intentionally structured like production infrastructure: reusable Terraform modules, rack-level live stacks, remote state, CI validation, examples, and operator runbooks.

## Architecture

```text
infra/
|-- terragrunt.hcl                 # Root backend/provider/credential wiring
|-- modules/
|   `-- vm/                        # Reusable Proxmox VM module
`-- racks/
    |-- top-rack/terragrunt.hcl    # VMs targeting pvetop
    |-- middle-rack/terragrunt.hcl # VMs targeting pvemiddle
    `-- bottom-rack/terragrunt.hcl # Reserved rack, currently empty
```

Each rack is a Terragrunt stack with its own Terraform Cloud workspace. Rack files define a `vms` map, and each map entry calls `infra/modules/vm` with `for_each`. The module can create one VM or a small group of identical VMs by setting `instance_count`; VM names and IDs are derived from `name`, `vmid_start`, and the instance index.

More detail: [docs/architecture.md](docs/architecture.md).

## Prerequisites

- Terraform `>= 1.5.0`
- Terragrunt `>= 0.63`
- Terraform Cloud access to organization `solohomeserver-org`
- Proxmox API access with permissions to clone templates, create VMs, attach disks, configure cloud-init, and read VM state
- A cloud-init-ready Proxmox template on each target node
- Optional local tools for full parity with CI: `tflint`, `trivy`, and `terraform-docs`

## Quickstart

1. Authenticate to Terraform Cloud.

   ```bash
   terraform login
   ```

2. Export Proxmox credentials. Prefer API tokens for automation.

   ```bash
   export PM_API_URL="https://pve.example.invalid:8006/api2/json"
   export PM_API_TOKEN_ID="terraform@pve!homeserver"
   export PM_API_TOKEN_SECRET="<redacted-token-secret>"
   export PM_TLS_INSECURE="false"
   ```

   If the homelab Proxmox API uses a self-signed certificate and you explicitly accept that risk, set `PM_TLS_INSECURE="true"` for that shell/session.

   Password auth is also supported:

   ```bash
   export PM_API_URL="https://pve.example.invalid:8006/api2/json"
   export PM_USER="terraform@pve"
   export PM_PASS="<redacted-password>"
   export PM_TLS_INSECURE="false"
   ```

3. Review a single rack.

   ```bash
   cd infra/racks/top-rack
   terragrunt init
   terragrunt plan
   ```

4. Apply only after the plan matches the intended VM lifecycle.

   ```bash
   terragrunt apply
   ```

## Validation

Local checks that do not require Proxmox credentials:

```bash
terraform -chdir=infra/modules/vm fmt -check
terraform -chdir=infra/modules/vm init -backend=false -input=false
terraform -chdir=infra/modules/vm validate
terragrunt hclfmt --terragrunt-check
for rack in infra/racks/*; do (cd "$rack" && terragrunt init -backend=false -input=false -lockfile=readonly && terraform fmt -check && terragrunt validate-inputs && terragrunt validate); done
```

Optional checks when tools are installed:

```bash
tflint --recursive
trivy config --exit-code 1 --severity HIGH,CRITICAL .
terraform-docs markdown table infra/modules/vm
```

CI runs formatting, module validation, Terragrunt formatting, TFLint, Trivy config scanning, and terraform-docs generation where feasible.

## State And Secrets

Terragrunt owns the backend configuration by generating `backend.tf` from [infra/terragrunt.hcl](infra/terragrunt.hcl). Do not add a Terraform `cloud` block or a separate Terragrunt `remote_state` block next to it; Terraform supports only one state mode for a stack. The current backend is Terraform Cloud remote state with one workspace per rack:

- `top-rack`
- `middle-rack`
- `bottom-rack`

Secrets are supplied through environment variables and marked sensitive in Terraform variable declarations. Do not commit `.tfvars`, Terraform state, plan files, provider credentials, or generated `.terraform` directories.

Rack stack `.terraform.lock.hcl` files are committed deliberately. CI runs backendless rack init with `-lockfile=readonly`, so provider upgrades require an intentional lockfile refresh rather than happening implicitly during validation.

## Examples

Scale a small stateless VM group:

```hcl
"api-workers" = {
  instance_count = 3
  node           = "pvetop"
  vmid_start     = 310
  name           = "api-worker"
  cpu            = 2
  memory         = 4096
  disk_gb        = 32
  template       = "ubuntu-2404-cloudinit"
  ciuser         = "solomon"
  ipconfig0      = "ip=dhcp"
  tags           = ["rack=top", "role=api", "env=lab"]
  onboot         = true
}
```

Expected sanitized output shape:

```json
{
  "vms": {
    "0": {
      "id": 310,
      "name": "api-worker-0",
      "node": "pvetop",
      "ipv4": "192.0.2.10"
    }
  }
}
```

Additional sample files are in [examples](examples).

## Operations

Common operator workflows are documented in [docs/operations.md](docs/operations.md), including adding VMs, changing VMID ranges, checking plans, handling state locks, and rotating Proxmox credentials.

## Teardown Warnings

`terragrunt destroy` deletes managed VMs. In Proxmox this can remove disks and cloud-init configuration for the affected VM resources. Read [docs/teardown.md](docs/teardown.md) before any destroy operation, export outputs first, and prefer destroying one rack at a time.

## Tradeoffs

- Terraform Cloud remote state keeps locking and history out of the homelab, but local validation that initializes rack stacks requires Terraform Cloud auth.
- The repository uses `telmate/proxmox ~> 2.9` because no `~> 3.0` provider release was available during validation. The module is written to the 2.9 schema.
- Power state is not treated as authoritative desired state in this provider version. Use Proxmox or separate automation for day-to-day start/stop actions.
- Rack files duplicate the generated module wiring for readability. A future refactor could extract a shared rack include once the fleet grows.
