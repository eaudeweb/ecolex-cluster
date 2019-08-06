#!/usr/bin/env python3

from pathlib import Path
from configparser import ConfigParser
from jinja2 import Environment, FileSystemLoader
import requests
import click

path = Path(__file__).parent.resolve()


def read_config(config_path):
    config = ConfigParser()
    config.optionxform = str
    config.read(config_path)
    return config


versions = read_config(path / 'versions.ini')
config = read_config(path / 'ecolex.ini')
nomad = config.get('cluster', 'nomad')
vault_url = config.get('cluster', 'vault')
vault = requests.Session()
vault_config = read_config(path / config.get('cluster', 'vault_secrets'))
vault.headers['X-Vault-Token'] = vault_config.get('vault', 'root_token')

jinja = Environment(
    variable_start_string='${',
    variable_end_string='}',
    loader=FileSystemLoader(str(path / 'templates')),
)


def render(filename, **kwargs):
    return jinja.get_template(filename).render(**kwargs)


def get_images():
    rv = dict(versions['docker-images'])
    if 'docker-images' in config:
        rv.update(config['docker-images'])
    return rv


class Options:
    images = get_images()
    env = dict(config['env'])
    volumes = config.get('ecolex', 'volumes')
    fixtures = path / 'fixtures'


@click.group()
def cli():
    pass


def ensure_vault_engine():
    mounts = vault.get(f'{vault_url}/v1/sys/mounts').json()
    if 'ecolex/' not in mounts['data']:
        vault.post(f'{vault_url}/v1/sys/mounts/ecolex', json={'type': 'kv'})


def set_secret(name, value):
    return vault.put(f'{vault_url}/v1/ecolex/{name}', json={'value': value})


def get_secret(name):
    # TODO move secrets someplace else
    return Options.env.get(name, '')


@cli.command()
def deploy():
    ensure_vault_engine()
    set_secret('mysql-password', get_secret('MYSQL_PASSWORD'))
    set_secret('mysql-root-password', get_secret('MYSQL_ROOT_PASSWORD'))
    set_secret('web-secret-key', get_secret('EDW_RUN_WEB_SECRET_KEY'))
    set_secret('faolex-api-key', get_secret('EDW_RUN_WEB_FAOLEX_API_KEY'))
    set_secret('sentry-dsn', get_secret('EDW_RUN_WEB_SENTRY_DSN'))
    set_secret('sentry-public-dsn',
               get_secret('EDW_RUN_WEB_SENTRY_PUBLIC_DSN'))
    set_secret('ecolex-code', get_secret('EDW_RUN_WEB_ECOLEX_CODE'))
    set_secret('informea-code', get_secret('EDW_RUN_WEB_INFORMEA_CODE'))
    set_secret('faolex-code', get_secret('EDW_RUN_WEB_FAOLEX_CODE'))
    set_secret('faolex-code-2', get_secret('EDW_RUN_WEB_FAOLEX_CODE_2'))

    hcl = render('ecolex.nomad', options=Options())
    spec = requests.post(f'{nomad}/v1/jobs/parse', json={'JobHCL': hcl}).json()
    return requests.post(f'{nomad}/v1/jobs', json={'Job': spec}).json()


@cli.command()
def halt():
    return requests.delete(f'{nomad}/v1/job/ecolex').json()


if __name__ == '__main__':
    cli()
