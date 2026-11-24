locals {
  ip = { for name, vm in var.vms : name => "${vm.ip}/32" }
}

# Bastion: снаружи открыт только SSH (вход только по ключу).
resource "yandex_vpc_security_group" "bastion" {
  name       = "diploma-bastion"
  network_id = yandex_vpc_network.diploma.id

  ingress {
    protocol       = "TCP"
    description    = "SSH из интернета, только по ключу"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Исходящий трафик"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Общая группа для всех ВМ, кроме bastion: SSH только из группы bastion.
resource "yandex_vpc_security_group" "internal" {
  name       = "diploma-internal"
  network_id = yandex_vpc_network.diploma.id

  ingress {
    protocol          = "TCP"
    description       = "SSH только с bastion"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
  }

  egress {
    protocol       = "ANY"
    description    = "Исходящий трафик (пакеты через NAT, связи между сервисами)"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "alb" {
  name       = "diploma-alb"
  network_id = yandex_vpc_network.diploma.id

  ingress {
    protocol       = "TCP"
    description    = "HTTP к сайту"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol          = "TCP"
    description       = "Проверки состояния узлов балансировщика"
    port              = 30080
    predefined_target = "loadbalancer_healthchecks"
  }

  egress {
    protocol       = "ANY"
    description    = "К веб-серверам"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "web" {
  name       = "diploma-web"
  network_id = yandex_vpc_network.diploma.id

  ingress {
    protocol          = "TCP"
    description       = "HTTP от балансировщика"
    port              = 80
    security_group_id = yandex_vpc_security_group.alb.id
  }

  ingress {
    protocol          = "TCP"
    description       = "HTTP-проверки балансировщика"
    port              = 80
    predefined_target = "loadbalancer_healthchecks"
  }

  ingress {
    protocol       = "TCP"
    description    = "Node Exporter для Prometheus"
    port           = 9100
    v4_cidr_blocks = [local.ip["prometheus"]]
  }

  ingress {
    protocol       = "TCP"
    description    = "Nginx Log Exporter для Prometheus"
    port           = 4040
    v4_cidr_blocks = [local.ip["prometheus"]]
  }
}

resource "yandex_vpc_security_group" "prometheus" {
  name       = "diploma-prometheus"
  network_id = yandex_vpc_network.diploma.id

  ingress {
    protocol       = "TCP"
    description    = "API Prometheus для Grafana"
    port           = 9090
    v4_cidr_blocks = [local.ip["grafana"]]
  }
}

resource "yandex_vpc_security_group" "grafana" {
  name       = "diploma-grafana"
  network_id = yandex_vpc_network.diploma.id

  ingress {
    protocol       = "TCP"
    description    = "Веб-интерфейс Grafana"
    port           = 3000
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "elastic" {
  name       = "diploma-elastic"
  network_id = yandex_vpc_network.diploma.id

  ingress {
    protocol       = "TCP"
    description    = "Elasticsearch API для Filebeat и Kibana"
    port           = 9200
    v4_cidr_blocks = [local.ip["web-a"], local.ip["web-b"], local.ip["kibana"]]
  }
}

resource "yandex_vpc_security_group" "kibana" {
  name       = "diploma-kibana"
  network_id = yandex_vpc_network.diploma.id

  ingress {
    protocol       = "TCP"
    description    = "Веб-интерфейс Kibana (вход по паролю)"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  vm_security_groups = {
    bastion    = [yandex_vpc_security_group.bastion.id]
    web-a      = [yandex_vpc_security_group.internal.id, yandex_vpc_security_group.web.id]
    web-b      = [yandex_vpc_security_group.internal.id, yandex_vpc_security_group.web.id]
    prometheus = [yandex_vpc_security_group.internal.id, yandex_vpc_security_group.prometheus.id]
    elastic    = [yandex_vpc_security_group.internal.id, yandex_vpc_security_group.elastic.id]
    grafana    = [yandex_vpc_security_group.internal.id, yandex_vpc_security_group.grafana.id]
    kibana     = [yandex_vpc_security_group.internal.id, yandex_vpc_security_group.kibana.id]
  }
}
