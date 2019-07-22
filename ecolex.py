#!/usr/bin/env python3

from pathlib import Path
from configparser import ConfigParser
from jinja2 import Environment, FileSystemLoader
import requests

path = Path(__file__).parent.resolve()
config = ConfigParser()
config.optionxform = str
config.read(path / 'ecolex.ini')
jinja_env = Environment(
    variable_start_string="${",
    variable_end_string="}",
    loader=FileSystemLoader(str(path / 'templates')),
)
nomad = config.get('cluster', 'nomad')


class Options:
    env = dict(config['env'])
    volumes = config.get('ecolex', 'volumes')
    fixtures = path / 'fixtures'


def render(filename, **kwargs):
    return jinja_env.get_template(filename).render(**kwargs)


def deploy():
    hcl = render('ecolex.nomad', options=Options())
    spec = requests.post(f'{nomad}/v1/jobs/parse', json={
        'JobHCL': hcl,
        'Canonicalize': True,
    }).json()
    result = requests.post(f'{nomad}/v1/jobs', json={'job': spec}).json()
    print(result)


if __name__ == '__main__':
    import sys
    assert sys.argv[1:] == ['deploy']
    deploy()
