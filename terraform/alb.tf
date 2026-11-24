resource "yandex_alb_target_group" "web" {
  name = "diploma-web-tg"

  dynamic "target" {
    for_each = ["web-a", "web-b"]
    content {
      subnet_id  = yandex_compute_instance.vm[target.value].network_interface[0].subnet_id
      ip_address = yandex_compute_instance.vm[target.value].network_interface[0].ip_address
    }
  }
}

resource "yandex_alb_backend_group" "web" {
  name = "diploma-web-bg"

  http_backend {
    name             = "web"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web.id]

    load_balancing_config {
      # 0 = режим паники выключен: при падении одного сервера трафик идет
      # только на здоровый. С порогом 90 при 1 из 2 здоровых ALB слал запросы
      # и на упавший сервер (получали 503, см. README).
      panic_threshold = 0
    }

    healthcheck {
      timeout             = "10s"
      interval            = "2s"
      healthy_threshold   = 2
      unhealthy_threshold = 3
      healthcheck_port    = 80

      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "web" {
  name = "diploma-web-router"
}

resource "yandex_alb_virtual_host" "web" {
  name           = "diploma-web-vhost"
  http_router_id = yandex_alb_http_router.web.id

  route {
    name = "root"

    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }

      http_route_action {
        backend_group_id = yandex_alb_backend_group.web.id
        timeout          = "60s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "web" {
  name               = "diploma-alb"
  network_id         = yandex_vpc_network.diploma.id
  security_group_ids = [yandex_vpc_security_group.alb.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.this["public-a"].id
    }

    location {
      zone_id   = "ru-central1-d"
      subnet_id = yandex_vpc_subnet.this["public-d"].id
    }
  }

  listener {
    name = "http"

    endpoint {
      address {
        # Публичный адрес выделяется автоматически.
        external_ipv4_address {}
      }
      ports = [80]
    }

    http {
      handler {
        http_router_id = yandex_alb_http_router.web.id
      }
    }
  }
}
