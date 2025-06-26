job "atuin" {
  datacenters = ["homelab"]
  type = "service"
  
  group "atuin-stack" {
    count = 1
    
    network {
      mode = "bridge"
      port "atuin" {
        static = 8888
        to = 8888
      }
      port "postgres" {
        to = 5432
      }
    }
    
    # Volume для конфигурации Atuin
    volume "atuin-config" {
      type   = "host"
      source = "atuin-config"
    }
    
    # Volume для данных PostgreSQL
    volume "postgres-data" {
      type   = "host"
      source = "postgres-data"
    }
    
    # PostgreSQL Task
    task "postgresql" {
      driver = "docker"
      
      volume_mount {
        volume      = "postgres-data"
        destination = "/var/lib/postgresql/data"
      }
      
      config {
        image = "postgres:14"
        ports = ["postgres"]
      }
      
      env {
        POSTGRES_USER     = "${ATUIN_DB_USERNAME}"
        POSTGRES_PASSWORD = "${ATUIN_DB_PASSWORD}"
        POSTGRES_DB       = "${ATUIN_DB_NAME}"
      }
      
      resources {
        cpu    = 500
        memory = 512
      }
      
      service {
        name = "atuin-postgres"
        port = "postgres"
        
        check {
          type     = "tcp"
          interval = "30s"
          timeout  = "5s"
        }
      }
    }
    
    # Atuin Task
    task "atuin" {
      driver = "docker"
      
      volume_mount {
        volume      = "atuin-config"
        destination = "/config"
      }
      
      config {
        image = "ghcr.io/atuinsh/atuin:f8145e6"
        command = "server"
        args = ["start"]
        ports = ["atuin"]
      }
      
      env {
        ATUIN_HOST            = "0.0.0.0"
        ATUIN_OPEN_REGISTRATION = "false"
        ATUIN_DB_URI          = "postgres://${ATUIN_DB_USERNAME}:${ATUIN_DB_PASSWORD}@${NOMAD_ADDR_postgresql_postgres}/${ATUIN_DB_NAME}"
        RUST_LOG              = "info,atuin_server=debug"
      }
      
      resources {
        cpu    = 500
        memory = 256
      }
      
      service {
        name = "atuin"
        port = "atuin"
        
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.atuin.rule=Host(`atuin.cosmdandy.ru`)",
          "traefik.http.routers.atuin.entrypoints=websecure",
          "traefik.http.routers.atuin.tls.certresolver=myresolver",
          "traefik.http.routers.atuin.service=atuin",
          "traefik.http.services.atuin.loadbalancer.server.port=8888"
        ]
        
        check {
          type     = "http"
          path     = "/"
          interval = "30s"
          timeout  = "5s"
        }
      }
    }
  }
}
