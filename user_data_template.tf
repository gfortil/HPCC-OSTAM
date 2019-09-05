data "template_file" "master_user_data" {
    template   = "${file("${path.module}/provisioner.sh")}"
    vars       = {
        hpcc_package            = "${upper(var.hpcc_package)}"
        hpcc_version            = "${var.hpcc_version}"
        hpcc_release            = "${var.hpcc_release}"
        device                  = "${dirname(var.device)}"
        mountpoint              = "${dirname(var.mountpoint)}"
        build_server            = "${var.build_server}"
        mydropzone_folder_names = "${replace(join(", ", compact(var.mydropzone_folder_names)),",","")}"
        timezone                = "${var.timezone}"
        ip                      = "${openstack_networking_port_v2.master_port.all_fixed_ips.0}"
    }
}

data "template_file" "dali_user_data" {
    template    = "${file("${path.module}/provisioner.sh")}"
    vars        = {
        hpcc_package            = "${upper(var.hpcc_package)}"
        hpcc_version            = "${var.hpcc_version}"
        hpcc_release            = "${var.hpcc_release}"
        device                  = "${dirname(var.device)}"
        mountpoint              = "${dirname(var.mountpoint)}"
        build_server            = "${var.build_server}"
        mydropzone_folder_names = "${replace(join(", ", compact(var.mydropzone_folder_names)),",","")}"
        timezone                = "${var.timezone}"
        ip                      = "${openstack_networking_port_v2.dali_port.all_fixed_ips.0}"
    }
}

data "template_file" "esp_user_data" {
    template    = "${file("${path.module}/provisioner.sh")}"
    vars = {
        hpcc_package            = "${upper(var.hpcc_package)}"
        hpcc_version            = "${var.hpcc_version}"
        hpcc_release            = "${var.hpcc_release}"
        device                  = "${dirname(var.device)}"
        mountpoint              = "${dirname(var.mountpoint)}"
        build_server            = "${var.build_server}"
        mydropzone_folder_names = "${replace(join(", ", compact(var.mydropzone_folder_names)),",","")}"
        timezone                = "${var.timezone}"
        ip                      = "${openstack_networking_port_v2.esp_port.all_fixed_ips.0}"
    }
}

data "template_file" "lzone_user_data" {
    template    = "${file("${path.module}/provisioner.sh")}"
    vars        = {
        hpcc_package            = "${upper(var.hpcc_package)}"
        hpcc_version            = "${var.hpcc_version}"
        hpcc_release            = "${var.hpcc_release}"
        device                  = "${dirname(var.device)}"
        mountpoint              = "${dirname(var.mountpoint)}"
        build_server            = "${var.build_server}"
        mydropzone_folder_names = "${replace(join(", ", compact(var.mydropzone_folder_names)),",","")}"
        timezone                = "${var.timezone}"
        ip                      = "${openstack_networking_port_v2.lzone_port.all_fixed_ips.0}"
    }
}

data "template_file" "slave_user_data" {
    count       = "${var.slave_count}"
    template    = "${file("${path.module}/provisioner.sh")}"
    vars = {
        hpcc_package            = "${upper(var.hpcc_package)}"
        hpcc_version            = "${var.hpcc_version}"
        hpcc_release            = "${var.hpcc_release}"
        device                  = "${dirname(var.device)}"
        mountpoint              = "${dirname(var.mountpoint)}"
        build_server            = "${var.build_server}"
        mydropzone_folder_names = "${replace(join(", ", compact(var.mydropzone_folder_names)),",","")}"
        timezone                = "${var.timezone}"
        ip                      = "${element(openstack_networking_port_v2.slave_port.*.all_fixed_ips.0, count.index)}"
    }
}

data "template_file" "backup_user_data" {
    count       = "${var.backup_count}"
    template    = "${file("${path.module}/provisioner.sh")}"
    vars = {
        hpcc_package            = "${upper(var.hpcc_package)}"
        hpcc_version            = "${var.hpcc_version}"
        hpcc_release            = "${var.hpcc_release}"
        device                  = "${dirname(var.device)}"
        mountpoint              = "${dirname(var.mountpoint)}"
        build_server            = "${var.build_server}"
        mydropzone_folder_names = "${replace(join(", ", compact(var.mydropzone_folder_names)),",","")}"
        timezone                = "${var.timezone}"
        ip                      = "${element(openstack_networking_port_v2.backup_port.*.all_fixed_ips.0, count.index)}"
    }
}

