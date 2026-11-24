# Ежедневные снимки загрузочных дисков всех ВМ, каждый хранится неделю.
resource "yandex_compute_snapshot_schedule" "daily" {
  name             = "diploma-daily"
  description      = "Ежедневный снимок всех дисков стенда, хранение 7 дней"
  retention_period = "168h0m0s" # 7 суток; формат как в API, иначе вечный дрейф в plan

  schedule_policy {
    # 03:00 МСК
    expression = "0 0 * * *"
  }

  snapshot_spec {
    description = "diploma daily snapshot"
    labels = {
      project = "netology-diploma"
    }
  }

  disk_ids = [for vm in yandex_compute_instance.vm : vm.boot_disk[0].disk_id]
}
