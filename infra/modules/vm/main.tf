# VM Module - Supports count for multiple identical VMs
# Each VM gets a unique VMID: vmid_start + count.index

resource "proxmox_vm_qemu" "vm" {
  count       = var.count
  name        = var.count > 1 ? "${var.name}-${count.index}" : var.name
  target_node = var.node
  vmid        = var.vmid_start + count.index
  description = var.description != "" ? var.description : "VM ${var.name}${var.count > 1 ? " #${count.index}" : ""}"

  # CPU Configuration
  cpu {
    cores = var.cpu
    type  = "host"
  }

  # Memory Configuration
  memory = var.memory

  # Disk Configuration - using latest Proxmox provider syntax
  disks {
    scsi {
      scsi0 {
        disk {
          size    = "${var.disk_gb}G"
          storage = var.disk_storage
          format  = var.disk_format
        }
      }
    }
  }

  # Cloud-init Configuration
  disks {
    ide {
      ide2 {
        cloudinit {
          storage = var.disk_storage
        }
      }
    }
  }

  # Network Configuration
  network {
    id     = 0
    model  = var.network_model
    bridge = var.network_bridge
  }

  # Clone from template (required for cloud-init)
  clone      = var.template != null ? var.template : null
  full_clone = var.full_clone

  # Cloud-init Parameters
  ciuser       = var.ciuser
  cipassword   = var.cipassword != "" ? var.cipassword : null
  ipconfig0    = var.ipconfig0
  sshkeys      = var.sshkeys != "" ? var.sshkeys : null
  nameserver   = var.nameserver != "" ? var.nameserver : null
  searchdomain = var.searchdomain != "" ? var.searchdomain : null

  # QEMU Guest Agent
  agent = var.agent

  # Tags (convert list to comma-separated string)
  tags = length(var.tags) > 0 ? join(",", var.tags) : ""

  # Start on boot
  start_at_node_boot = var.onboot

  # VM State
  vm_state = var.vm_state

  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}
