job "homepage" {
  datacenters = ["homelab"]
  type = "service"

  group "homepage" {
    count = 1

    network {
      mode = "host"
      port "http" {
        static = 3000
      }
    }

    task "homepage" {
      driver = "docker"

      config {
        image = "ghcr.io/gethomepage/homepage:latest"
        network_mode = "host"
        volumes = [
          "local/config:/app/config"
        ]
      }

      service {
        name = "homepage"
        port = "http"

        check {
          type = "http"
          path = "/"
          interval = "10s"
          timeout = "2s"
        }
      }

      env {
        HOMEPAGE_ALLOWED_HOSTS = "homepage.cosmdandy.ru"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
