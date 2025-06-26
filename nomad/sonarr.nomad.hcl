job "sonarr" {
  datacenters = ["homelab"]
  type = "service"

  group "sonarr" {
    count = 1

    network {
      mode = "host"
      port "http" {
        static = 8989
      }
    }

    # volume "sonarr_config" {
    #   type   = "host"
    #   source = "sonarr_config"
    # }

    task "sonarr" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/sonarr:latest"
        network_mode = "host"
      }

      # volume_mount {
      #   volume      = "sonarr_config"
      #   destination = "/app/config"
      # }

      service {
        name = "sonarr"
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


