# Example entries for a rack-level `inputs.vms` map.

api_workers = {
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

dns_primary = {
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
