# Proxmox VM Module

Reusable Terraform module for cloud-init QEMU VMs on Proxmox using `telmate/proxmox`.

Example:

```hcl
module "vm" {
  source = "../../modules/vm"

  instance_count = 2
  node           = "pvetop"
  vmid_start     = 300
  name           = "api-worker"
  cpu            = 2
  memory         = 4096
  disk_gb        = 32
  template       = "ubuntu-2404-cloudinit"
  ciuser         = "solomon"
  ipconfig0      = "ip=dhcp"
  tags           = ["rack=top", "role=api"]
  onboot         = true
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| proxmox | ~> 2.9 |

## Providers

| Name | Version |
|------|---------|
| proxmox | ~> 2.9 |

## Resources

| Name | Type |
|------|------|
| proxmox_vm_qemu.vm | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| node | The Proxmox node on which to create the VM | `string` | n/a | yes |
| vmid_start | Starting VM ID. Actual VMIDs will be vmid_start + count.index | `number` | n/a | yes |
| name | Base name for the VM(s). If count > 1, will be name-0, name-1, etc. | `string` | n/a | yes |
| instance_count | Number of identical VMs to create | `number` | `1` | no |
| description | Description of the VM (shows as Notes in Proxmox GUI) | `string` | `""` | no |
| cpu | Number of CPU cores | `number` | `2` | no |
| memory | Memory in MB | `number` | `4096` | no |
| disk_gb | Disk size in GB | `number` | `32` | no |
| disk_storage | Storage pool name for the disk | `string` | `"local-lvm"` | no |
| disk_format | Disk format (raw, qcow2, etc.) | `string` | `"raw"` | no |
| template | Template to clone from. Required for cloud-init. | `string` | `null` | no |
| full_clone | Set to true for full clone, false for linked clone | `bool` | `true` | no |
| network_bridge | Network bridge to attach to | `string` | `"vmbr0"` | no |
| network_model | Network card model | `string` | `"virtio"` | no |
| ciuser | Cloud-init user name | `string` | `"ubuntu"` | no |
| cipassword | Cloud-init user password | `string` | `""` | no |
| ipconfig0 | Cloud-init IP configuration | `string` | `"ip=dhcp"` | no |
| sshkeys | SSH public keys for cloud-init | `string` | `""` | no |
| nameserver | DNS nameserver for cloud-init | `string` | `""` | no |
| searchdomain | DNS search domain for cloud-init | `string` | `""` | no |
| tags | Tags for the VM | `list(string)` | `[]` | no |
| onboot | Start VM on boot | `bool` | `false` | no |
| agent | Enable QEMU Guest Agent | `number` | `1` | no |

## Outputs

| Name | Description |
|------|-------------|
| vm_ids | List of VM IDs created |
| vm_names | List of VM names created |
| vm_nodes | List of nodes where VMs are running |
| vm_ipv4_addresses | List of IPv4 addresses (if agent is enabled) |
| vms | Map of VM details |
<!-- END_TF_DOCS -->
