# =========================
# RESOURCE GROUP
# =========================
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# =========================
# VIRTUAL NETWORK
# =========================
resource "azurerm_virtual_network" "vnet" {
  name                = "saisadhan-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# =========================
# SUBNET
# =========================
resource "azurerm_subnet" "subnet" {
  name                 = "saisadhan-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# =========================
# PUBLIC IP
# =========================
resource "azurerm_public_ip" "publicip" {
  name                = "saisadhan-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# =========================
# NSG (OPEN 80, 22 OPTIONAL)
# =========================
resource "azurerm_network_security_group" "nsg" {
  name                = "saisadhan-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# =========================
# NIC
# =========================
resource "azurerm_network_interface" "nic" {
  name                = "saisadhan-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

# =========================
# NSG ATTACHMENT
# =========================
resource "azurerm_network_interface_security_group_association" "nsgassociation" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# =========================
# LINUX VM (PASSWORD LOGIN)
# =========================
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"

  admin_username = var.admin_username
  admin_password = var.admin_password

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<EOF
#!/bin/bash

# Update packages
apt-get update -y

# Install Docker
apt-get install -y docker.io

# Start Docker
systemctl start docker
systemctl enable docker

# Pull latest image
sudo docker pull ${var.docker_username}/devops-app:latest

# Remove old container if exists
sudo docker rm -f devops-container || true

# Run container
sudo docker run -d \
  --name devops-container \
  -p 80:80 \
  ${var.docker_username}/devops-app:latest

EOF
  )
}