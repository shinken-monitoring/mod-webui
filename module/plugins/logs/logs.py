#!/usr/bin/python

# -*- coding: utf-8 -*-

# Copyright (C) 2009-2014:
#    Gabes Jean, naparuba@gmail.com
#    Gerhard Lausser, Gerhard.Lausser@consol.de
#    Gregory Starck, g.starck@gmail.com
#    Hartmut Goebel, h.goebel@goebel-consult.de
#    Frederic Mohier, frederic.mohier@gmail.com
#
# This file is part of Shinken.
#
# Shinken is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Shinken is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Shinken.  If not, see <http://www.gnu.org/licenses/>.

import time
import re

from shinken.log import logger

# Mongodb lib
try:
    import pymongo
    from pymongo.connection import Connection
    import gridfs
except ImportError:
    Connection = None


### Will be populated by the UI with it's own value
app = None

# Get plugin's parameters from configuration file
params = {}
params['mongo_host'] = "localhost"
params['mongo_port'] = 27017
params['database'] = "shinken"
params['collection'] = "Logs"
params['max_records'] = 500
params['logs_type'] = ['INFO', 'WARNING', 'ERROR']
params['logs_hosts'] = []
params['logs_services'] = []

def load_config(app):
    global params
    
    import os
    from webui.config_parser import config_parser
    try:
        currentdir = os.path.dirname(os.path.realpath(__file__))
        configuration_file = "%s/%s" % (currentdir, 'plugin.cfg')
        logger.info("[WebUI-logs] Plugin configuration file: %s", configuration_file)
        scp = config_parser('#', '=')
        z = params.copy()
        z.update(scp.parse_config(configuration_file))
        params = z

        # Integers ...
        params['mongo_port'] = int(params['mongo_port'])
        params['max_records'] = int(params['max_records'])
        params['logs_type'] = [item.strip() for item in params['logs_type'].split(',')]
        if len(params['logs_hosts']) > 0:
            params['logs_hosts'] = [item.strip() for item in params['logs_hosts'].split(',')]
        if len(params['logs_services']) > 0:
            params['logs_services'] = [item.strip() for item in params['logs_services'].split(',')]
        
        logger.info("[WebUI-logs] configuration loaded.")
        logger.info("[WebUI-logs] configuration, database: %s (%s) - %s, %s", params['mongo_host'], params['mongo_port'], params['database'], params['collection'])
        logger.info("[WebUI-logs] configuration, fetching limit: %d", params['max_records'])
        logger.info("[WebUI-logs] configuration, fetching types: %s", params['logs_type'])
        logger.info("[WebUI-logs] configuration, hosts: %s", params['logs_hosts'])
        logger.info("[WebUI-logs] configuration, services: %s", params['logs_services'])
        return True
    except Exception, exp:
        logger.warning("[WebUI-logs] configuration file (%s) not available: %s", configuration_file, str(exp))
        return False


def show_logs():
    # If exists an external module ...
    if app.logs_module.is_available():
        records = app.logs_module.get_ui_logs(name=None, logs_type = params['logs_type'])
        return {'records': records, 'params': params, 'message': "%d records fetched from database." % len(records)}
            
    logger.warning("[WebUI-logs] no get history external module defined!")
    return {'records': None, 'params': params, 'message': "No module configured to get Shinken logs from a database!"}
    

def form_hosts_list():
    return {'params': params}

def set_hosts_list():
    # Form cancel
    if app.request.forms.get('cancel'): 
        app.bottle.redirect("/logs")

    params['logs_hosts'] = []
    
    hostsList = app.request.forms.getall('hostsList[]')
    logger.debug("[WebUI-logs] Selected hosts : ")
    for host in hostsList:
        logger.debug("[WebUI-logs] - host : %s" % (host))
        params['logs_hosts'].append(host)

    app.bottle.redirect("/logs")
    return

def form_services_list():
    return {'params': params}

def set_services_list():
    # Form cancel
    if app.request.forms.get('cancel'): 
        app.bottle.redirect("/logs")

    params['logs_services'] = []
    
    servicesList = app.request.forms.getall('servicesList[]')
    logger.debug("[WebUI-logs] Selected services : ")
    for service in servicesList:
        logger.debug("[WebUI-logs] - service : %s" % (service))
        params['logs_services'].append(service)

    app.bottle.redirect("/logs")
    return

def form_logs_type_list():
    return {'params': params}

def set_logs_type_list():
    # Form cancel
    if app.request.forms.get('cancel'): 
        app.bottle.redirect("/logs")

    params['logs_type'] = []
    
    logs_typeList = app.request.forms.getall('logs_typeList[]')
    logger.debug("[WebUI-logs] Selected logs types : ")
    for log_type in logs_typeList:
        logger.debug("[WebUI-logs] - log type : %s" % (log_type))
        params['logs_type'].append(log_type)

    app.bottle.redirect("/logs")
    return

def get_history(name):
    elt_type = 'host'
    if '/' in name:
        elt_type = 'service'
        
    # If exists an external module ...
    if app.logs_module.is_available():
        records = app.logs_module.get_ui_logs(name=name)
        return {'records': records, 'elt_type': elt_type}
            
    logger.warning("[WebUI-logs] no get history external module defined!")
    return {'records': None}


pages = {   
        show_logs: {'routes': ['/logs'], 'view': 'logs', 'static': True},
        
        get_history: {'routes': ['/logs/inner/<name:path>'], 'view': 'history'},
    
        form_hosts_list: {'routes': ['/logs/hosts_list'], 'view': 'form_hosts_list'},
        set_hosts_list: {'routes': ['/logs/set_hosts_list'], 'view': 'logs', 'method': 'POST'},
        form_services_list: {'routes': ['/logs/services_list'], 'view': 'form_services_list'},
        set_services_list: {'routes': ['/logs/set_services_list'], 'view': 'logs', 'method': 'POST'},
        form_logs_type_list: {'routes': ['/logs/logs_type_list'], 'view': 'form_logs_type_list'},
        set_logs_type_list: {'routes': ['/logs/set_logs_type_list'], 'view': 'logs', 'method': 'POST'},
}
