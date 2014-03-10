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
from webui import config_parser
try:
    currentdir = os.path.dirname(os.path.realpath(__file__))
    configuration_file = "%s/%s" % (currentdir, 'plugin.cfg')
    logger.debug("Plugin configuration file: %s" % (configuration_file))
    scp = config_parser('#', '=')
    params = scp.parse_config(configuration_file)

    # params['mongo_host'] = params['mongo_host']
    params['mongo_port'] = int(params['mongo_port'])
    params['logs_limit'] = int(params['logs_limit'])
    params['logs_type'] = [item.strip() for item in params['logs_type'].split(',')]
    
    logger.debug("Plugin configuration, database: %s (%s)" % (params['mongo_host'], params['mongo_port']))
    logger.debug("Plugin configuration, fetching: %d %s" % (params['logs_limit'], params['logs_type']))
except Exception, exp:
    logger.warning("Plugin configuration file (%s) not available: %s" % (configuration_file, str(exp)))


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

    logger.warning("[Timeline] Fetching records from database for host %s" % (hostname))
    
    records=[]

    try:
        logger.warning("[Timeline] Fetching records from database: %s (max %d)" % (params['logs_type'], params['logs_limit']))
        for log in db.logs.find({ "$and" : [ { "type" : { "$in": params['logs_type'] }}, { "host_name" : hostname }  ]}).sort("time", 1).limit(params['logs_limit']):
            records.append({
                "date" : int(log["time"]),
                "service" : log['service_description'],
                "message" : log['message']
            })
        message = "%d records fetched from database." % len(records)
        logger.debug("[Timeline] %d records fetched from database." % len(records))
    except Exception, exp:
        logger.error("[Logs] Exception when querying database: %s" % (str(exp)))
        return

    timeline = {}
    timeline['type'] = "default"
    timeline['headline'] = hostname
    timeline['startDate'] = "2014,01,01"
    timeline['text'] = host.get_full_name()
    if len(host.display_name) > 0:
        timeline['text'] += ' ('+host.display_name+')'
        
    timeline['asset'] = {}
    timeline['asset']['media'] = "http://www.flickr.com/photos/tm_10001/2310475988/"
    timeline['asset']['credit'] = "flickr/<a href='http://www.flickr.com/photos/tm_10001/'>tm_10001</a>"
    timeline['asset']['caption'] = "Whitney Houston performing on her My Love is Your Love Tour in Hamburg."
    timeline['date'] = []
    for record in records:
        t=datetime.datetime.fromtimestamp(record['date'])

        timeline['date'].append({
                "startDate" : t.strftime('%Y,%m,%d %H:%m'),
                "headline" : record['service'],
                "text" : record['message']
        })
    
    output = {}
    output['timeline'] = timeline
    
    return json.dumps(output)


pages = {get_page: {'routes': ['/timeline/:hostname'], 'view': 'timeline', 'static': True},
         get_json: {'routes': ['/timeline/json/:hostname'], 'view': 'timeline', 'static': True},}
