output "vm_ids" {
  description = "List of VM IDs created"
  value       = [for vm in proxmox_vm_qemu.vm : vm.vmid]
}

output "vm_names" {
  description = "List of VM names created"
  value       = [for vm in proxmox_vm_qemu.vm : vm.name]
}

output "vm_nodes" {
  description = "List of nodes where VMs are running"
  value       = [for vm in proxmox_vm_qemu.vm : vm.target_node]
}

output "vm_ipv4_addresses" {
  description = "List of IPv4 addresses (if agent is enabled)"
  value       = [for vm in proxmox_vm_qemu.vm : vm.default_ipv4_address]
}

output "vms" {
  description = "Map of VM details"
  value = {
    for idx, vm in proxmox_vm_qemu.vm : idx => {
      id   = vm.vmid
      name = vm.name
      node = vm.target_node
      ipv4 = vm.default_ipv4_address
    }
  }
}
