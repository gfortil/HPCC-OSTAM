data "openstack_networking_network_v2" "network" {
  name = var.system_config.network_name
}

data "openstack_networking_subnet_v2" "subnet" {
  name = var.system_config.subnet_name
}

# Create Security Group
#----------------------------------------------------------------

resource "openstack_networking_secgroup_v2" "secgroup" {
  name = "secgroup"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_2" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_3" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_5" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = var.allow_traffic.from_port
  port_range_max    = var.allow_traffic.to_port
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

# Create Ports
#----------------------------------------------------------------

resource "openstack_networking_port_v2" "dali_port" {
  name               = "dali_port"
  network_id         = data.openstack_networking_network_v2.network.id
  admin_state_up     = "true"
  security_group_ids = ["${openstack_networking_secgroup_v2.secgroup.id}"]

  fixed_ip {
    subnet_id  = data.openstack_networking_subnet_v2.subnet.id
    ip_address = cidrhost(data.openstack_networking_subnet_v2.subnet.cidr, 5)

  }
}

resource "openstack_networking_port_v2" "dropzone_port" {
  name               = "dropzone_port"
  network_id         = data.openstack_networking_network_v2.network.id
  admin_state_up     = "true"
  security_group_ids = ["${openstack_networking_secgroup_v2.secgroup.id}"]

  fixed_ip {
    subnet_id  = data.openstack_networking_subnet_v2.subnet.id
    ip_address = cidrhost(data.openstack_networking_subnet_v2.subnet.cidr, 6)

  }
}

resource "openstack_networking_port_v2" "esp_port" {
  count               = var.esp.count
  name                = format("esp-port-%02d", count.index + 1)
  network_id          = data.openstack_networking_network_v2.network.id
  admin_state_up      = "true"
  security_group_ids  = ["${openstack_networking_secgroup_v2.secgroup.id}"]

  fixed_ip {
    subnet_id  = data.openstack_networking_subnet_v2.subnet.id
    ip_address = cidrhost(data.openstack_networking_subnet_v2.subnet.cidr, 7 + count.index)

  }
}

resource "openstack_networking_port_v2" "roxie_port" {
  count               = var.roxie.count
  name                = format("roxie-port-%02d", count.index + 1)
  network_id          = data.openstack_networking_network_v2.network.id
  admin_state_up      = "true"
  security_group_ids  = ["${openstack_networking_secgroup_v2.secgroup.id}"]

  fixed_ip {
    subnet_id  = data.openstack_networking_subnet_v2.subnet.id
    ip_address = cidrhost(data.openstack_networking_subnet_v2.subnet.cidr, 7 + "${var.esp.count}" + count.index)

  }
}
resource "openstack_networking_port_v2" "thor_port" {
  count              = var.thor.count
  name               = format("thor-port-%02d", count.index + 1)
  network_id         = data.openstack_networking_network_v2.network.id
  admin_state_up     = "true"
  security_group_ids = ["${openstack_networking_secgroup_v2.secgroup.id}"]

  fixed_ip {
    subnet_id  = data.openstack_networking_subnet_v2.subnet.id
    ip_address = cidrhost(data.openstack_networking_subnet_v2.subnet.cidr, 7 + "${var.esp.count}" + "${var.roxie.count}" + count.index)

  }
}
resource "openstack_networking_port_v2" "support_port" {
  count              = var.support.count
  name               = format("support_port-%02d", count.index + 1)
  network_id         = data.openstack_networking_network_v2.network.id
  admin_state_up     = "true"
  security_group_ids = ["${openstack_networking_secgroup_v2.secgroup.id}"]

  fixed_ip {
    subnet_id  = data.openstack_networking_subnet_v2.subnet.id
    ip_address = cidrhost(data.openstack_networking_subnet_v2.subnet.cidr, 7 + "${var.esp.count}" + "${var.roxie.count}" + "${var.thor.count}" + count.index)

  }
}

# Create DNS
## Create DNS Zone
resource "openstack_dns_zone_v2" "hpcc_zone" {
  count = var.dns.enabled == true ? 1 : 0
  name  = var.dns.zone_name
  ttl   = var.dns.zone_ttl
  type  = var.dns.zone_type
  email = var.dns.email
}

## Create DNS Record Set
resource "openstack_dns_recordset_v2" "hpcc_record_set" {
  count   = length(openstack_dns_zone_v2.hpcc_zone)
  zone_id = openstack_dns_zone_v2.hpcc_zone.*.id[count.index]
  name    = var.dns.record_name
  ttl     = var.dns.record_ttl
  type    = var.dns.record_type
  records = ["${var.float_ip.address}"]
}

resource "openstack_compute_floatingip_associate_v2" "float_ip" {
  count       = var.float_ip.enabled == true ? 1 : 0
  floating_ip = var.float_ip.address
  instance_id = element(openstack_compute_instance_v2.esp.*.id, count.index)
}

# Create volumes
## Be very careful of your changes
## Changing some arguments below will result in clean new volumes
#----------------------------------------------------------------

resource "openstack_blockstorage_volume_v2" "esp_vol" {
  count       = var.esp.count
  name        = "esp-${count.index + 1}-vol"
  description = "ECLWatch dedicated volume"
  size        = var.esp.disk
  image_id    = var.system_config.image_id
  lifecycle {
    prevent_destroy = false
  }
}
resource "openstack_blockstorage_volume_v2" "dali_vol" {
  name        = "dali_vol"
  description = "Dali dedicated volume"
  size        = var.dali.disk
  image_id    = var.system_config.image_id
  lifecycle {
    prevent_destroy = false
  }
}
resource "openstack_blockstorage_volume_v2" "dropzone_vol" {
  name        = "dropzone_vol"
  description = "Landing Zone dedicated volume"
  size        = var.dropzone.disk
  image_id    = var.system_config.image_id
  lifecycle {
    prevent_destroy = false
  }
}
resource "openstack_blockstorage_volume_v2" "thor_vol" {
  count       = var.thor.count
  name        = "thor-${count.index + 1}-vol"
  description = "thors dedicated volumes"
  size        = var.thor.disk
  image_id    = var.system_config.image_id
  lifecycle {
    prevent_destroy = false
  }
}
resource "openstack_blockstorage_volume_v2" "support_vol" {
  count       = var.support.count
  name        = "support-${count.index + 1}-vol"
  description = "supports dedicated volumes"
  size        = var.support.disk
  image_id    = var.system_config.image_id
  lifecycle {
    prevent_destroy = false
  }
}
resource "openstack_blockstorage_volume_v2" "roxie_vol" {
  count       = var.roxie.count
  name        = "roxie-${count.index + 1}-vol"
  description = "roxie dedicated volume"
  size        = var.roxie.disk
  image_id    = var.system_config.image_id
  lifecycle {
    prevent_destroy = false
  }
}

# Compute roxie  
#----------------------------------------------------------------

resource "openstack_compute_instance_v2" "roxie" {
  count             = var.roxie.count
  name              = "roxie-${count.index + 1}"
  image_name        = var.system_config.image_name
  image_id          = var.system_config.image_id
  flavor_name       = var.roxie.flavor_name
  key_pair          = var.system_config.pub_key_name
  availability_zone = element(openstack_blockstorage_volume_v2.roxie_vol.*.availability_zone, count.index)
  security_groups   = ["${openstack_networking_secgroup_v2.secgroup.name}"]
  network {
    port = openstack_networking_port_v2.roxie_port.*.id[count.index]
  }

  user_data = element(data.template_file.roxie_user_data.*.rendered, count.index)
}
## Compute thor 
#----------------------------------------------------------------

resource "openstack_compute_instance_v2" "thor" {
  count             = var.thor.count
  name              = "thor-${count.index + 1}"
  image_name        = var.system_config.image_name
  image_id          = var.system_config.image_id
  flavor_name       = var.thor.flavor_name
  key_pair          = var.system_config.pub_key_name
  availability_zone = element(openstack_blockstorage_volume_v2.thor_vol.*.availability_zone, count.index)
  security_groups   = ["${openstack_networking_secgroup_v2.secgroup.name}"]
  network {
    port = openstack_networking_port_v2.thor_port.*.id[count.index]
  }

  user_data = element(data.template_file.thor_user_data.*.rendered, count.index)
}
## Compute Dali node  
#----------------------------------------------------------------

resource "openstack_compute_instance_v2" "dali" {
  name              = "dali"
  image_name        = var.system_config.image_name
  image_id          = var.system_config.image_id
  flavor_name       = var.dali.flavor_name
  key_pair          = var.system_config.pub_key_name
  availability_zone = openstack_blockstorage_volume_v2.dali_vol.availability_zone
  security_groups   = ["${openstack_networking_secgroup_v2.secgroup.name}"]
  network {
    port = openstack_networking_port_v2.dali_port.id
  }

  user_data = data.template_file.dali_user_data.rendered
}

## Compute ESP  
#----------------------------------------------------------------

resource "openstack_compute_instance_v2" "esp" {
  count             = var.esp.count
  name              = "esp-${count.index + 1}"
  image_name        = var.system_config.image_name
  image_id          = var.system_config.image_id
  flavor_name       = var.esp.flavor_name
  key_pair          = var.system_config.pub_key_name
  availability_zone = element(openstack_blockstorage_volume_v2.esp_vol.*.availability_zone, count.index)
  security_groups   = ["${openstack_networking_secgroup_v2.secgroup.name}"]
  network {
    port = openstack_networking_port_v2.esp_port.*.id[count.index]
  }

  user_data = element(data.template_file.esp_user_data.*.rendered, count.index)
}

## Compute Landing Zone 
#----------------------------------------------------------------

resource "openstack_compute_instance_v2" "dropzone" {
  name              = "dropzone"
  image_name        = var.system_config.image_name
  image_id          = var.system_config.image_id
  flavor_name       = var.dropzone.flavor_name
  key_pair          = var.system_config.pub_key_name
  availability_zone = openstack_blockstorage_volume_v2.dropzone_vol.availability_zone
  security_groups   = ["${openstack_networking_secgroup_v2.secgroup.name}"]
  network {
    port = openstack_networking_port_v2.dropzone_port.id
  }

  user_data = data.template_file.dropzone_user_data.rendered
}

## Compute support nodes 
#----------------------------------------------------------------

resource "openstack_compute_instance_v2" "support" {
  count             = var.support.count
  name              = "support-${count.index + 1}"
  image_name        = var.system_config.image_name
  image_id          = var.system_config.image_id
  flavor_name       = var.support.flavor_name
  key_pair          = var.system_config.pub_key_name
  availability_zone = element(openstack_blockstorage_volume_v2.support_vol.*.availability_zone, count.index)
  security_groups   = ["${openstack_networking_secgroup_v2.secgroup.name}"]
  network {
    port = openstack_networking_port_v2.support_port.*.id[count.index]
  }

  user_data = element(data.template_file.support_user_data.*.rendered, count.index)
}

# Attach Volumes
#----------------------------------------------------------------

resource "openstack_compute_volume_attach_v2" "esp_attach" {
  count       = var.esp.count
  instance_id = element(openstack_compute_instance_v2.esp.*.id, count.index)
  volume_id   = element(openstack_blockstorage_volume_v2.esp_vol.*.id, count.index)
}
resource "openstack_compute_volume_attach_v2" "dali_attach" {
  instance_id = openstack_compute_instance_v2.dali.id
  volume_id   = openstack_blockstorage_volume_v2.dali_vol.id
}
resource "openstack_compute_volume_attach_v2" "dropzone_attach" {
  instance_id = openstack_compute_instance_v2.dropzone.id
  volume_id   = openstack_blockstorage_volume_v2.dropzone_vol.id
}
resource "openstack_compute_volume_attach_v2" "thor_attach" {
  count       = var.thor.count
  instance_id = element(openstack_compute_instance_v2.thor.*.id, count.index)
  volume_id   = element(openstack_blockstorage_volume_v2.thor_vol.*.id, count.index)
}
resource "openstack_compute_volume_attach_v2" "roxie_attach" {
  count       = var.roxie.count
  instance_id = element(openstack_compute_instance_v2.roxie.*.id, count.index)
  volume_id   = element(openstack_blockstorage_volume_v2.roxie_vol.*.id, count.index)
}
resource "openstack_compute_volume_attach_v2" "support_attach" {
  count       = var.support.count
  instance_id = element(openstack_compute_instance_v2.support.*.id, count.index)
  volume_id   = element(openstack_blockstorage_volume_v2.support_vol.*.id, count.index)
}



