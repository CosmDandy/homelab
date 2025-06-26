job "paperless" {
  datacenters = ["homelab"]
  type        = "service"
  
  group "paperless-stack" {
    count = 1
    
    network {
      mode = "host"
      port "http" {
        static = 8000
      }
      port "redis" {
        static = 6379
      }
      port "postgres" {
        static = 5432
      }
      port "gotenberg" {
        static = 3000
      }
      port "tika" {
        static = 9998
      }
    }
    
    # Redis broker
    task "redis" {
      driver = "docker"
      
      config {
        image = "redis:8"
        network_mode = "host"
      }
      
      service {
        name = "paperless-redis"
        port = "redis"
        
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
      
      resources {
        cpu    = 200
        memory = 256
      }
    }
    
    # PostgreSQL database
    task "postgres" {
      driver = "docker"
      
      config {
        image = "postgres:17"
        network_mode = "host"
      }
      
      template {
        destination = "secrets/postgres.env"
        env         = true
        data = <<EOH
POSTGRES_DB=paperless
POSTGRES_USER=paperless
POSTGRES_PASSWORD={{ keyOrDefault "paperless/postgres_password" "paperless" }}
EOH
      }
      
      service {
        name = "paperless-postgres"
        port = "postgres"
        
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
      
      resources {
        cpu    = 500
        memory = 512
      }
    }
    
    # Gotenberg service
    task "gotenberg" {
      driver = "docker"
      
      config {
        image = "gotenberg/gotenberg:8.20"
        network_mode = "host"
        args = [
          "gotenberg",
          "--chromium-disable-javascript=true",
          "--chromium-allow-list=file:///tmp/.*"
        ]
      }
      
      service {
        name = "paperless-gotenberg"
        port = "gotenberg"
        
        check {
          type     = "http"
          path     = "/health"
          interval = "30s"
          timeout  = "5s"
        }
      }
      
      resources {
        cpu    = 300
        memory = 512
      }
    }
    
    # Tika service  
    task "tika" {
      driver = "docker"
      
      config {
        image = "apache/tika:latest"
        network_mode = "host"
      }
      
      service {
        name = "paperless-tika"
        port = "tika"
        
        check {
          type     = "http"
          path     = "/tika"
          interval = "30s"
          timeout  = "5s"
        }
      }
      
      resources {
        cpu    = 300
        memory = 512
      }
    }
    
    # Paperless webserver
    task "webserver" {
      driver = "docker"
      
      config {
        image = "ghcr.io/paperless-ngx/paperless-ngx:latest"
        network_mode = "host"
      }
      
      template {
        destination = "secrets/paperless.env"
        env         = true
        data = <<EOH
PAPERLESS_REDIS=redis://localhost:6379
PAPERLESS_DBHOST=localhost
PAPERLESS_TIKA_ENABLED=1
PAPERLESS_TIKA_GOTENBERG_ENDPOINT=http://localhost:3000
PAPERLESS_TIKA_ENDPOINT=http://localhost:9998
EOH
      }
      
      service {
        name = "paperless"
        port = "http"
        
        tags = [
          "web",
          "paperless",
        ]
        
        check {
          type     = "http"
          path     = "/api/"
          interval = "30s"
          timeout  = "5s"
        }
      }
      
      resources {
        cpu    = 2000
        memory = 1024
      }
    }
  }
}
