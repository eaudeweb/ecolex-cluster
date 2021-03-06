job "ecolex" {
  datacenters = ["dc1"]
  type = "service"

  group "web" {
    task "web" {
      driver = "docker"
      config {
        image = "${options.images['ecolex-web']}"
        entrypoint = ["/local/entrypoint.sh"]
        args = ["run"]
        volumes = [
          "${options.volumes}/www_ecolex_static:/www_static",
          "${options.volumes}/web_logs:/home/web/ecolex/logs",
        ]
        port_map {
          http = 8000
        }
        labels {
          ecolex = "web"
        }
      }
      template {
        data = <<-EOF
        #!/bin/bash -ex
        cd /home/web/ecolex
        ./manage.py collectstatic --noinput
        exec /home/web/bin/docker-entrypoint.sh "$@"
        EOF
        destination = "local/entrypoint.sh"
        perms = "755"
      }
      template {
        data = <<-EOF
        TZ = "${options.env.TZ}"
        EDW_RUN_WEB_DEBUG = "${options.env.EDW_RUN_WEB_DEBUG}"
        MYSQL_DATABASE = "${options.env.MYSQL_DATABASE}"
        MYSQL_USER = "${options.env.MYSQL_USER}"
        MYSQL_PASSWORD = "${options.env.MYSQL_PASSWORD}"
        EDW_RUN_WEB_ECOLEX_CODE = "${options.env.EDW_RUN_WEB_ECOLEX_CODE}"
        EDW_RUN_WEB_FAOLEX_API_KEY = "${options.env.EDW_RUN_WEB_FAOLEX_API_KEY}"
        EDW_RUN_WEB_FAOLEX_CODE = "${options.env.EDW_RUN_WEB_FAOLEX_CODE}"
        EDW_RUN_WEB_FAOLEX_CODE_2 = "${options.env.EDW_RUN_WEB_FAOLEX_CODE_2}"
        EDW_RUN_WEB_FAOLEX_ENABLED = "${options.env.EDW_RUN_WEB_FAOLEX_ENABLED}"
        EDW_RUN_WEB_INFORMEA_CODE = "${options.env.EDW_RUN_WEB_INFORMEA_CODE}"
        EDW_RUN_WEB_PORT = "${options.env.EDW_RUN_WEB_PORT}"
        EDW_RUN_WEB_SECRET_KEY = "${options.env.EDW_RUN_WEB_SECRET_KEY}"
        EDW_RUN_WEB_SENTRY_DSN = "${options.env.EDW_RUN_WEB_SENTRY_DSN}"
        EDW_RUN_WEB_SENTRY_PUBLIC_DSN = "${options.env.EDW_RUN_WEB_SENTRY_PUBLIC_DSN}"
        EDW_RUN_WEB_STATIC_ROOT = "${options.env.EDW_RUN_WEB_STATIC_ROOT}"
        {{- range service "ecolex-solr" }}
        EDW_RUN_SOLR_URI = "http://{{.Address}}:{{.Port}}/solr/ecolex"
        {{- end }}
        {{- range service "ecolex-mariadb" }}
        MYSQL_HOST = "{{.Address}}"
        MYSQL_PORT = "{{.Port}}"
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

  group "lb" {
    task "nginx" {
      driver = "docker"
      config = {
        image = "nginx:1.17"
        port_map {
          nginx = 80
        }
        volumes = [
          "local/nginx.conf:/etc/nginx/conf.d/default.conf:ro",
          "${options.volumes}/www_ecolex_static:/www_static",
        ]
        labels {
          ecolex = "nginx"
        }
      }
      template {
        data = <<EOF
          server {
            listen 80 default_server;

            {{- with service "ecolex-web" }}
              {{- with index . 0 }}
                location /static {
                  alias /www_static;
                }
                location / {
                  proxy_pass http://{{ .Address }}:{{ .Port }};
                }
              {{- end }}
            {{- end }}
          }
          server_names_hash_bucket_size 128;
          EOF
        destination = "local/nginx.conf"
      }
      resources {
        memory = 100
        network {
          mbits = 10
          port "nginx" {
            static = 8000
          }
        }
      }
      service {
        name = "ecolex-nginx"
        port = "nginx"
      }
    }
  }

  group "mariadb" {
    task "mariadb" {
      driver = "docker"
      config {
        image = "${options.images['ecolex-mariadb']}"
        args = ["bash", "/local/startup.sh"]
        volumes = [
          "${options.volumes}/mariadb:/var/lib/mysql",
        ]
        port_map {
          mariadb = 3306
        }
        labels {
          ecolex = "mariadb"
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
        destination = "local/mariadb.env"
        env = true
      }
      resources {
        cpu = 100
        memory = 250
        network {
          mbits = 10
          port "mariadb" {}
        }
      }
      service {
        name = "ecolex-mariadb"
        port = "mariadb"
      }
    }
  }

  group "solr" {
    task "solr" {
      driver = "docker"
      config {
        image = "${options.images['ecolex-solr']}"
        entrypoint = ["/local/entrypoint.sh"]
        volumes = [
          "${options.fixtures}/solr/solr_scripts/:/docker-entrypoint-initdb.d/",
          "${options.volumes}/solr/mycores:/opt/solr/server/solr/mycores",
          "${options.fixtures}/solr/ecolex_initial_conf:/core-template/ecolex_initial_conf:ro",
        ]
        port_map {
          solr = 8983
        }
        labels {
          ecolex = "solr"
        }
      }
      template {
        data = <<-EOF
        #!/bin/sh
        set -ex
        exec docker-entrypoint.sh solr-precreate ecolex /core-template/ecolex_initial_conf
        EOF
        destination = "local/entrypoint.sh"
        perms = "755"
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
        memory = 4000
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
