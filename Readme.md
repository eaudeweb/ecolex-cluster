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
