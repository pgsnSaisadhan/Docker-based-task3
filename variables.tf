variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "saisadhan-rgdocker2"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "vm_name" {
  description = "VM name"
  type        = string
  default     = "docker-vm"
}

variable "admin_username" {
  description = "VM admin username"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "VM admin password"
  type        = string
  sensitive   = true
}
variable "my_ip" {
  description = "Your public IP for SSH access (use /32 format)"
  type        = string
  default     = "49.37.120.15/32"
}
variable "docker_username" {
  type = string
}