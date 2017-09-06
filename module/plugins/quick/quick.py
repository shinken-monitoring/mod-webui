#!/usr/bin/python

# -*- coding: utf-8 -*-

import time
import re
import json

from shinken.log import logger

app = None

def _host_to_dict(host):
    _dict = dict()

    __all__ = [x for x in dir(host) if re.match("[a-z][a-z0-9_]+$", x, re.IGNORECASE)]
    
    for attr in __all__:
        try:
            var = getattr(host,attr)
            if isinstance( var, ( int, long, str)):
                _dict[attr] = var
        except:
            pass
            
    _dict['customs'] = getattr(host,'customs',[])
            
    return _dict
    
def _service_to_dict(host):
    _dict = dict()

    __all__ = [x for x in dir(host) if re.match("[a-z][a-z0-9_]+$", x, re.IGNORECASE)]
    
    for attr in __all__:
        try:
            var = getattr(host,attr)
            if isinstance( var, ( int, long, str)):
                _dict[attr] = var
        except:
            pass
            
    return _dict
    

def quick(host_name):
    user = app.bottle.request.environ['USER']
    host = app.datamgr.get_host(host_name, user)
    return json.dumps(_host_to_dict(host))
    
    
def quick_services(host_name):
    user = app.bottle.request.environ['USER']
    host = app.datamgr.get_host(host_name, user)
    
    services = [ _service_to_dict(x) for x in host.get_services() ]

    return json.dumps(services)

pages = {
    quick: {
        'name': 'quick', 'route': '/quick/:host_name', 'view': None, 'static': False
    },
    quick_services: {
        'name': 'quick', 'route': '/quick/:host_name/services', 'view': None, 'static': False
    }
}

