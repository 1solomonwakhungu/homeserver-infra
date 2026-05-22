# Root Terragrunt configuration shared by all rack stacks.
#
# State is configured in one generated Terraform backend block.
# Do not also generate a Terraform `cloud` block or add Terragrunt `remote_state`;
# Terraform supports only one backend/state mode per stack.
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "solohomeserver-org"

    workspaces {
      name = "${basename(get_terragrunt_dir())}"
    }
  }
}
EOF
}

# Generate Terraform provider and version constraints for each rack stack.
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_user             = var.proxmox_user != "" ? var.proxmox_user : null
  pm_password         = var.proxmox_password != "" ? var.proxmox_password : null
  pm_api_token_id     = var.proxmox_api_token_id != "" ? var.proxmox_api_token_id : null
  pm_api_token_secret = var.proxmox_api_token_secret != "" ? var.proxmox_api_token_secret : null
  pm_tls_insecure     = var.proxmox_tls_insecure
}
EOF
}

generate "proxmox_variables" {
  path      = "proxmox_variables.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "proxmox_api_url" {
  description = "Proxmox API URL, for example https://pve.example.com:8006/api2/json."
  type        = string
  sensitive   = true
}

variable "proxmox_user" {
  description = "Proxmox username for password auth. Leave blank when using API tokens."
  type        = string
  default     = ""
  sensitive   = true
}

variable "proxmox_password" {
  description = "Proxmox password for password auth. Prefer API tokens for automation."
  type        = string
  default     = ""
  sensitive   = true
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID, for example terraform@pve!homeserver."
  type        = string
  default     = ""
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret."
  type        = string
  default     = ""
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Allow self-signed Proxmox TLS certificates. Keep false unless explicitly accepting homelab/self-signed TLS risk."
  type        = bool
  default     = false
}
EOF
}

inputs = {
  proxmox_api_url          = get_env("PM_API_URL", "")
  proxmox_user             = get_env("PM_USER", "")
  proxmox_password         = get_env("PM_PASS", "")
  proxmox_api_token_id     = get_env("PM_API_TOKEN_ID", "")
  proxmox_api_token_secret = get_env("PM_API_TOKEN_SECRET", "")
  proxmox_tls_insecure     = tobool(get_env("PM_TLS_INSECURE", "false"))
}

