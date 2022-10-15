resource "azurerm_resource_group" "myinfra" {
  name     = "testing1"
  location = "Central India"
}

resource "azurerm_virtual_network" "example" {
  name                = "testing-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.myinfra.location
  resource_group_name = azurerm_resource_group.myinfra.name
}

resource "azurerm_subnet" "example" {
  name                 = "Testing-subnet-1"
  resource_group_name  = azurerm_resource_group.myinfra.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "example" {
  name                 = "Testing-subnet-2"
  resource_group_name  = azurerm_resource_group.myinfra.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.4.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "TestPublicIp1"
  location            = azurerm_resource_group.myinfra.location
  resource_group_name = azurerm_resource_group.myinfra.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "example" {
  name                = "TestVM-nic"
  location            = azurerm_resource_group.myinfra.location
  resource_group_name = azurerm_resource_group.myinfra.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "TestSecurityGroup1"
  location            = azurerm_resource_group.myinfra.location
  resource_group_name = azurerm_resource_group.myinfra.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "TestVM"
  location            = azurerm_resource_group.myinfra.location
  resource_group_name = azurerm_resource_group.myinfra.name
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "Password@1234"
  custom_data         = base64encode(file("scripts/init.sh"))
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]
  disable_password_authentication = "false"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}