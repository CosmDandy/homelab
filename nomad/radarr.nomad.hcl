job "radarr" {
  datacenters = ["homelab"]
  type = "service"

  group "radarr" {
    count = 1

    network {
      mode = "host"
      port "http" {
        static = 7878
      }
    }

    # volume "radarr_config" {
    #   type   = "host"
    #   source = "radarr_config"
    # }

    task "radarr" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/radarr:latest"
        network_mode = "host"
      }

      # volume_mount {
      #   volume      = "radarr_config"
      #   destination = "/app/config"
      # }

      service {
        name = "radarr"
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


