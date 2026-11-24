data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2404-lts"
}

locals {
  cloud_init = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    ssh_user       = var.ssh_user
    ssh_public_key = trimspace(file(var.ssh_public_key_path))
  })
}

resource "yandex_compute_instance" "vm" {
  for_each = var.vms

  name                      = each.key
  hostname                  = each.key
  zone                      = var.subnets[each.value.subnet].zone
  platform_id               = "standard-v3"
  allow_stopping_for_update = true

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = each.value.core_fraction
  }

  scheduling_policy {
    preemptible = var.preemptible
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-hdd"
      size     = each.value.disk_size
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.this[each.value.subnet].id
    ip_address         = each.value.ip
    nat                = each.value.public
    security_group_ids = local.vm_security_groups[each.key]
  }

  metadata = {
    user-data = local.cloud_init
  }
}
