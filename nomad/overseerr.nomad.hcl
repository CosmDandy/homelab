job "overseerr" {
  datacenters = ["homelab"]
  type = "service"

  group "overseerr" {
    count = 1

    network {
      mode = "host"
      port "http" {
        static = 5055
      }
    }

    # volume "overseerr_config" {
    #   type   = "host"
    #   source = "overseerr_config"
    # }

    task "overseerr" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/overseerr:latest"
        network_mode = "host"
      }

      # volume_mount {
      #   volume      = "overseerr_config"
      #   destination = "/app/config"
      # }

      service {
        name = "overseerr"
        port = "http"

        check {
          type = "http"
          path = "/"
          interval = "10s"
          timeout = "2s"
        }
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}


