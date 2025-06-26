job "prowlarr" {
  datacenters = ["homelab"]
  type = "service"

  group "prowlarr" {
    count = 1

    network {
      mode = "host"
      port "http" {
        static = 9696
      }
    }

    # volume "prowlarr_config" {
    #   type   = "host"
    #   source = "prowlarr_config"
    # }

    task "prowlarr" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/prowlarr:latest"
        network_mode = "host"
      }

      # volume_mount {
      #   volume      = "prowlarr_config"
      #   destination = "/app/config"
      # }

      service {
        name = "prowlarr"
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


