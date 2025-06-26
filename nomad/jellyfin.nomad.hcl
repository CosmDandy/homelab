job "jellyfin" {
  datacenters = ["homelab"]
  type = "service"
  
  group "jellyfin" {
    count = 1

    network {
      mode = "host"
      port "http" {
        static = 8096
      }
    }

    service {
      name = "jellyfin"
      provider = "nomad"
      port = "http"

      check {
        name = "alive"
        type = "http"
        path = "/"
        interval = "10s"
        timeout = "2s"
      }
    }

    task "jellyfin" {
      driver = "docker"
      
      config {
        image = "jellyfin/jellyfin:latest"
        network_mode = "host"
        volumes = [
          "../data/jellyfin/config:/config",
          "../data/jellyfin/cache:/media"
        ]
      }

      resources {
        cpu    = 4000
        memory = 1024
      }
      
      # vault {
      #   policies = ["jellyfin"]
      # }
    }
  }
}
