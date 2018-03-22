#!/usr/bin/env python3

from flask import Flask, request, jsonify
from inspect import signature
from datetime import datetime
import json

class CustomEncoder(json.JSONEncoder):
  def default(self, o):
    if isinstance(o, datetime):
      return {'__datetime__': o.replace(microsecond=0).isoformat()}
    return {'__{}__'.format(o.__class__.__name__): o.__dict__}

app = Flask(__name__)
app.json_encoder = CustomEncoder

def route(func):
  func_name = func.__name__
  num_parameters = len(signature(func).parameters)
  def new_func():
    print(request)
    data = request.get_json(force=True, silent=True)
    if data == None:
      if request.args != None:
        data = request.args.get('args')
        if data != None:
          try:
            data = json.loads(data)
          except:
            return jsonify({'error': 'args object is not JSON', 'method': func_name, 'args': data})
    if data == None:
      data = []
    print('data is')
    print(data)
    if len(data) != num_parameters:
      return jsonify({'error': 'wrong number of parameters', 'method': func_name, 'expected_parameters': num_parameters, 'received_parameters': len(data)})
    return jsonify(func(*data))
  new_func.__name__ = func.__name__
  return app.route('/' + func_name, methods=['POST', 'GET'])(new_func)

import scipy.stats

@route
def ttest_rel(a, b):
  return scipy.stats.ttest_rel(a, b)

@route
def mannwhitneyu(a, b):
  return scipy.stats.mannwhitneyu(a, b)

@route
def wilcoxon(a, b):
  return scipy.stats.wilcoxon(a, b)

@route
def linregress(x):
  return scipy.stats.linregress(x)

app.run(port=9999)
