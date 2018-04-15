#!/usr/bin/env python3

from flask import Flask, request, jsonify
from inspect import signature
from datetime import datetime
import json
from functools import wraps

import lifelines.statistics

class CustomEncoder(json.JSONEncoder):
  def default(self, o):
    if isinstance(o, datetime):
      return {'__datetime__': o.replace(microsecond=0).isoformat()}
    return {'__{}__'.format(o.__class__.__name__): o.__dict__}

app = Flask(__name__)
app.json_encoder = CustomEncoder

def support_jsonp(f):
  """Wraps JSONified output for JSONP"""
  @wraps(f)
  def decorated_function(*args, **kwargs):
    callback = request.args.get('callback', False)
    if callback:
      content = str(callback) + '(' + f(*args,**kwargs).data.decode('utf-8') + ')'
      return app.response_class(content, mimetype='application/javascript')
    else:
      return f(*args, **kwargs)
  return decorated_function

def route(func):
  func_name = func.__name__
  num_parameters = len(signature(func).parameters)
  @wraps(func)
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
  return app.route('/' + func_name, methods=['POST', 'GET'])(support_jsonp(new_func))

import scipy.stats

@route
def ttest_rel(a, b):
  return scipy.stats.ttest_rel(a, b)

@route
def ttest_ind(a, b):
  return scipy.stats.ttest_ind(a, b)

@route
def mannwhitneyu(a, b):
  return scipy.stats.mannwhitneyu(a, b)

@route
def wilcoxon(a, b):
  return scipy.stats.wilcoxon(a, b)

@route
def linregress(x):
  return scipy.stats.linregress(x)

@route
def fisher_exact(a, b):
  # where a=[3,8] is comparing ratios 3:8 to b=[1,7] 1:7
  return scipy.stats.fisher_exact([a, b])

@route
def logrank_test(a, b):
  # a={"lifetimes": [], "attritions": []}
  # b={"lifetimes": [], "attritions": []}
  return lifelines.statistics.logrank_test(a['lifetimes'], b['lifetimes'], event_observed_A=a['attritions'], event_observed_B=b['attritions'])

app.run(port=9999)
