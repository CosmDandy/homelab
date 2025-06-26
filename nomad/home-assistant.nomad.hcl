job "homeassistant" {
  datacenters = ["homelab"]
  type = "service"

  group "homeassistant" {
    count = 1

    network {
      mode = "host"
      port "http" {
        static = 8123
      }
    }

    # volume "homeassistant_config" {
    #   type   = "host"
    #   source = "homeassistant_config"
    # }

    task "homeassistant" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/homeassistant:latest"
        network_mode = "host"
      }

      # volume_mount {
      #   volume      = "homeassistant_config"
      #   destination = "/app/config"
      # }

      service {
        name = "homeassistant"
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


