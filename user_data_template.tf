data "template_file" "dali_user_data" {
    template    = "${file("${path.module}/provisioner.sh")}"
    vars        = {
        project_name            = "${var.project_name}"
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

data "template_file" "dropzone_user_data" {
    template    = "${file("${path.module}/provisioner.sh")}"
    vars        = {
        project_name            = "${var.project_name}"
        edition                 = "${upper(var.hpcc_upgrade.edition)}"
        version                 = "${var.hpcc_upgrade.version}"
        release                 = "${var.hpcc_upgrade.release}"
        server                  = "${var.hpcc_upgrade.server}"
        device                  = "${var.system_config.device}"
        mountpoint              = "${var.system_config.mountpoint}"
        mydropzone_folder_names = "${replace(join(", ", compact(var.mydropzone_folder_names)),",","")}"
        timezone                = "${var.system_config.timezone}"
        ip                      = "${openstack_networking_port_v2.dropzone_port.all_fixed_ips.0}"
    }
}

data "template_file" "esp_user_data" {
    count                   = "${var.esp.count}"
    template    = "${file("${path.module}/provisioner.sh")}"
    vars = {
        project_name            = "${var.project_name}"
        edition                 = "${upper(var.hpcc_upgrade.edition)}"
        version                 = "${var.hpcc_upgrade.version}"
        release                 = "${var.hpcc_upgrade.release}"
        server                  = "${var.hpcc_upgrade.server}"
        device                  = "${var.system_config.device}"
        mountpoint              = "${var.system_config.mountpoint}"
        mydropzone_folder_names = "${replace(join(", ", compact(var.mydropzone_folder_names)),",","")}"
        timezone                = "${var.system_config.timezone}"
        ip                      = "${element(openstack_networking_port_v2.esp_port.*.all_fixed_ips.0, count.index)}"
    }
}

data "template_file" "roxie_user_data" {
    count       = "${var.roxie.count}"
    template   = "${file("${path.module}/provisioner.sh")}"
    vars       = {
        project_name            = "${var.project_name}"
        edition                 = "${upper(var.hpcc_upgrade.edition)}"
        version                 = "${var.hpcc_upgrade.version}"
        release                 = "${var.hpcc_upgrade.release}"
        server                  = "${var.hpcc_upgrade.server}"
        device                  = "${var.system_config.device}"
        mountpoint              = "${var.system_config.mountpoint}"
        mydropzone_folder_names = "${replace(join(", ", compact(var.mydropzone_folder_names)),",","")}"
        timezone                = "${var.system_config.timezone}"
        ip                      = "${element(openstack_networking_port_v2.roxie_port.*.all_fixed_ips.0, count.index)}"
    }
}

data "template_file" "thor_user_data" {
    count       = "${var.thor.count}"
    template    = "${file("${path.module}/provisioner.sh")}"
    vars = {
        project_name            = "${var.project_name}"
        edition                 = "${upper(var.hpcc_upgrade.edition)}"
        version                 = "${var.hpcc_upgrade.version}"
        release                 = "${var.hpcc_upgrade.release}"
        server                  = "${var.hpcc_upgrade.server}"
        device                  = "${var.system_config.device}"
        mountpoint              = "${var.system_config.mountpoint}"
        mydropzone_folder_names = "${replace(join(", ", compact(var.mydropzone_folder_names)),",","")}"
        timezone                = "${var.system_config.timezone}"
        ip                      = "${element(openstack_networking_port_v2.thor_port.*.all_fixed_ips.0, count.index)}"
    }
}

data "template_file" "generic_user_data" {
    count       = "${var.generic.count}"
    template    = "${file("${path.module}/provisioner.sh")}"
    vars = {
        project_name            = "${var.project_name}"
        edition                 = "${upper(var.hpcc_upgrade.edition)}"
        version                 = "${var.hpcc_upgrade.version}"
        release                 = "${var.hpcc_upgrade.release}"
        server                  = "${var.hpcc_upgrade.server}"
        device                  = "${var.system_config.device}"
        mountpoint              = "${var.system_config.mountpoint}"
        mydropzone_folder_names = "${replace(join(", ", compact(var.mydropzone_folder_names)),",","")}"
        timezone                = "${var.system_config.timezone}"
        ip                      = "${element(openstack_networking_port_v2.generic_port.*.all_fixed_ips.0, count.index)}"
    }
}

