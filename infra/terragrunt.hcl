# Root Terragrunt configuration
# This file contains common configuration shared across all racks

# Configure Terragrunt to use Terraform Cloud remote backend
# The cloud block in the generated terraform configuration is the primary backend config
# This remote_state block ensures Terragrunt is aware of the remote state location
remote_state {
  backend = "remote"
  config = {
    hostname     = "app.terraform.io"
    organization = "solohomeserver-org"
    workspaces {
      name = basename(get_terragrunt_dir())
    }
  }
}

# Generate Terraform provider configuration with Terraform Cloud backend
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"

  cloud {
    organization = "solohomeserver-org"

    workspaces {
      name = "${basename(get_terragrunt_dir())}"
    }
  }

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

