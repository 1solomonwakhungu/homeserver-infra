# Proxmox Rack Infrastructure with Terragrunt

This directory contains Terragrunt configurations for managing VMs across different Proxmox nodes organized by racks. **Terragrunt is used to eliminate code duplication** by centralizing provider and Terraform configuration.

## Directory Structure

```
infra/
  terragrunt.hcl              # Root Terragrunt config (common provider settings)
  racks/
    top-rack/                 # VMs running on pvetop node
      terragrunt.hcl          # Points to module + rack-specific inputs
      variables.tf            # Variable definitions (for reference)
    middle-rack/              # VMs running on pvemiddle node
      terragrunt.hcl          # Points to module + rack-specific inputs
      variables.tf            # Variable definitions (for reference)
    bottom-rack/              # Reserved for future use (pve node)
  modules/
    vm/                       # Reusable VM module (called directly by Terragrunt)
```

## How Terragrunt Works Here

**Terragrunt eliminates duplication** by:

1. **Root Configuration** (`infra/terragrunt.hcl`):
   - Defines common Terraform provider configuration
   - Generates `provider.tf` automatically in each rack
   - Sets default inputs for Proxmox connection

2. **Rack-Specific Configuration** (`racks/*/terragrunt.hcl`):
   - Includes the root configuration
   - Uses `terraform { source = "../../modules/vm" }` to point directly to the module
   - Defines inputs specific to each rack (VM names, node targets, etc.)
   - **No `main.tf` needed** - Terragrunt runs the module directly!

3. **Module Outputs**:
   - Module outputs are automatically available via `terragrunt output`
   - No need for rack-level `outputs.tf` files by Terragrunt

## How Racks Work

Each rack folder represents a different Proxmox node in your homelab:

- **top-rack**: Test VMs deployed to the `pvetop` Proxmox node
- **middle-rack**: Test VMs deployed to the `pvemiddle` Proxmox node
- **bottom-rack**: Reserved for future deployments to the `pve` node

## Prerequisites

1. **Proxmox Access**: You need API access to your Proxmox cluster
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
4. **Provider Credentials**: Set up Proxmox API credentials

### Setting Up Proxmox API Credentials

You can provide credentials via environment variables (recommended):

```bash
export PM_API_URL="https://your-proxmox-server:8006/api2/json"
export PM_USER="terraform-prov@pve"
export PM_PASS="your-password"
export PM_TLS_INSECURE="true"  # For self-signed certificates
```

Or if using API tokens:

```bash
export PM_API_URL="https://your-proxmox-server:8006/api2/json"
export PM_API_TOKEN_ID="terraform-prov@pve!mytoken"
export PM_API_TOKEN_SECRET="your-token-secret"
```

**Note**: You can also override these in each rack's `terragrunt.hcl` file if needed.

## Deploying Per Rack

To deploy VMs to a specific rack using Terragrunt:

1. Navigate to the rack directory:
   ```bash
   cd infra/racks/top-rack
   ```

2. Initialize Terragrunt (this will also initialize Terraform):
   ```bash
   terragrunt init
   ```

3. Review the plan:
   ```bash
   terragrunt plan
   ```

4. Apply the configuration:
   ```bash
   terragrunt apply
   ```

### Example: Deploy Top Rack Test VM

```bash
cd infra/racks/top-rack
terragrunt init
terragrunt plan
terragrunt apply
```

This will create `test-vm-pvetop` on the `pvetop` node.

### Example: Deploy Middle Rack Test VM

```bash
cd infra/racks/middle-rack
terragrunt init
terragrunt plan
terragrunt apply
```

This will create `test-vm-pvemiddle` on the `pvemiddle` node.

## Deploying the Entire Homelab

To deploy all racks at once, you can use Terragrunt's `run-all` command from the racks directory:

```bash
cd infra/racks
terragrunt run-all init
terragrunt run-all plan
terragrunt run-all apply
```

Or deploy each rack sequentially:

```bash
# Deploy top rack
cd infra/racks/top-rack
terragrunt init && terragrunt apply

# Deploy middle rack
cd ../middle-rack
terragrunt init && terragrunt apply
```

## Current Test VMs

- **test-vm-pvetop**: Running on `pvetop` node
  - 2 CPU cores
  - 4GB RAM
  - 32GB disk
  - Cloud-init enabled
  - Tags: `rack=top,node=pvetop,environment=test`

- **test-vm-pvemiddle**: Running on `pvemiddle` node
  - 2 CPU cores
  - 4GB RAM
  - 32GB disk
  - Cloud-init enabled
  - Tags: `rack=middle,node=pvemiddle,environment=test`

## Customizing Rack Configuration

Each rack has its own `terragrunt.hcl` file where you can customize:

- VM name and description
- VM resources (CPU, memory, disk)
- Network configuration
- Tags
- VM state

Example: Edit `infra/racks/top-rack/terragrunt.hcl`:

```hcl
inputs = {
  vm_name     = "my-custom-vm-name"
  cpu_cores   = 4
  memory      = 8192  # 8GB
  disk_size   = "64G"
  # ... other settings
}
```

## VM Module

The `infra/modules/vm` directory contains a reusable VM module that provides:

- CPU and memory configuration
- Disk management
- Network configuration
- Cloud-init support
- QEMU Guest Agent support
- Tagging
- Optional clone support for templates

### Module Variables

Key variables you can customize per rack (via `terragrunt.hcl`):

- `cpu_cores` - Number of CPU cores (default: 2)
- `memory` - Memory in MB (default: 4096)
- `disk_size` - Disk size (default: "32G")
- `cloudinit_user` - Cloud-init user (default: "ubuntu")
- `cloudinit_ipconfig0` - IP configuration (default: "ip=dhcp")
- `vm_tags` - VM tags for organization

## Cloud-Init Configuration

VMs are configured with cloud-init support. You can customize in `terragrunt.hcl`:

- User credentials via `cloudinit_user` and `cloudinit_password`
- Network configuration via `cloudinit_ipconfig0`
- SSH keys via `cloudinit_sshkeys`

Example static IP configuration in `terragrunt.hcl`:

```hcl
inputs = {
  cloudinit_ipconfig0 = "ip=192.168.1.100/24,gw=192.168.1.1"
}
```

**Note**: For cloud-init to work properly, you typically need to clone from a cloud-init ready template. Add the `clone` parameter to your rack's `terragrunt.hcl`:

```hcl
inputs = {
  clone = "ubuntu-cloud-template"
  # ... other settings
}
```

## Terragrunt Benefits

Using Terragrunt provides several advantages:

1. **DRY (Don't Repeat Yourself)**: Provider and Terraform configuration defined once in root
2. **Consistency**: All racks use the same provider version and settings
3. **Flexibility**: Easy to override settings per rack
4. **State Management**: Centralized state file organization
5. **Dependency Management**: Can easily add dependencies between racks if needed

## Troubleshooting

### Provider Authentication Issues

If you encounter authentication errors:
1. Verify your Proxmox API URL is correct in environment variables
2. Check that your user has the required permissions
3. For self-signed certificates, ensure `PM_TLS_INSECURE="true"` is set

### Terragrunt Not Found

If you get "terragrunt: command not found":
- Install Terragrunt (see Prerequisites section)
- Verify installation: `terragrunt --version`

### VM Creation Fails

- Ensure the target node exists and is accessible
- Check that storage pools are available
- Verify VMID is not already in use (or leave it null to auto-assign)

### Cloud-Init Not Working

- Ensure you're cloning from a cloud-init ready template (set `clone` in `terragrunt.hcl`)
- Check that the cloud-init storage pool exists
- Verify network configuration is correct

## Adding New VMs

To add a new VM to a rack, you have two options:

### Option 1: Create a New Rack Directory

Create a new directory (e.g., `infra/racks/top-rack-2/`) with its own `terragrunt.hcl`:

```hcl
include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
  source = "../../modules/vm"
}

inputs = {
  target_node = "pvetop"
  vm_name     = "test-vm-pvetop-2"
  # ... other configuration
}
```

### Option 2: Use Terragrunt's Multiple Modules Feature

If you need multiple VMs in the same rack, you can use Terragrunt's dependency feature or create subdirectories for each VM within the rack.

## Best Practices

1. **Use version control**: Keep your Terragrunt code in Git
2. **Never commit secrets**: Use environment variables or secret management
3. **Use tags**: Tag VMs for better organization
4. **Test changes**: Always run `terragrunt plan` before `apply`
5. **Backup state**: Keep your Terraform state files backed up
6. **Use modules**: Leverage the VM module for consistency
7. **Centralize config**: Keep common settings in root `terragrunt.hcl`

## Provider Documentation

This configuration uses the [Telmate Proxmox Terraform Provider](https://registry.terraform.io/providers/telmate/proxmox/latest/docs).

For the latest provider documentation and examples, refer to:
- [Provider Documentation](https://registry.terraform.io/providers/telmate/proxmox/latest/docs)
- [VM QEMU Resource](https://registry.terraform.io/providers/telmate/proxmox/latest/docs/resources/vm_qemu)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
