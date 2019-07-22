#!/bin/bash -ex

# Export volumes from running database containers

cd "$( dirname "${BASH_SOURCE[0]}" )"

docker run --rm --volumes-from ecx_solr -v $(pwd):/export debian tar cvf /export/solr.tar /opt/solr/server/solr/mycores
docker run --rm --volumes-from ecx_maria -v $(pwd):/export debian tar cvf /export/maria.tar /var/lib/mysql
