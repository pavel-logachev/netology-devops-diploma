locals {
  bastion_ip = yandex_compute_instance.vm["bastion"].network_interface[0].nat_ip_address
  alb_ip     = yandex_alb_load_balancer.web.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

output "site_url" {
  value = "http://${local.alb_ip}/"
}

output "grafana_url" {
  value = "http://${yandex_compute_instance.vm["grafana"].network_interface[0].nat_ip_address}:3000/"
}

output "kibana_url" {
  value = "http://${yandex_compute_instance.vm["kibana"].network_interface[0].nat_ip_address}:5601/"
}

output "bastion_ssh" {
  value = "ssh -i .secrets/id_ed25519 ${var.ssh_user}@${local.bastion_ip}"
}

resource "local_file" "inventory" {
  filename        = abspath("${path.module}/../ansible/inventory.yml")
  file_permission = "0644"
  content = templatefile("${path.module}/inventory.yml.tftpl", {
    ssh_user   = var.ssh_user
    bastion_ip = local.bastion_ip
    vms        = var.vms
  })
}
