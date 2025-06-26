datacenter = "homelab"
data_dir = "/var/lib/nomad"

server {
  enabled = true
  bootstrap_expect = 1
}

client {
  enabled = true
  servers = ["127.0.0.1:4647"]
  
  options {
    "driver.raw_exec.enable" = "1"
  }

  # Определите host volumes
  host_volume "jellyfin-config" {
    path      = "/opt/jellyfin/config"
    read_only = false
  }
  
  host_volume "jellyfin-media" {
    path      = "/opt/jellyfin/media"
    read_only = false
  }

  host_volume "homepage_config" {
    path      = "/home/cosmdandy/homelab/configs/services/homepage"
    read_only = false
  }
}

consul {
  address = "127.0.0.1:8500"
}

vault {
  enabled = true
  address = "http://127.0.0.1:8200"
}

ui {
  enabled = true
}
