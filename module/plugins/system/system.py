#!/usr/bin/python

# -*- coding: utf-8 -*-

# Copyright (C) 2009-2012:
#    Gabes Jean, naparuba@gmail.com
#    Gerhard Lausser, Gerhard.Lausser@consol.de
#    Gregory Starck, g.starck@gmail.com
#    Hartmut Goebel, h.goebel@goebel-consult.de
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
params['db_name'] = "Logs"
params['logs_limit'] = 500
params['logs_type'] = []
params['logs_hosts'] = []
params['logs_services'] = []

import os,sys
from webui import config_parser
try:
    currentdir = os.path.dirname(os.path.realpath(__file__))
    configuration_file = "%s/%s" % (currentdir, 'plugin.cfg')
    logger.debug("Plugin configuration file: %s" % (configuration_file))
    scp = config_parser('#', '=')
    params = scp.parse_config(configuration_file)

    # mongo_host = params['mongo_host']
    params['mongo_port'] = int(params['mongo_port'])
    params['logs_limit'] = int(params['logs_limit'])
    params['logs_type'] = [item.strip() for item in params['logs_type'].split(',')]
    params['logs_hosts'] = [item.strip() for item in params['logs_hosts'].split(',')]
    params['logs_services'] = [item.strip() for item in params['logs_services'].split(',')]
    
    logger.debug("Plugin configuration, database: %s (%s)" % (params['mongo_host'], params['mongo_port']))
    logger.debug("Plugin configuration, fetching: %d %s" % (params['logs_limit'], params['logs_type']))
    logger.debug("Plugin configuration, hosts: %s" % (params['logs_hosts']))
    logger.debug("Plugin configuration, services: %s" % (params['logs_services']))
except Exception, exp:
    logger.warning("Plugin configuration file (%s) not available: %s" % (configuration_file, str(exp)))


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

    return (  
        "Connected to mongo database '%s'" % dbname,
        db
    )


def system_page():
    user = app.get_user_auth()

    if not user:
        app.bottle.redirect("/user/login")

    schedulers = app.datamgr.get_schedulers()
    brokers = app.datamgr.get_brokers()
    reactionners = app.datamgr.get_reactionners()
    receivers = app.datamgr.get_receivers()
    pollers = app.datamgr.get_pollers()

    return {'app': app, 'user': user, 'schedulers': schedulers,
            'brokers': brokers, 'reactionners': reactionners,
            'receivers': receivers, 'pollers': pollers,
            }


def system_widget():
    user = app.get_user_auth()

    if not user:
        app.bottle.redirect("/user/login")

    schedulers = app.datamgr.get_schedulers()
    brokers = app.datamgr.get_brokers()
    reactionners = app.datamgr.get_reactionners()
    receivers = app.datamgr.get_receivers()
    pollers = app.datamgr.get_pollers()

    wid = app.request.GET.get('wid', 'widget_system_' + str(int(time.time())))
    collapsed = (app.request.GET.get('collapsed', 'False') == 'True')
    print "SYSTEM COLLAPSED?", collapsed, type(collapsed)

    got_childs = (app.request.GET.get('got_childs', 'False') == 'True')
    key = app.request.GET.get('key', 1)

    options = {}

    return {'app': app, 'user': user, 'wid': wid,
            'collapsed': collapsed, 'options': options,
            'base_url': '/widget/system', 'title': 'System Information',
            'schedulers': schedulers,
            'brokers': brokers, 'reactionners': reactionners,
            'receivers': receivers, 'pollers': pollers,
            }


def show_log():
    user = app.get_user_auth()

    if not user:
        app.bottle.redirect("/user/login")

    message,db = getdb(params['db_name'])
    if not db:
        return {
            'app': app,
            'user': user, 
            'message': message,
            'params': params,
            'records': []
        }

    records=[]

    try:
        logger.info("[Logs] Fetching records from database: %s (max %d)" % (params['logs_type'], params['logs_limit']))
        for log in db.logs.find({ "$and" : [ { "type" : { "$in": params['logs_type'] }}, { "host_name" : { "$in": params['logs_hosts'] }}, { "service_description" : { "$in": params['logs_services'] }}  ]}).sort("time", -1).limit(params['logs_limit']):
        # for log in db.logs.find({ "type" : { "$in": params['logs_type'] }}).sort("time", -1).limit(params['logs_limit']):
            records.append({
                "date" : int(log["time"]),
                "host" : log['host_name'],
                "service" : log['service_description'],
                "message" : log['message']
            })
        message = "%d records fetched from database." % len(records)
        logger.debug("[Logs] %d records fetched from database." % len(records))
    except Exception, exp:
        logger.error("[Logs] Exception when querying database: %s" % (str(exp)))

    return {
        'app': app,
        'user': user, 
        'message': message,
        'params': params,
        'records': records
    }


widget_desc = '''<h4>System state</h4>
Show an aggregated view of all Shinken daemons.
'''

pages = {system_page: {'routes': ['/system', '/system/'], 'view': 'system', 'static': True},
         system_widget: {'routes': ['/widget/system'], 'view': 'system_widget', 'static': True, 'widget': ['dashboard'], 'widget_desc': widget_desc, 'widget_name': 'system', 'widget_picture': '/static/system/img/widget_system.png'},
         show_log: {'routes': ['/system/logs'], 'view': 'log', 'static': True},
         }
