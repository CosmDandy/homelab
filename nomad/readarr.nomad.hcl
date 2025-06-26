job "readarr" {
  datacenters = ["homelab"]
  type = "service"

  group "readarr" {
    count = 1

    network {
      mode = "host"
      port "http" {
        static = 8787
      }
    }

    # volume "readarr_config" {
    #   type   = "host"
    #   source = "readarr_config"
    # }

    task "readarr" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/readarr:develop"
        network_mode = "host"
      }

      # volume_mount {
      #   volume      = "readarr_config"
      #   destination = "/app/config"
      # }

      service {
        name = "readarr"
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


