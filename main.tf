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
  name               = "${var.project_name}_dali_port"
  network_id         = data.openstack_networking_network_v2.network.id
  admin_state_up     = "true"
  security_group_ids = ["${openstack_networking_secgroup_v2.secgroup.id}"]

  fixed_ip {
    subnet_id  = data.openstack_networking_subnet_v2.subnet.id
    ip_address = cidrhost(data.openstack_networking_subnet_v2.subnet.cidr, 10)

  }
}

resource "openstack_networking_port_v2" "dropzone_port" {
  name               = "${var.project_name}_dropzone_port"
  network_id         = data.openstack_networking_network_v2.network.id
  admin_state_up     = "true"
  security_group_ids = ["${openstack_networking_secgroup_v2.secgroup.id}"]

  fixed_ip {
    subnet_id  = data.openstack_networking_subnet_v2.subnet.id
    ip_address = cidrhost(data.openstack_networking_subnet_v2.subnet.cidr, 11)

  }
}

resource "openstack_networking_port_v2" "esp_port" {
  count               = var.esp.count
  name                = format("${var.project_name}_esp_port_%02d", count.index + 1)
  network_id          = data.openstack_networking_network_v2.network.id
  admin_state_up      = "true"
  security_group_ids  = ["${openstack_networking_secgroup_v2.secgroup.id}"]

  fixed_ip {
    subnet_id  = data.openstack_networking_subnet_v2.subnet.id
    ip_address = cidrhost(data.openstack_networking_subnet_v2.subnet.cidr, 12 + count.index)

  }
}

resource "openstack_networking_port_v2" "roxie_port" {
  count               = var.roxie.count
  name                = format("${var.project_name}_roxie_port_%02d", count.index + 1)
  network_id          = data.openstack_networking_network_v2.network.id
  admin_state_up      = "true"
  security_group_ids  = ["${openstack_networking_secgroup_v2.secgroup.id}"]

  fixed_ip {
    subnet_id  = data.openstack_networking_subnet_v2.subnet.id
    ip_address = cidrhost(data.openstack_networking_subnet_v2.subnet.cidr, 12 + "${var.esp.count}" + count.index)

  }
}
resource "openstack_networking_port_v2" "thor_port" {
  count              = var.thor.count
  name               = format("${var.project_name}_thor_port_%02d", count.index + 1)
  network_id         = data.openstack_networking_network_v2.network.id
  admin_state_up     = "true"
  security_group_ids = ["${openstack_networking_secgroup_v2.secgroup.id}"]

  fixed_ip {
    subnet_id  = data.openstack_networking_subnet_v2.subnet.id
    ip_address = cidrhost(data.openstack_networking_subnet_v2.subnet.cidr, 12 + "${var.esp.count}" + "${var.roxie.count}" + count.index)

  }
}
resource "openstack_networking_port_v2" "generic_port" {
  count              = var.generic.count
  name               = format("${var.project_name}_generic_port_%02d", count.index + 1)
  network_id         = data.openstack_networking_network_v2.network.id
  admin_state_up     = "true"
  security_group_ids = ["${openstack_networking_secgroup_v2.secgroup.id}"]

  fixed_ip {
    subnet_id  = data.openstack_networking_subnet_v2.subnet.id
    ip_address = cidrhost(data.openstack_networking_subnet_v2.subnet.cidr, 12 + "${var.esp.count}" + "${var.roxie.count}" + "${var.thor.count}" + count.index)

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

# Associate floating IP
resource "openstack_compute_floatingip_associate_v2" "float_ip" {
  count       = var.float_ip.enabled == true ? 1 : 0
  floating_ip = var.float_ip.address
  # instance_id = openstack_lb_loadbalancer_v2.lb_1.*.id[count.index]
  instance_id = element(openstack_compute_instance_v2.esp.*.id, count.index)
}

# # Create Load Balancer
# resource "openstack_lb_loadbalancer_v2" "lb_1" {
#   count         = var.esp.count > 1 ? 1 : 0
#   name          = "${var.project_name}_lb"
#   vip_subnet_id = data.openstack_networking_subnet_v2.subnet.id
#   vip_address   = cidrhost(data.openstack_networking_subnet_v2.subnet.cidr, 9)
# }

# # LB Listener
# resource "openstack_lb_listener_v2" "listener_1" {
#   count           = var.esp.count > 1 ? 1 : 0
#   protocol        = "HTTP"
#   protocol_port   = 8010
#   loadbalancer_id = openstack_lb_loadbalancer_v2.lb_1.*.id[count.index]
# }

# # LB Pool 
# resource "openstack_lb_pool_v2" "pool_1" {
#   count           = var.esp.count > 1 ? 1 : 0
#   name            = "${var.project_name}_pool_1"
#   protocol        = "HTTP"
#   lb_method       = "ROUND_ROBIN"
#   loadbalancer_id = openstack_lb_loadbalancer_v2.lb_1.*.id[count.index]
#   listener_id     = openstack_lb_listener_v2.listener_1.*.id[count.index]
# }

# # LB Monitoring 
# resource "openstack_lb_monitor_v2" "monitor_1" {
#   count       = var.esp.count > 1 ? var.esp.count : 0
#   pool_id     = openstack_lb_pool_v2.pool_1.*.id[0]
#   type        = "TCP"
#   delay       = 5
#   timeout     = 5
#   max_retries = 3
# }

# # LB Members 
# resource "openstack_lb_member_v2" "member_1" {
#   count         = var.esp.count
#   pool_id       = openstack_lb_pool_v2.pool_1.*.id[0]
#   address       = cidrhost(data.openstack_networking_subnet_v2.subnet.cidr, 12 + count.index)
#   protocol_port = 8010
#   subnet_id     = data.openstack_networking_subnet_v2.subnet.id
# }

# Create volumes
## Be very careful of your changes
## Changing some arguments below will result in clean new volumes
#----------------------------------------------------------------

resource "openstack_blockstorage_volume_v2" "esp_vol" {
  count       = var.esp.count
  name        = "${var.project_name}_esp_${count.index + 1}_vol"
  description = "ECLWatch node dedicated volume"
  size        = var.esp.disk
  image_id    = var.system_config.image_id
  lifecycle {
    prevent_destroy = false
  }
}
resource "openstack_blockstorage_volume_v2" "dali_vol" {
  name        = "${var.project_name}_dali_vol"
  description = "Dali node dedicated volume"
  size        = var.dali.disk
  image_id    = var.system_config.image_id
  lifecycle {
    prevent_destroy = false
  }
}
resource "openstack_blockstorage_volume_v2" "dropzone_vol" {
  name        = "${var.project_name}_dropzone_vol"
  description = "Landing Zone node dedicated volume"
  size        = var.dropzone.disk
  image_id    = var.system_config.image_id
  lifecycle {
    prevent_destroy = false
  }
}
resource "openstack_blockstorage_volume_v2" "thor_vol" {
  count       = var.thor.count
  name        = "${var.project_name}_thor_${count.index + 1}_vol"
  description = "thor node dedicated volumes"
  size        = var.thor.disk
  image_id    = var.system_config.image_id
  lifecycle {
    prevent_destroy = false
  }
}
resource "openstack_blockstorage_volume_v2" "generic_vol" {
  count       = var.generic.count
  name        = "${var.project_name}_generic_${count.index + 1}_vol"
  description = "generic node dedicated volume"
  size        = var.generic.disk
  image_id    = var.system_config.image_id
  lifecycle {
    prevent_destroy = false
  }
}
resource "openstack_blockstorage_volume_v2" "roxie_vol" {
  count       = var.roxie.count
  name        = "${var.project_name}_roxie_${count.index + 1}_vol"
  description = "roxie node dedicated volume"
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
  name              = "${var.project_name}_roxie_${count.index + 1}"
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
  name              = "${var.project_name}_thor_${count.index + 1}"
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
  name              = "${var.project_name}_dali"
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
  name              = "${var.project_name}_esp_${count.index + 1}"
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
  name              = "${var.project_name}_dropzone"
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

## Compute generic nodes 
#----------------------------------------------------------------

resource "openstack_compute_instance_v2" "generic" {
  count             = var.generic.count
  name              = "${var.project_name}_${count.index + 1}"
  image_name        = var.system_config.image_name
  image_id          = var.system_config.image_id
  flavor_name       = var.generic.flavor_name
  key_pair          = var.system_config.pub_key_name
  availability_zone = element(openstack_blockstorage_volume_v2.generic_vol.*.availability_zone, count.index)
  security_groups   = ["${openstack_networking_secgroup_v2.secgroup.name}"]
  network {
    port = openstack_networking_port_v2.generic_port.*.id[count.index]
  }

  user_data = element(data.template_file.generic_user_data.*.rendered, count.index)
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
resource "openstack_compute_volume_attach_v2" "generic_attach" {
  count       = var.generic.count
  instance_id = element(openstack_compute_instance_v2.generic.*.id, count.index)
  volume_id   = element(openstack_blockstorage_volume_v2.generic_vol.*.id, count.index)
}