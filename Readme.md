[![Build Status](https://jenkins.liquiddemo.org/api/badges/eaudeweb/ecolex-cluster/status.svg)](https://jenkins.liquiddemo.org/eaudeweb/ecolex-cluster)

## Deployment
Copy the example config file and customize it:
```shell
cp examples/ecolex.ini ./
```

Deploy to the cluster:
```shell
pipenv install
pipenv run ./ecolex.py deploy
```

To run commands in the ecolex-web docker container:
```shell
docker exec -it "$(docker ps -qf label=ecolex=web)" bash
```

Initial setup:
```
./manage.py collectstatic
./manage.py loaddata ecolex/fixtures/initial_data.json
```
