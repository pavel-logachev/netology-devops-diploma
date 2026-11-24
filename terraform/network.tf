resource "yandex_vpc_network" "diploma" {
  name        = "diploma-net"
  description = "Единственная VPC курсовой работы"
}

# NAT нужен приватным ВМ только для установки пакетов.
resource "yandex_vpc_gateway" "nat" {
  name = "diploma-nat"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private" {
  name       = "diploma-private-rt"
  network_id = yandex_vpc_network.diploma.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}

resource "yandex_vpc_subnet" "this" {
  for_each = var.subnets

  name           = "diploma-${each.key}"
  zone           = each.value.zone
  network_id     = yandex_vpc_network.diploma.id
  v4_cidr_blocks = [each.value.cidr]
  route_table_id = each.value.private ? yandex_vpc_route_table.private.id : null
}
