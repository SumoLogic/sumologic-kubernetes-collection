#!/usr/bin/env python3

import argparse
from yaml import load, dump, Loader
import http.client
from http import HTTPStatus

REPO='SumoLogic/sumologic-kubernetes-collection'
HOST='github.com'
RAW_HOST='raw.githubusercontent.com'
FILE='deploy/helm/sumologic/values.yaml'
AGENT='Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/118.0'

def main():
  parser = argparse.ArgumentParser(
  prog='SKC values diff',
  description='Return customer overrides over default values.yaml')

  parser.add_argument('filename')         # positional argument
  parser.add_argument('-v', '--version')  # on/off flag

  args = parser.parse_args()
  default_values = load(get_values(args.version), Loader)
  with open(args.filename) as f:
    values = load(f.read(), Loader)
  
  print(dump(remove_duplicates(values, default_values)))


def remove_duplicates(obj1, obj2):
  if type(obj1) != type(obj2):
    return obj1

  if isinstance(obj1, dict):
    to_remove = []
    for key, value in obj1.items():
      if obj2.get(key) == value:
        to_remove.append(key)
        continue

      obj1[key] = remove_duplicates(value, obj2.get(key))

      if obj1[key] == {}:
        to_remove.append(key)

    for key in to_remove:
      del obj1[key]
  elif isinstance(obj1, list):
    to_remove = []
    for key, value in enumerate(obj1):
      if key < len(obj2) and obj2[key] == value:
        to_remove.append(key)
        continue

      if key < len(obj2):
        obj1[key] = remove_duplicates(value, obj2[key])
  
    to_remove.reverse()
    for key in to_remove:
      del obj1[key]

  return obj1


def get_values(version: str):
  if version is None:
    conn = http.client.HTTPSConnection(HOST)
    conn.request('GET', f'/{REPO}/releases/latest', headers={'Host': HOST, 'User-Agent': AGENT})
    response = conn.getresponse()
    if response.status != HTTPStatus.FOUND:
      raise Exception(f'Unexpected response status {response.status}')
    version = response.headers['Location'].removeprefix(f'https://{HOST}/{REPO}/releases/tag/')
  
  conn = http.client.HTTPSConnection(RAW_HOST)
  conn.request('GET', f'/{REPO}/{version}/{FILE}', headers={'Host': RAW_HOST, 'User-Agent': AGENT})
  response = conn.getresponse()
  if response.status != HTTPStatus.OK:
    raise Exception(f'Unexpected response status {response.status}')
  
  return response.read()


if __name__ == '__main__':
  main()
