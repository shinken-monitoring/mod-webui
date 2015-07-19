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

# Json lib
try:
    import json
except ImportError:
    # For old Python version, load
    # simple json (it can be hard json?! It's 2 functions guy!)
    try:
        import simplejson as json
    except ImportError:
        print "Error: you need the json or simplejson module"
        raise

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


def getdb(dbname):
    con = None
    db = None

    try:
        con = Connection(params['mongo_host'],int(params['mongo_port']))
    except:
        return (  
            "Error : Unable to create mongo DB connection %s:%s" % (params['mongo_host'],params['mongo_port']),
            None
        )

    try:
        db = con[dbname]
    except:
        return (  
            "Error : Unable to connect to mongo database %s" % dbname,
            None
        )
    
    # Store connection and db handle ...
    # self.con = con
    # self.db = db
    
    return (  
        "Connected to mongo database '%s'" % dbname,
        db
    )


def show_logs():
    # If exists an external module ...
    if app.get_history:
        records = app.get_history(name=None, logs_type = params['logs_type'])
        return {'records': records, 'params': params, 'message': "%d records fetched from database." % len(records)}
            
    logger.warning("[WebUI-logs] no get history external module defined!")
    return {'records': None, 'params': params, 'message': "No module configured to get Shinken logs from a database!"}
    
    # message,db = getdb(params['database'])
    # if not db:
        # return {
            # 'app': app,
            # 'user': user, 
            # 'message': message,
            # 'params': params,
            # 'records': []
        # }

    # records=[]

    # try:
        # logger.debug("[WebUI-logs] fetching records from database: %s / %s / %s (max %d)", params['logs_type'], params['logs_hosts'], params['logs_services'], params['max_records'])

        # max_records = params['max_records']
        # logs_type = params['logs_type']
        # logs_hosts = params['logs_hosts']
        # logs_services = params['logs_services']

        # query = []
        # if len(logs_type) > 0 and logs_type[0] != '':
            # query.append({ "type" : { "$in": logs_type }})
        # if len(logs_hosts) > 0 and logs_hosts[0] != '':
            # query.append({ "host_name" : { "$in": logs_hosts }})
        # if len(logs_services) > 0 and logs_services[0] != '':
            # query.append({ "service_description" : { "$in": logs_services }})
            
        # records=[]
        # if len(query) > 0:
            # for log in db.logs.find({'$and': query}).sort("time",pymongo.DESCENDING).limit(max_records):
                # message = log['message']
                # m = re.search(r"\[(\d+)\] (.*)", message)
                # if m and m.group(2):
                    # message = m.group(2)
                    
                # records.append({
                    # "date" : int(log["time"]),
                    # "host" : log['host_name'],
                    # "service" : log['service_description'],
                    # "message" : message
                # })
        # else:
            # for log in db.logs.find().sort("time",pymongo.DESCENDING).limit(max_records):
                # message = log['message']
                # m = re.search(r"\[(\d+)\] (.*)", message)
                # if m and m.group(2):
                    # message = m.group(2)
                    
                # records.append({
                    # "date" : int(log["time"]),
                    # "host" : log['host_name'],
                    # "service" : log['service_description'],
                    # "message" : message
                # })
        # message = "%d records fetched from database." % len(records)
        # logger.info("[WebUI-logs] %d records fetched from database.", len(records))
    # except Exception, exp:
        # logger.error("[WebUI-logs] Exception when querying database: %s", str(exp))

    # return {
        # 'app': app,
        # 'user': user, 
        # 'message': message,
        # 'params': params,
        # 'records': records
    # }


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
    # If exists an external module ...
    if app.get_history:
        records = app.get_history(name=name)
        return {'records': records}
            
    logger.warning("[WebUI-logs] no get history external module defined!")
    return {'records': None}

    # logger.debug("[WebUI-logs] get_history, name: %s", name)
    # hostname = None
    # service = None
    # if '/' in name:
        # service = name.split('/')[1]
        # hostname = name.split('/')[0]
    # else:
        # hostname = name
    # logger.debug("[WebUI-logs] get_history, host/service: %s/%s", hostname, service)

    # message,db = getdb(params['database'])
    # if not db:
        # return {
            # 'app': app,
            # 'user': user, 
            # 'message': message,
            # 'params': params,
            # 'records': []
        # }

    # records=[]

    # try:
        # max_records = params['max_records']
        # logs_type = []
        # logs_hosts = [ hostname ]
        # logs_services = [ ]
        # if service is not None:
            # logger.debug("[WebUI-logs] Fetching records from database for host/service: %s/%s", hostname, service)
            # logs_services = [ service ]
        # else:
            # logger.debug("[WebUI-logs] Fetching records from database for host: %s", hostname)

        # query = []
        # if len(logs_type) > 0 and logs_type[0] != '':
            # query.append({ "type" : { "$in": logs_type }})
        # if len(logs_hosts) > 0 and logs_hosts[0] != '':
            # query.append({ "host_name" : { "$in": logs_hosts }})
        # if len(logs_services) > 0 and logs_services[0] != '':
            # query.append({ "service_description" : { "$in": logs_services }})
            
        # records=[]
        # if len(query) > 0:
            # for log in db.logs.find({'$and': query}).sort("time",pymongo.DESCENDING).limit(max_records):
                # message = log['message']
                # m = re.search(r"\[(\d+)\] (.*)", message)
                # if m and m.group(2):
                    # message = m.group(2)
                    
                # records.append({
                    # "timestamp":    int(log["time"]),
                    # "host":         log['host_name'],
                    # "service":      log['service_description'],
                    # "message":      message
                # })
        # else:
            # for log in db.logs.find().sort("time",pymongo.DESCENDING).limit(max_records):
                # message = log['message']
                # m = re.search(r"\[(\d+)\] (.*)", message)
                # if m and m.group(2):
                    # message = m.group(2)
                    
                # records.append({
                    # "timestamp":    int(log["time"]),
                    # "host":         log['host_name'],
                    # "service":      log['service_description'],
                    # "message":      message
                # })
        # message = "%d records fetched from database." % len(records)
        # logger.debug("[WebUI-logs] %d records fetched from database.", len(records))
    # except Exception, exp:
        # logger.error("[WebUI-logs] Exception when querying database: %s", str(exp))
    
    # return {'records': records}

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
