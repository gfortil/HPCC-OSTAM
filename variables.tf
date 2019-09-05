variable "build_server" {
  type   = string
}
variable "mydropzone_folder_names" {
  type      = list
  default   = "mydropzone"
}
variable "timezone" {
  type      = string
  default   = "New_York"
}
variable "device" {
    type    = string
    default = "/dev/vdb"
}
variable "mountpoint" {
    type    = string
    default = "/mnt/vdb"
}
variable "ssh_key_private" {
    type    = string
    default = "~/.ssh/id_rsa"
}
variable "hpcc_package" {
    type = string
}
variable "hpcc_version" {
    type = string
}
variable "hpcc_release" {
    type = string
}
variable "master_disk" {
    type    = number
    default = 50
}
variable "slave_disk" {
    type    = number
    default = 50
}
variable "backup_disk" {
    type    = number
    default = 50
}
variable "dali_disk" {
    type    = number
    default = 50
}
variable "esp_disk" {
    type    = number
    default = 20
}
variable "lzone_disk" {
    type    = number
    default = 50
}

# Counts
#-----------------------------------
variable "slave_count" {
    type = number
}
variable "backup_count" {
    type = number
}

# Flavors
#-----------------------------------
variable "master_flavor_name" {
    type = string
}
variable "slave_flavor_name" {
    type = string
}
variable "backup_flavor_name" {
    type = string
}
variable "esp_flavor_name" {
    type = string
}
variable "dali_flavor_name" {
    type = string
}
variable "lzone_flavor_name" {
    type = string
}

# 
#-----------------------------------
variable "ssh_key_public" {
    type = string
    default     = "~/.ssh/id_rsa.pub"
}
variable "network_name" {
    type = string
}
variable "subnet_name" {
    type = string
}
variable "key_pair" {
    type = string
}
variable "image_name" {
    type = string
}
variable "image_id" {
    type = string
}
variable "from_port" {
    type = number
    default = 6000
}
variable "to_port" {
    type = number
    default = 9000
}


