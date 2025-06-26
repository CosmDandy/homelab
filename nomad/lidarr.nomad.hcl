job "lidarr" {
  datacenters = ["homelab"]
  type = "service"

  group "lidarr" {
    count = 1

    network {
      mode = "host"
      port "http" {
        static = 8686
      }
    }

    # volume "lidarr_config" {
    #   type   = "host"
    #   source = "lidarr_config"
    # }

    task "lidarr" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/lidarr:latest"
        network_mode = "host"
      }

      # volume_mount {
      #   volume      = "lidarr_config"
      #   destination = "/app/config"
      # }

      service {
        name = "lidarr"
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


