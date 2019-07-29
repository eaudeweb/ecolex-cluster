#!/usr/bin/env bash


echo "Setting SOLR_HEAP to ${EDW_RUN_SOLR_HEAP_MB:-'4096m'}  in /opt/solr/bin/solr.in.sh"
sed -i -e"s/^SOLR_HEAP=.*\$/SOLR_HEAP=\"${EDW_RUN_SOLR_HEAP_MB:-'4096m'}\"/" /opt/solr/bin/solr.in.sh

echo "Setting log4j.appender.file.MaxFileSize to ${EDW_RUN_SOLR_LOG_MB:-'200MB'}"
sed -i -e"s/^log4j.appender.file.MaxFileSize=.*/log4j.appender.file.MaxFileSize=${EDW_RUN_SOLR_LOG_MB:-'200MB'}/" /opt/solr/server/resources/log4j.properties

