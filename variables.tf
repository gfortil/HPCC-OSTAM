variable "project_name" {
  type  = string
}

variable "mydropzone_folder_names" {
  type    = list
  default = ["mydropzone"]
}

variable "hpcc_upgrade" {
  type = object({
    version = string
    release = string
    edition = string
    server  = string
  })
}

variable "roxie" {
  type = object({
    count       = number
    flavor_name = string
    disk        = string
  })
}

variable "dali" {
  type = object({
    flavor_name = string
    disk        = string
  })
}

variable "dropzone" {
  type = object({
    flavor_name = string
    disk        = string
  })
}

variable "esp" {
  type = object({
    count       = number
    flavor_name = string
    disk        = string
  })
}

variable "thor" {
  type = object({
    count       = number
    flavor_name = string
    disk        = string
  })
}

variable "generic" {
  type = object({
    count       = number
    flavor_name = string
    disk        = string
  })
}

variable "system_config" {
  type = object({
    image_name    = string
    image_id      = string
    pub_key_name  = string
    private_key   = string
    subnet_name   = string
    network_name  = string
    device        = string
    mountpoint    = string
    timezone      = string
  })
}

variable "allow_traffic" {
  type = object({
    from_port = number
    to_port   = number
  })
}

variable "dns" {
  type = object({
    enabled     = bool
    zone_name   = string
    zone_ttl    = number
    zone_type   = string
    record_name = string
    record_ttl  = number
    record_type = string
    email       = string
  })
}

variable "float_ip" {
  type = object({
    enabled = bool
    address = string
  })
}

