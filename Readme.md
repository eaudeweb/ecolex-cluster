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
docker exec -it $(docker ps -qf label=cluster_task=ecolex-web) bash
```

Initial setup:
```
./manage.py collectstatic
./manage.py loaddata ecolex/fixtures/initial_data.json
```
