terraform {
  required_version = ">= 1.5.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.215.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# YC_TOKEN, YC_CLOUD_ID и YC_FOLDER_ID берутся из переменных окружения.
provider "yandex" {
  zone = "ru-central1-a"
}
