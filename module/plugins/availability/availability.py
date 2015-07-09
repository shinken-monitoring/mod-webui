#!/usr/bin/python
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
params['collection'] = "availability"
params['max_records'] = 500
params['logs_type'] = ['INFO', 'WARNING', 'ERROR']
params['search_hosts'] = []
params['search_services'] = []

def load_config(app):
    global params
    
    import os,sys
    from webui.config_parser import config_parser
    plugin_name = os.path.splitext(os.path.basename(__file__))[0]
    try:
        currentdir = os.path.dirname(os.path.realpath(__file__))
        configuration_file = "%s/%s" % (currentdir, 'plugin.cfg')
        logger.info("[WebUI-availability] Plugin configuration file: %s", configuration_file)
        scp = config_parser('#', '=')
        z = params.copy()
        z.update(scp.parse_config(configuration_file))
        params = z

        # Integers ...
        params['mongo_port'] = int(params['mongo_port'])
        params['max_records'] = int(params['max_records'])
        
        logger.info("[WebUI-availability] configuration loaded.")
        logger.info("[WebUI-availability] configuration, database: %s (%s) - %s, %s", params['mongo_host'], params['mongo_port'], params['database'], params['collection'])
        logger.info("[WebUI-availability] configuration, fetching limit: %d", params['max_records'])
        return True
    except Exception, exp:
        logger.warning("[WebUI-availability] configuration file (%s) not available: %s", configuration_file, str(exp))
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


def get_element(name):
    user = app.check_user_authentication()

    logger.info("[WebUI-availability] get_element, name: %s", name)
    hostname = None
    service = None
    if '/' in name:
        service = name.split('/')[1]
        hostname = name.split('/')[0]
    else:
        hostname = name
    logger.info("[WebUI-availability] get_element, host/service: %s/%s", hostname, service)

    message,db = getdb(params['database'])
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
        max_records = params['max_records']
        search_hosts = []
        if hostname is not None:
            search_hosts = [ hostname ]
        search_services = []
        if service is not None:
            search_services = [ service ]
        logger.debug("[WebUI-availability] Fetching records from database for host/service: '%s/%s'", hostname, service)

        query = []
        query.append({ "hostname" : { "$in": search_hosts }})
        if len(search_services) > 0 and search_services[0] != '':
            query.append({ "service" : { "$in": search_services }})
            
        if len(query) > 0:
            for log in db[params['collection']].find({'$and': query}).sort("day",pymongo.DESCENDING).limit(max_records):
                if '_id' in log:
                    del log['_id']
                records.append(log)
        else:
            for log in db[params['collection']].find().sort("day",pymongo.DESCENDING).limit(max_records):
                if '_id' in log:
                    del log['_id']
                records.append(log)
                
        message = "%d records fetched from database." % len(records)
        logger.debug("[WebUI-availability] %d records fetched from database.", len(records))
    except Exception, exp:
        logger.error("[WebUI-availability] Exception when querying database: %s", str(exp))

    return {'app': app, 'records': records}
    

def get_page():
    user = app.check_user_authentication()

    logger.info("[WebUI-availability] get_page")
    hostname = None
    service = None

    message,db = getdb(params['database'])
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
        max_records = params['max_records']
        logger.debug("[WebUI-availability] Fetching records from database for all hosts")

        for log in db[params['collection']].find().sort("day",pymongo.DESCENDING).limit(max_records):
            if '_id' in log:
                del log['_id']
            records.append(log)
                
        logger.debug("[WebUI-availability] %d records fetched from database.", len(records))
    except Exception, exp:
        logger.error("[WebUI-availability] Exception when querying database: %s", str(exp))

    return {'app': app, 'user': user, 'records': records}
    

pages = {   
    get_element: {'routes': ['/availability/inner/<name:path>'], 'view': 'availability', 'static': True},
    get_page: {'routes': ['/availability'], 'view': 'availability-all', 'static': True},
}
