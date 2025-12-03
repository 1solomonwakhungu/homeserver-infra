# Root Terragrunt configuration
# This file contains common configuration shared across all racks

# Configure Terragrunt to automatically store tfstate files
remote_state {
  backend = "local"
  config = {
    path = "${get_parent_terragrunt_dir()}/.terraform/${path_relative_to_include()}/terraform.tfstate"
  }
}

# Generate Terraform provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 3.0"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = var.proxmox_tls_insecure
}
EOF
}

# Common inputs that can be overridden per rack
inputs = {
  # Proxmox connection - set via environment variables or override in rack terragrunt.hcl
  proxmox_api_url      = get_env("PM_API_URL", "")
  proxmox_user         = get_env("PM_USER", "")
  proxmox_password     = get_env("PM_PASS", "")
  proxmox_tls_insecure = tobool(get_env("PM_TLS_INSECURE", "true"))

  # Cloud-init defaults
  cloudinit_user      = "ubuntu"
  cloudinit_password  = ""
  cloudinit_ipconfig0 = "ip=dhcp"
  cloudinit_sshkeys   = ""
}

