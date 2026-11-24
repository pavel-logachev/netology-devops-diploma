variable "ssh_user" {
  description = "Пользователь, которого cloud-init создаёт на всех ВМ"
  type        = string
  default     = "diploma"
}

variable "ssh_public_key_path" {
  description = "Публичный ключ для входа на ВМ"
  type        = string
  default     = "../.secrets/id_ed25519.pub"
}

variable "preemptible" {
  description = "Прерываемые ВМ дешевле; для учебного стенда этого достаточно"
  type        = bool
  default     = true
}

variable "subnets" {
  description = "Подсети VPC: публичные для bastion, Grafana, Kibana и балансировщика, приватные для остальных"
  type = map(object({
    zone    = string
    cidr    = string
    private = bool
  }))
  default = {
    public-a  = { zone = "ru-central1-a", cidr = "10.20.1.0/24", private = false }
    public-d  = { zone = "ru-central1-d", cidr = "10.20.2.0/24", private = false }
    private-a = { zone = "ru-central1-a", cidr = "10.20.11.0/24", private = true }
    private-d = { zone = "ru-central1-d", cidr = "10.20.12.0/24", private = true }
  }
}

variable "vms" {
  description = "Параметры ВМ стенда. Адреса фиксированы, чтобы конфигурации Ansible не зависели от порядка создания"
  type = map(object({
    subnet        = string
    ip            = string
    public        = bool
    cores         = number
    memory        = number
    core_fraction = number
    disk_size     = number
    groups        = list(string)
  }))
  default = {
    bastion    = { subnet = "public-a", ip = "10.20.1.10", public = true, cores = 2, memory = 1, core_fraction = 20, disk_size = 10, groups = ["bastion"] }
    web-a      = { subnet = "private-a", ip = "10.20.11.11", public = false, cores = 2, memory = 1, core_fraction = 20, disk_size = 10, groups = ["web"] }
    web-b      = { subnet = "private-d", ip = "10.20.12.11", public = false, cores = 2, memory = 1, core_fraction = 20, disk_size = 10, groups = ["web"] }
    prometheus = { subnet = "private-d", ip = "10.20.12.20", public = false, cores = 2, memory = 2, core_fraction = 20, disk_size = 15, groups = ["prometheus"] }
    elastic    = { subnet = "private-d", ip = "10.20.12.30", public = false, cores = 2, memory = 4, core_fraction = 50, disk_size = 20, groups = ["elastic"] }
    grafana    = { subnet = "public-a", ip = "10.20.1.20", public = true, cores = 2, memory = 2, core_fraction = 20, disk_size = 10, groups = ["grafana"] }
    kibana     = { subnet = "public-a", ip = "10.20.1.30", public = true, cores = 2, memory = 4, core_fraction = 50, disk_size = 10, groups = ["kibana"] }
  }
}
