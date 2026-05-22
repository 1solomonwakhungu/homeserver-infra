# VM Module - Supports multiple identical cloud-init VMs.
# Each VM gets a unique VMID: vmid_start + count.index.

resource "proxmox_vm_qemu" "vm" {
  count       = var.instance_count
  name        = var.instance_count > 1 ? "${var.name}-${count.index}" : var.name
  target_node = var.node
  vmid        = var.vmid_start + count.index
  desc        = var.description != "" ? var.description : "VM ${var.name}${var.instance_count > 1 ? " #${count.index}" : ""}"

  os_type = "cloud-init"
  cpu     = "host"
  sockets = 1
  cores   = var.cpu
  memory  = var.memory
  scsihw  = "virtio-scsi-pci"

  disk {
    slot    = 0
    type    = "scsi"
    size    = "${var.disk_gb}G"
    storage = var.disk_storage
    format  = var.disk_format
  }

  cloudinit_cdrom_storage = var.disk_storage

  network {
    model  = var.network_model
    bridge = var.network_bridge
  }

  clone      = var.template != null ? var.template : null
  full_clone = var.full_clone

  ciuser       = var.ciuser
  cipassword   = var.cipassword != "" ? var.cipassword : null
  ipconfig0    = var.ipconfig0
  sshkeys      = var.sshkeys != "" ? var.sshkeys : null
  nameserver   = var.nameserver != "" ? var.nameserver : null
  searchdomain = var.searchdomain != "" ? var.searchdomain : null

  agent = var.agent

  tags   = length(var.tags) > 0 ? join(";", var.tags) : ""
  onboot = var.onboot
}
