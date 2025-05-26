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
        memory = 2048
      }
      
      # vault {
      #   policies = ["jellyfin"]
      # }
    }
  }
}
