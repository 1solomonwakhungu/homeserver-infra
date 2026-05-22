# Architecture

This repository separates reusable Terraform from live Terragrunt stacks:

- `infra/modules/vm` defines one Proxmox VM abstraction using the Telmate provider.
- `infra/racks/*/terragrunt.hcl` describes live VM groups for each physical rack or Proxmox node group.
- `infra/terragrunt.hcl` centralizes backend, provider, and credential inputs.

## Deployment Flow

1. An operator runs Terragrunt from a rack directory.
2. Terragrunt generates provider, backend, Proxmox variable, VM module wiring, and VM map variable files.
3. Terraform initializes a Terraform Cloud workspace named after the rack directory.
4. Terraform calls the VM module once for each entry in the rack `vms` map.
5. The VM module clones a cloud-init template into one or more VMs using `instance_count`.

## Rack Model

Racks are used as operational boundaries rather than abstract environments:

| Rack | Target node | Purpose |
| --- | --- | --- |
| `top-rack` | `pvetop` | Primary application and web workloads |
| `middle-rack` | `pvemiddle` | Test and utility workloads |
| `bottom-rack` | `pve` | Reserved capacity, currently empty |

Each rack has an isolated Terraform Cloud workspace. A plan for `top-rack` cannot directly modify `middle-rack` state.

## VM Identity

Every VM group supplies:

- `name`: base VM name
- `vmid_start`: first Proxmox VMID in the range
- `instance_count`: number of VMs to create

For `name = "api"`, `vmid_start = 300`, and `instance_count = 3`, Terraform creates:

| Instance | Name | VMID |
| --- | --- | --- |
| `0` | `api-0` | `300` |
| `1` | `api-1` | `301` |
| `2` | `api-2` | `302` |

Keep VMID ranges non-overlapping across racks and manually-created Proxmox resources.

## State Design

State is configured only by the Terragrunt-generated `backend.tf`. The generated Terraform does not contain a `cloud` block and the root Terragrunt file does not use `remote_state`, avoiding the Terraform Cloud versus backend conflict that previously blocked validation. Workspace names use `basename(get_terragrunt_dir())`, so directory names are part of the state contract.

## Provider Design

The module pins `telmate/proxmox ~> 2.9`. Validation currently resolves `2.9.14`; no `~> 3.0` release was available from the Terraform Registry at implementation time. The resource syntax uses the 2.9 schema: `cores`, `disk`, `network`, `desc`, `onboot`, and `cloudinit_cdrom_storage`.

Provider lockfiles are committed for the reusable module and for every live rack stack. The rack lockfiles are generated with backendless Terragrunt init, include `windows_amd64` and `linux_amd64` provider hashes, and are enforced in CI with `terraform init -lockfile=readonly` through Terragrunt. This keeps generated rack stacks reproducible even though their generated `backend.tf`, `provider.tf`, and `variables.tf` files are not committed.

Network interface configuration is managed by Terraform. The module intentionally does not ignore `network` drift, so manual bridge/model changes in Proxmox will appear in future plans and can be reviewed or reverted through code.

## Security Boundaries

Credentials enter through environment variables and are declared sensitive in generated Terraform variables. State can still contain sensitive Proxmox/cloud-init values, so Terraform Cloud access must be treated as privileged infrastructure access.
