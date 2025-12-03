# Proxmox Infrastructure with Terraform + Terragrunt

This infrastructure uses **Terraform** and **Terragrunt** to manage Proxmox VMs across multiple racks (nodes). The system is designed to be flexible, allowing you to deploy multiple VMs per rack with unique configurations or scale identical VMs using the `count` parameter.

## Directory Structure

```
infra/
├── terragrunt.hcl              # Root Terragrunt config (common provider settings)
├── racks/
│   ├── top-rack/               # VMs running on pvetop node
│   │   └── terragrunt.hcl      # VM definitions for this rack
│   ├── middle-rack/            # VMs running on pvemiddle node
│   │   └── terragrunt.hcl      # VM definitions for this rack
│   └── bottom-rack/            # VMs running on pve node (future)
│       └── terragrunt.hcl      # VM definitions for this rack
└── modules/
    └── vm/                      # Reusable VM module
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## How It Works

### 1. Racks as Environments

Each **rack** is a Terragrunt environment that represents a Proxmox node:
- **top-rack**: Deploys VMs to `pvetop` node
- **middle-rack**: Deploys VMs to `pvemiddle` node
- **bottom-rack**: Deploys VMs to `pve` node (reserved for future use)

### 2. VM Definitions

Each rack's `terragrunt.hcl` contains a `vms` map that defines all VMs to deploy:

```hcl
inputs = {
  vms = {
    "webserver-main" = {
      count      = 1
      node       = "pvetop"
      vmid_start = 200
      name       = "web-main"
      # ... other config
    }
    "api" = {
      count      = 3
      node       = "pvetop"
      vmid_start = 300
      name       = "api"
      # ... other config
    }
  }
}
```

### 3. Dynamic VM Deployment

- **Terragrunt** generates a `main.tf` that uses `for_each` to iterate over the `vms` map
- Each VM definition calls the **VM module** with its configuration
- The **VM module** uses `count` to create multiple identical VMs when `count > 1`
- **VMIDs are calculated dynamically**: `vmid = vmid_start + count.index`

### 4. Example: Scaling VMs

If you define:
```hcl
"api" = {
  count      = 3
  vmid_start = 300
  name       = "api"
  # ...
}
```

This creates:
- `api-0` with VMID `300`
- `api-1` with VMID `301`
- `api-2` with VMID `302`

## Prerequisites

1. **Proxmox Access**: API access to your Proxmox cluster
2. **Terraform**: Install Terraform (>= 1.0)
3. **Terragrunt**: Install Terragrunt (>= 0.40)
   ```bash
   # macOS
   brew install terragrunt
   
   # Linux
   wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.50.0/terragrunt_linux_amd64
   chmod +x terragrunt_linux_amd64
   sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
   ```
4. **Terraform Cloud Account**: Access to the `solohomeserver-org` organization

### Setting Up Terraform Cloud

This infrastructure uses **Terraform Cloud** for remote state management. Each rack has its own workspace:

- `top-rack` - Workspace for top-rack VMs
- `middle-rack` - Workspace for middle-rack VMs
- `bottom-rack` - Workspace for bottom-rack VMs

#### Initial Setup

1. **Login to Terraform Cloud**:
   ```bash
   terraform login
   ```
   This will open your browser to authenticate with Terraform Cloud.

2. **Verify Organization Access**:
   Ensure you have access to the `solohomeserver-org` organization in Terraform Cloud.

3. **Workspaces are Auto-Created**:
   Workspaces are automatically created when you first run `terragrunt init` or `terragrunt apply` in each rack directory.

#### Using Terraform Cloud

- **State Storage**: All Terraform state is stored remotely in Terraform Cloud
- **Workspace Isolation**: Each rack manages its own isolated workspace
- **State Locking**: Automatic state locking prevents concurrent modifications
- **State History**: Full history of state changes is available in Terraform Cloud UI

### Setting Up Proxmox API Credentials

Set environment variables:

```bash
export PM_API_URL="https://your-proxmox-server:8006/api2/json"
export PM_USER="terraform-prov@pve"
export PM_PASS="your-password"
export PM_TLS_INSECURE="true"  # For self-signed certificates
```

Or use API tokens:

```bash
export PM_API_URL="https://your-proxmox-server:8006/api2/json"
export PM_API_TOKEN_ID="terraform-prov@pve!mytoken"
export PM_API_TOKEN_SECRET="your-token-secret"
```

## Quick Start

### First-Time Setup

1. **Login to Terraform Cloud**:
   ```bash
   terraform login
   ```

2. **Initialize and Deploy**:
   ```bash
   cd infra/racks/top-rack
   terragrunt init
   terragrunt plan
   terragrunt apply
   ```

### Deploy a Single Rack

```bash
cd infra/racks/top-rack
terragrunt init
terragrunt plan
terragrunt apply
```

**Note**: The first time you run `terragrunt init`, Terraform Cloud will automatically create the workspace if it doesn't exist.

### Deploy All Racks

```bash
cd infra/racks
terragrunt run-all init
terragrunt run-all plan
terragrunt run-all apply
```

This will deploy all racks, each to its own Terraform Cloud workspace.

## Adding a New VM

Edit the rack's `terragrunt.hcl` file and add a new entry to the `vms` map:

```hcl
inputs = {
  vms = {
    # ... existing VMs ...

    "new-vm" = {
      count      = 1
      node       = "pvetop"
      vmid_start = 500
      name       = "new-vm"
      cpu        = 4
      memory     = 8192
      disk_gb    = 64
      template   = "local:vztmpl/ubuntu-22.04-cloudinit-template"
      ciuser     = "solomon"
      ipconfig0  = "ip=192.168.1.100/24,gw=192.168.1.1"
      tags       = ["rack=top", "role=app"]
      onboot     = true
    }
  }
}
```

Then apply:

```bash
cd infra/racks/top-rack
terragrunt apply
```

## Scaling VMs with Count

To deploy multiple identical VMs, set `count > 1`:

```hcl
"api-cluster" = {
  count      = 5              # Creates 5 identical VMs
  node       = "pvetop"
  vmid_start = 400            # VMIDs: 400, 401, 402, 403, 404
  name       = "api"          # Names: api-0, api-1, api-2, api-3, api-4
  cpu        = 2
  memory     = 2048
  disk_gb    = 20
  template   = "local:vztmpl/ubuntu-22.04-cloudinit-template"
  ciuser     = "solomon"
  ipconfig0  = "ip=dhcp"
  tags       = ["rack=top", "role=api"]
}
```

## Dynamic VMID Calculation

VMIDs are automatically calculated based on `vmid_start` and `count.index`:

- **Formula**: `vmid = vmid_start + count.index`
- **Example**: If `vmid_start = 300` and `count = 3`:
  - First VM: `300 + 0 = 300`
  - Second VM: `300 + 1 = 301`
  - Third VM: `300 + 2 = 302`

**Important**: Ensure `vmid_start` values don't overlap between different VM definitions to avoid conflicts.

## VM Configuration Options

Each VM definition supports the following options:

### Required Fields

- `count`: Number of identical VMs to create
- `node`: Proxmox node name (e.g., "pvetop", "pvemiddle")
- `vmid_start`: Starting VM ID (actual VMIDs = vmid_start + index)
- `name`: Base name for VM(s) (if count > 1, becomes name-0, name-1, etc.)

### Optional Fields

- `description`: VM description (default: auto-generated)
- `cpu`: CPU cores (default: 2)
- `memory`: Memory in MB (default: 4096)
- `disk_gb`: Disk size in GB (default: 32)
- `disk_storage`: Storage pool (default: "local-lvm")
- `disk_format`: Disk format (default: "raw")
- `template`: Template to clone from (required for cloud-init)
- `full_clone`: Full clone vs linked clone (default: true)
- `network_bridge`: Network bridge (default: "vmbr0")
- `network_model`: Network model (default: "virtio")
- `ciuser`: Cloud-init user (default: "ubuntu")
- `cipassword`: Cloud-init password
- `ipconfig0`: IP configuration (default: "ip=dhcp")
- `sshkeys`: SSH public keys (newline delimited)
- `nameserver`: DNS nameserver
- `searchdomain`: DNS search domain
- `tags`: List of tags (default: [])
- `onboot`: Start VM on boot (default: false)
- `vm_state`: VM state - "running", "stopped", "started" (default: "running")
- `agent`: Enable QEMU Guest Agent - 0 or 1 (default: 1)

### Example: Full VM Configuration

```hcl
"production-db" = {
  count       = 2
  node        = "pvetop"
  vmid_start  = 100
  name        = "db-prod"
  description = "Production database server"
  cpu         = 4
  memory      = 16384
  disk_gb     = 100
  disk_storage = "local-lvm"
  disk_format  = "raw"
  template     = "ubuntu-22.04-template"
  full_clone   = true
  network_bridge = "vmbr0"
  network_model  = "virtio"
  ciuser        = "admin"
  cipassword    = "secure-password"
  ipconfig0     = "ip=192.168.1.10/24,gw=192.168.1.1"
  sshkeys       = "ssh-rsa AAAAB3NzaC1yc2E..."
  nameserver    = "8.8.8.8"
  searchdomain  = "example.com"
  tags          = ["rack=top", "role=database", "env=production"]
  onboot        = true
  vm_state      = "running"
  agent         = 1
}
```

## Cloud-Init Configuration

VMs are provisioned using cloud-init. Key points:

1. **Template Required**: You must specify a `template` that is cloud-init ready
2. **IP Configuration**: Use `ipconfig0` for network setup:
   - DHCP: `"ip=dhcp"`
   - Static: `"ip=192.168.1.50/24,gw=192.168.1.1"`
3. **SSH Keys**: Provide SSH keys via `sshkeys` (newline delimited)
4. **User**: Set `ciuser` for the cloud-init user

## Network Configuration

- **Bridge**: Default is `vmbr0`, override with `network_bridge`
- **Model**: Default is `virtio` (best performance), can use `e1000` for compatibility
- **IP**: Configure via cloud-init `ipconfig0` parameter

## Tags

Tags help organize and filter VMs in Proxmox:

```hcl
tags = ["rack=top", "role=webserver", "environment=production"]
```

Tags are stored as a list and converted to comma-separated format for Proxmox.

## Autostart (onboot)

Set `onboot = true` to start VMs automatically when the Proxmox node boots:

```hcl
onboot = true
```

## Common Commands

### Single Rack

```bash
cd infra/racks/top-rack

# Initialize
terragrunt init

# Plan changes
terragrunt plan

# Apply changes
terragrunt apply

# Destroy all VMs in rack
terragrunt destroy

# Show outputs
terragrunt output
```

### All Racks

```bash
cd infra/racks

# Initialize all
terragrunt run-all init

# Plan all
terragrunt run-all plan

# Apply all
terragrunt run-all apply

# Destroy all
terragrunt run-all destroy
```

## Outputs

The VM module provides outputs for each VM group:

- `vm_ids`: List of VM IDs created
- `vm_names`: List of VM names created
- `vm_nodes`: List of nodes where VMs are running
- `vm_ipv4_addresses`: List of IPv4 addresses (if agent enabled)
- `vm_ipv6_addresses`: List of IPv6 addresses (if agent enabled)
- `vms`: Map of VM details (id, name, node, ipv4, ipv6)

Access outputs:

```bash
terragrunt output -json
```

## Troubleshooting

### VM Creation Fails

- **Check VMID conflicts**: Ensure `vmid_start` values don't overlap
- **Verify template exists**: Template name must match an existing VM/template in Proxmox
- **Check node availability**: Ensure target node exists and is accessible
- **Verify storage**: Ensure storage pool exists and has space

### Cloud-Init Not Working

- **Template required**: Must specify a cloud-init ready template
- **Check network**: Verify `ipconfig0` format is correct
- **Verify storage**: Cloud-init drive needs storage space

### Terragrunt Errors

- **Check environment variables**: Ensure Proxmox credentials are set
- **Verify Terragrunt version**: Use Terragrunt >= 0.40
- **Check file paths**: Ensure `terragrunt.hcl` includes are correct

### Terraform Cloud Issues

- **Authentication**: Run `terraform login` to authenticate with Terraform Cloud
- **Organization Access**: Ensure you have access to `solohomeserver-org` organization
- **Workspace Creation**: Workspaces are auto-created on first `terragrunt init`
- **State Locking**: If state is locked, check Terraform Cloud UI for running operations

## Best Practices

1. **VMID Planning**: Plan your VMID ranges to avoid conflicts:
   - Top rack: 100-199
   - Middle rack: 200-299
   - Bottom rack: 300-399

2. **Naming Convention**: Use descriptive names that indicate purpose:
   - `web-main`, `api-cluster`, `db-primary`

3. **Tags**: Use consistent tagging for filtering:
   - `rack=top`, `role=webserver`, `environment=production`

4. **Templates**: Create and maintain cloud-init ready templates

5. **Version Control**: Keep `terragrunt.hcl` files in Git (never commit secrets)

6. **State Management**: State is automatically managed in Terraform Cloud - no local state files

## Provider Documentation

- [Proxmox Terraform Provider](https://registry.terraform.io/providers/telmate/proxmox/latest/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)

## Example: Complete Rack Configuration

```hcl
# infra/racks/top-rack/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

generate "main" {
  path      = "main.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
module "vms" {
  source = "../../modules/vm"
  for_each = var.vms
  # ... (auto-generated)
}
EOF
}

inputs = {
  vms = {
    "webserver" = {
      count      = 2
      node       = "pvetop"
      vmid_start = 200
      name       = "web"
      cpu        = 2
      memory     = 4096
      disk_gb    = 32
      template   = "ubuntu-22.04-template"
      ciuser     = "solomon"
      ipconfig0  = "ip=dhcp"
      tags       = ["rack=top", "role=webserver"]
      onboot     = true
    }
    "database" = {
      count      = 1
      node       = "pvetop"
      vmid_start = 250
      name       = "db"
      cpu        = 4
      memory     = 8192
      disk_gb    = 100
      template   = "ubuntu-22.04-template"
      ciuser     = "solomon"
      ipconfig0  = "ip=192.168.1.10/24,gw=192.168.1.1"
      tags       = ["rack=top", "role=database"]
      onboot     = true
    }
  }
}
```

This configuration will create:
- 2 webserver VMs (web-0, web-1) with VMIDs 200, 201
- 1 database VM (db) with VMID 250

