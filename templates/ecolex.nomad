job "ecolex" {
  datacenters = ["dc1"]
  type = "service"

  group "app" {
    task "web" {
      driver = "docker"
      config {
        image = "iucn/ecolex_web:20190226"
        volumes = [
          "${options.volumes}/www_ecolex_static:/www_static",
          "${options.volumes}/web_logs:/home/web/ecolex/logs",
        ]
        port_map {
          http = 8000
        }
      }
      template {
        data = <<-EOF
          TZ = ${options.env.TZ}
          MYSQL_DATABASE = ${options.env.MYSQL_DATABASE}
          MYSQL_USER = ${options.env.MYSQL_USER}
          MYSQL_PASSWORD = ${options.env.MYSQL_PASSWORD}
          EDW_RUN_SOLR_URI = ${options.env.EDW_RUN_SOLR_URI}
          EDW_RUN_WEB_ECOLEX_CODE = ${options.env.EDW_RUN_WEB_ECOLEX_CODE}
          EDW_RUN_WEB_FAOLEX_API_KEY = ${options.env.EDW_RUN_WEB_FAOLEX_API_KEY}
          EDW_RUN_WEB_FAOLEX_CODE = ${options.env.EDW_RUN_WEB_FAOLEX_CODE}
          EDW_RUN_WEB_FAOLEX_CODE_2 = ${options.env.EDW_RUN_WEB_FAOLEX_CODE_2}
          EDW_RUN_WEB_FAOLEX_ENABLED = ${options.env.EDW_RUN_WEB_FAOLEX_ENABLED}
          EDW_RUN_WEB_INFORMEA_CODE = ${options.env.EDW_RUN_WEB_INFORMEA_CODE}
          EDW_RUN_WEB_PORT = ${options.env.EDW_RUN_WEB_PORT}
          EDW_RUN_WEB_SECRET_KEY = ${options.env.EDW_RUN_WEB_SECRET_KEY}
          EDW_RUN_WEB_SENTRY_DSN = ${options.env.EDW_RUN_WEB_SENTRY_DSN}
          EDW_RUN_WEB_SENTRY_PUBLIC_DSN = ${options.env.EDW_RUN_WEB_SENTRY_PUBLIC_DSN}
          EDW_RUN_WEB_STATIC_ROOT = ${options.env.EDW_RUN_WEB_STATIC_ROOT}
          {{- range service "ecolex-solr" }}
          SOLR_URL = "http://{{.Address}}:{{.Port}}"
          {{- end }}
          {{- range service "ecolex-maria" }}
          MARIA_HOST = {{.Address}}
          MARIA_PORT = {{.Port}}
          {{- end }}
        EOF
        destination = "local/docker.env"
        env = true
      }
      resources {
        memory = 500
        network {
          mbits = 10
          port "http" {}
        }
      }
      service {
        name = "ecolex-web"
        port = "http"
      }
    }
  }

  group "maria" {
    task "maria" {
      driver = "docker"
      config {
        image = "mariadb:10"
        args = ["bash", "/local/startup.sh"]
        volumes = [
          "${options.volumes}/maria:/var/lib/mysql",
        ]
        port_map {
          maria = 3306
        }
      }
      template {
        data = <<-EOF
        #!/bin/sh
        set -ex
        args=(
          --character-set-server="utf8mb4"
          --collation-server="utf8mb4_unicode_ci"
          --query-cache-size="${options.env.EDW_RUN_MARIA_query_cache_size}"
          --max-allowed-packet="${options.env.EDW_RUN_MARIA_max_allowed_packet}"
          --max-connections="${options.env.EDW_RUN_MARIA_max_connections}"
          --max-heap-table-size="${options.env.EDW_RUN_MARIA_max_heap_table_size}"
          --tmp_table_size="${options.env.EDW_RUN_MARIA_tmp_table_size}"
          --query_cache_limit="${options.env.EDW_RUN_MARIA_query_cache_limit}"
          --innodb-buffer-pool-size="${options.env.EDW_RUN_MARIA_innodb_buffer_pool_size}"
          --slow-query-log="${options.env.EDW_RUN_MARIA_slow_query_log}"
          --innodb-log-file-size="300M"
        )
        exec ./docker-entrypoint.sh "${'$'}{args[@]}"
        EOF
        destination = "local/startup.sh"
      }
      template {
        data = <<-EOF
        MYSQL_DATABASE = "${options.env.MYSQL_DATABASE}"
        MYSQL_USER = "${options.env.MYSQL_USER}"
        MYSQL_PASSWORD = "${options.env.MYSQL_PASSWORD}"
        MYSQL_ROOT_PASSWORD = "${options.env.MYSQL_PASSWORD}"
        EOF
        destination = "local/maria.env"
        env = true
      }
      resources {
        cpu = 100
        memory = 250
        network {
          mbits = 10
          port "maria" {}
        }
      }
      service {
        name = "nextcloud-maria"
        port = "maria"
      }
    }
  }

  group "solr" {
    task "solr" {
      driver = "docker"
      config {
        image = "solr:5.5 "
        args = [
          "docker-entrypoint.sh",
          "solr-precreate",
          "ecolex",
          "/core-template/ecolex_initial_conf",
        ]
        volumes = [
          "${options.fixtures}/solr/solr_scripts/:/docker-entrypoint-initdb.d/",
          "${options.volumes}/solr:/opt/solr/server/solr/mycores",
          "${options.fixtures}/solr/ecolex_initial_conf:/core-template/ecolex_initial_conf:ro",
        ]
        port_map {
          solr = 8983
        }
      }
      template {
        data = <<-EOF
        TZ = ${options.env.TZ}
        EDW_RUN_SOLR_HEAP_MB = ${options.env.EDW_RUN_SOLR_HEAP_MB}
        EDW_RUN_SOLR_LOG_MB = ${options.env.EDW_RUN_SOLR_LOG_MB}
        EOF
        destination = "local/solr.env"
        env = true
      }
      resources {
        cpu = 100
        memory = 250
        network {
          mbits = 10
          port "solr" {}
        }
      }
      service {
        name = "ecolex-solr"
        port = "solr"
      }
    }
  }

}
