#!/usr/bin/env python3

from pathlib import Path
from configparser import ConfigParser
from jinja2 import Environment, FileSystemLoader
import requests

path = Path(__file__).parent.resolve()

def read_config(config_path):
    config = ConfigParser()
    config.optionxform = str
    config.read(config_path)
    return config

versions = read_config(path / 'versions.ini')
config = read_config(path / 'ecolex.ini')
nomad = config.get('cluster', 'nomad')

jinja = Environment(
    variable_start_string='${',
    variable_end_string='}',
    loader=FileSystemLoader(str(path / 'templates')),
)


def render(filename, **kwargs):
    return jinja.get_template(filename).render(**kwargs)


class Options:
    images = dict(versions['docker-images'], **config['docker-images'])
    env = dict(config['env'])
    volumes = config.get('ecolex', 'volumes')
    fixtures = path / 'fixtures'


def deploy():
    hcl = render('ecolex.nomad', options=Options())
    spec = requests.post(f'{nomad}/v1/jobs/parse', json={'JobHCL': hcl}).json()
    result = requests.post(f'{nomad}/v1/jobs', json={'job': spec}).json()
    print(result)


if __name__ == '__main__':
    import sys
    assert sys.argv[1:] == ['deploy']
    deploy()
