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

import re
import time
import datetime

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
params['db_name'] = "Logs"
params['logs_limit'] = 500
params['logs_type'] = []

import os,sys
currentdir = os.path.dirname(os.path.realpath(__file__)) 
sys.path.insert(0,currentdir+"/../..") 
from config_parser import config_parser 
plugin_name = os.path.splitext(os.path.basename(__file__))[0]
try:
    configuration_file = "%s/%s" % (currentdir, 'plugin.cfg')
    logger.debug("Plugin configuration file: %s" % (configuration_file))
    scp = config_parser('#', '=')
    params = scp.parse_config(configuration_file)

    # params['mongo_host'] = params['mongo_host']
    params['mongo_port'] = int(params['mongo_port'])
    params['logs_limit'] = int(params['logs_limit'])
    params['logs_type'] = [item.strip() for item in params['logs_type'].split(',')]
    
    logger.debug("WebUI plugin '%s', configuration loaded." % (plugin_name))
    logger.debug("Plugin configuration, database: %s (%s)" % (params['mongo_host'], params['mongo_port']))
    logger.debug("Plugin configuration, fetching: %d %s" % (params['logs_limit'], params['logs_type']))
except Exception, exp:
    logger.warning("WebUI plugin '%s', configuration file (%s) not available: %s" % (plugin_name, configuration_file, str(exp)))


def checkauth():
    user = app.get_user_auth()

    if not user:
        app.bottle.redirect("/user/login")
    else:
        return user

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


# Our page. If the user call /dummy/TOTO arg1 will be TOTO.
# if it's /dummy/, it will be 'nothing'
def get_page(hostname='nothing'):
    user = checkauth()

    return {'app': app, 'user': user, 'hostname': hostname}


def get_json(hostname):
    user = checkauth()    

    app.response.content_type = 'application/json'

    host = app.datamgr.get_host(hostname)
    
    message,db = getdb(params['db_name'])
    if not db:
        return {
            'app': app,
            'user': user, 
            'message': message,
            'params': params,
            'records': []
        }

    logger.info("[Timeline] Fetching records from database for host %s" % (hostname))
    
    records=[]

    try:
        logger.info("[Timeline] Fetching records from database: %s (max %d)" % (params['logs_type'], params['logs_limit']))
        # {
        # "_id" : ObjectId("53140d923dbf176872000014"),
        # "comment" : "",
        # "plugin_output" : "",
        # "attempt" : 0,
        # "message" : "[1393823120] CURRENT SERVICE STATE: localhost;Load;PENDING;HARD;0;",
        # "logclass" : 6,
        # "options" : "",
        # "state_type" : "HARD",
        # "lineno" : 21,
        # "state" : "PENDING",
        # "host_name" : "localhost",
        # "time" : 1393823120,
        # "service_description" : "Load",
        # "logobject" : 2,
        # "type" : "CURRENT SERVICE STATE",
        # "contact_name" : "",
        # "command_name" : ""
        # }

        for log in db.logs.find({ "$and" : [ { "type" : { "$in": params['logs_type'] }}, { "host_name" : hostname }  ]}).sort("time", -1).limit(params['logs_limit']):
            records.append({
                "date" : int(log["time"]),
                "host" : log['host_name'],
                "service" : log['service_description'],
                "message" : log['message'].split(":")[1].lstrip()
            })
        message = "%d records fetched from database." % len(records)
        logger.debug(message)
    except Exception, exp:
        logger.error("[Logs] Exception when querying database: %s" % (str(exp)))
        return

    records = sorted(records, key=lambda record: (record.get('service'), record.get('date')))
    
    timeline = []
    for record in records:
        t=datetime.datetime.fromtimestamp(record['date'])
        logger.warning("[Timeline] Record: %s / %s -> %s" % (t.strftime('%Y,%m,%d %H:%m'), t.isoformat(), record['message']))
        message = record['message'].split(";")
        content = 'Downtime %s<br>' % message[1].lower()
        content +='<img src="/static/timeline/img/host_downtime.png" style="width:32px; height:32px;"><br/>'
        timeline.append({
                "start": t.isoformat(),
                "content" : content,
                # "group": 'Transitions'
        })
    
    # timeline = []
    # initial_state = ""
    # current_state = ""
    # start_date = 0
    # for record in records:
        # t=datetime.datetime.fromtimestamp(record['date'])
        # logger.warning("[Timeline] Record: %s -> %s" % (t.strftime('%Y,%m,%d %H:%m'), record['message']))
        # message = record['message'].split(";")
        
        # if message[1] != "OK":
            # current_state = message[1]
            # if start_date == 0:
                # start_date = record['date']
            
        # if message[1] == "OK" and current_state != "":
            # current_state = message[1]
            
            # content = 'Host is %s<br>' % current_state
            # content +='<img src="/static/timeline/img/host_%s.png" style="width:32px; height:32px;"><br/>' % current_state.lower()

            # logger.warning("[Timeline] -> Period: %s" % (content))
            # timeline.append({
                    # "start": start_date,
                    # "end": record['date'],
                    # "content" : content,
                    # "group": record['service'],
            # })
            
            # start_date = 0
    
    logger.debug("[Timeline] Finished compiling fetched records")
    return json.dumps(timeline)


pages = {get_page: {'routes': ['/timeline/:hostname'], 'view': 'timeline', 'static': True},
         get_page: {'routes': ['/timeline/inner/:hostname'], 'view': 'timeline_inner', 'static': True},
         get_json: {'routes': ['/timeline/json/:hostname'], 'view': 'timeline', 'static': True},}
