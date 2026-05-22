variable "node" {
  description = "The Proxmox node on which to create the VM"
  type        = string
}

variable "instance_count" {
  description = "Number of identical VMs to create"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count > 0
    error_message = "instance_count must be greater than 0."
  }
}

variable "vmid_start" {
  description = "Starting VM ID. Actual VMIDs will be vmid_start + count.index"
  type        = number
}

variable "name" {
  description = "Base name for the VM(s). If count > 1, will be name-0, name-1, etc."
  type        = string
}

variable "description" {
  description = "Description of the VM (shows as Notes in Proxmox GUI)"
  type        = string
  default     = ""
}

variable "cpu" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 4096
}

variable "disk_gb" {
  description = "Disk size in GB"
  type        = number
  default     = 32
}

variable "disk_storage" {
  description = "Storage pool name for the disk"
  type        = string
  default     = "local-lvm"
}

variable "disk_format" {
  description = "Disk format (raw, qcow2, etc.)"
  type        = string
  default     = "raw"
}

variable "template" {
  description = "Template to clone from (format: 'local:vztmpl/template-name' or VM name). Required for cloud-init."
  type        = string
  default     = null
}

variable "full_clone" {
  description = "Set to true for full clone, false for linked clone (only applies when template is set)"
  type        = bool
  default     = true
}

variable "network_bridge" {
  description = "Network bridge to attach to"
  type        = string
  default     = "vmbr0"
}

variable "network_model" {
  description = "Network card model (virtio, e1000, etc.)"
  type        = string
  default     = "virtio"
}

variable "ciuser" {
  description = "Cloud-init user name"
  type        = string
  default     = "ubuntu"
}

variable "cipassword" {
  description = "Cloud-init user password (sensitive)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ipconfig0" {
  description = "Cloud-init IP configuration (e.g., 'ip=dhcp' or 'ip=192.168.1.100/24,gw=192.168.1.1')"
  type        = string
  default     = "ip=dhcp"
}

variable "sshkeys" {
  description = "SSH public keys for cloud-init (newline delimited)"
  type        = string
  default     = ""
}

variable "nameserver" {
  description = "DNS nameserver for cloud-init"
  type        = string
  default     = ""
}

variable "searchdomain" {
  description = "DNS search domain for cloud-init"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags for the VM (list of strings)"
  type        = list(string)
  default     = []
}

variable "onboot" {
  description = "Start VM on boot"
  type        = bool
  default     = false
}

variable "agent" {
  description = "Enable QEMU Guest Agent (0 or 1)"
  type        = number
  default     = 1
}
