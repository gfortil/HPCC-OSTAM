data "template_file" "master_user_data" {
    template   = "${file("${path.module}/provisioner.sh")}"
    vars       = {
        edition                 = "${upper(var.hpcc_upgrade.edition)}"
        version                 = "${var.hpcc_upgrade.version}"
        release                 = "${var.hpcc_upgrade.release}"
        server                  = "${var.hpcc_upgrade.server}"
        device                  = "${var.system_config.device}"
        mountpoint              = "${var.system_config.mountpoint}"
        mydropzone_folder_names = "${replace(join(", ", compact(var.mydropzone_folder_names)),",","")}"
        timezone                = "${var.system_config.timezone}"
        ip                      = "${openstack_networking_port_v2.master_port.all_fixed_ips.0}"
    }
}

data "template_file" "dali_user_data" {
    template    = "${file("${path.module}/provisioner.sh")}"
    vars        = {
        edition                 = "${upper(var.hpcc_upgrade.edition)}"
        version                 = "${var.hpcc_upgrade.version}"
        release                 = "${var.hpcc_upgrade.release}"
        server                  = "${var.hpcc_upgrade.server}"
        device                  = "${var.system_config.device}"
        mountpoint              = "${var.system_config.mountpoint}"
        mydropzone_folder_names = "${replace(join(", ", compact(var.mydropzone_folder_names)),",","")}"
        timezone                = "${var.system_config.timezone}"
        ip                      = "${openstack_networking_port_v2.dali_port.all_fixed_ips.0}"
    }
}

data "template_file" "esp_user_data" {
    template    = "${file("${path.module}/provisioner.sh")}"
    vars = {
        edition                 = "${upper(var.hpcc_upgrade.edition)}"
        version                 = "${var.hpcc_upgrade.version}"
        release                 = "${var.hpcc_upgrade.release}"
        server                  = "${var.hpcc_upgrade.server}"
        device                  = "${var.system_config.device}"
        mountpoint              = "${var.system_config.mountpoint}"
        mydropzone_folder_names = "${replace(join(", ", compact(var.mydropzone_folder_names)),",","")}"
        timezone                = "${var.system_config.timezone}"
        ip                      = "${openstack_networking_port_v2.esp_port.all_fixed_ips.0}"
    }
}

data "template_file" "landingzone_user_data" {
    template    = "${file("${path.module}/provisioner.sh")}"
    vars        = {
        edition                 = "${upper(var.hpcc_upgrade.edition)}"
        version                 = "${var.hpcc_upgrade.version}"
        release                 = "${var.hpcc_upgrade.release}"
        server                  = "${var.hpcc_upgrade.server}"
        device                  = "${var.system_config.device}"
        mountpoint              = "${var.system_config.mountpoint}"
        mydropzone_folder_names = "${replace(join(", ", compact(var.mydropzone_folder_names)),",","")}"
        timezone                = "${var.system_config.timezone}"
        ip                      = "${openstack_networking_port_v2.landingzone_port.all_fixed_ips.0}"
    }
}

data "template_file" "slave_user_data" {
    count       = "${var.slave.count}"
    template    = "${file("${path.module}/provisioner.sh")}"
    vars = {
        edition                 = "${upper(var.hpcc_upgrade.edition)}"
        version                 = "${var.hpcc_upgrade.version}"
        release                 = "${var.hpcc_upgrade.release}"
        server                  = "${var.hpcc_upgrade.server}"
        device                  = "${var.system_config.device}"
        mountpoint              = "${var.system_config.mountpoint}"
        mydropzone_folder_names = "${replace(join(", ", compact(var.mydropzone_folder_names)),",","")}"
        timezone                = "${var.system_config.timezone}"
        ip                      = "${element(openstack_networking_port_v2.slave_port.*.all_fixed_ips.0, count.index)}"
    }
}

data "template_file" "support_user_data" {
    count       = "${var.support.count}"
    template    = "${file("${path.module}/provisioner.sh")}"
    vars = {
        edition                 = "${upper(var.hpcc_upgrade.edition)}"
        version                 = "${var.hpcc_upgrade.version}"
        release                 = "${var.hpcc_upgrade.release}"
        server                  = "${var.hpcc_upgrade.server}"
        device                  = "${var.system_config.device}"
        mountpoint              = "${var.system_config.mountpoint}"
        mydropzone_folder_names = "${replace(join(", ", compact(var.mydropzone_folder_names)),",","")}"
        timezone                = "${var.system_config.timezone}"
        ip                      = "${element(openstack_networking_port_v2.support_port.*.all_fixed_ips.0, count.index)}"
    }
}

