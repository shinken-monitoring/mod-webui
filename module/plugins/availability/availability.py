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
import datetime
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
    
    return (  
        "Connected to mongo database '%s'" % dbname,
        db
    )


def get_element(name):
    user = app.check_user_authentication()

    # If exists an external module ...
    if app.get_availability:
        records = app.get_availability(name)
        return {'app': app, 'records': records}
            
    return {'app': app, 'records': None}
    
    # logger.info("[WebUI-availability] get_element, name: %s", name)
    # hostname = None
    # service = None
    # if '/' in name:
        # service = name.split('/')[1]
        # hostname = name.split('/')[0]
    # else:
        # hostname = name
    # logger.info("[WebUI-availability] get_element, host/service: %s/%s", hostname, service)

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
        # search_hosts = []
        # if hostname is not None:
            # search_hosts = [ hostname ]
        # search_services = []
        # if service is not None:
            # search_services = [ service ]
        # logger.debug("[WebUI-availability] Fetching records from database for host/service: '%s/%s'", hostname, service)

        # query = []
        # query.append({ "hostname" : { "$in": search_hosts }})
        # if len(search_services) > 0 and search_services[0] != '':
            # query.append({ "service" : { "$in": search_services }})
            
        # if len(query) > 0:
            # for log in db[params['collection']].find({'$and': query}).sort("day",pymongo.DESCENDING).limit(max_records):
                # if '_id' in log:
                    # del log['_id']
                # records.append(log)
        # else:
            # for log in db[params['collection']].find().sort("day",pymongo.DESCENDING).limit(max_records):
                # if '_id' in log:
                    # del log['_id']
                # records.append(log)
                
        # message = "%d records fetched from database." % len(records)
        # logger.debug("[WebUI-availability] %d records fetched from database.", len(records))
    # except Exception, exp:
        # logger.error("[WebUI-availability] Exception when querying database: %s", str(exp))

    # return {'app': app, 'records': records}
    

def get_page():
    user = app.check_user_authentication()

    # Find start and end date if provided in parameters ...
    midnight_timestamp = time.mktime (datetime.date.today().timetuple())
    range_start = int(app.request.GET.get('range_start', midnight_timestamp))
    range_end = int(app.request.GET.get('range_end', midnight_timestamp+86399))
    logger.warning("[WebUI-availability] get_page, range: %d - %d", range_start, range_end)

    # If exists an external module ...
    if app.get_availability:
        records = app.get_availability(name=None, range_start=range_start, range_end=range_end)
        return {'app': app, 'user': user, 'records': records, 'range_start': range_start, 'range_end': range_end}
            
    logger.warning("[WebUI-availability] no get availability external module defined!")
    return {'app': app, 'user': user, 'records': None, 'range_start': range_start, 'range_end': range_end}
    
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
    # hosts_found=[]
    # days_found=[]
    # try:
        # logger.info("[WebUI-availability] Fetching records from database, range: %d to %d", range_start, range_end)

        # for log in db[params['collection']].find( { 'day_ts': { '$gte': range_start, '$lte': range_end } } ).sort([
                    # ("day",pymongo.DESCENDING), 
                    # ("hostname",pymongo.ASCENDING), 
                    # ("service",pymongo.ASCENDING)]).limit(params['max_records']):
                
            # if '_id' in log:
                # del log['_id']
                
            # log['found'] = True
            # if not log['hostname'] in hosts_found:
                # logger.info("[WebUI-availability] found info for host: %s", log['hostname'])
                # hosts_found.append(log['hostname'])
            # if not log['day'] in days_found:
                # logger.info("[WebUI-availability] found info for day: %s", log['day'])
                # days_found.append(log['day'])
            
            # records.append(log)
                
        # logger.debug("[WebUI-availability] %d records fetched from database.", len(records))
    # except Exception, exp:
        # logger.error("[WebUI-availability] Exception when querying database: %s", str(exp))
    # else:
        # for h in app.get_hosts():
            # if h.host_name not in hosts_found:
                # for d in days_found:
                    # logger.info("[WebUI-availability] add a record for host %s, day: %s", h.host_name, log['day'])

                    # records.append({ 
                        # "hostname": h.host_name, "service" : "", "day": d, "found": False, 
                        # "day_ts" : time.mktime(time.strptime(d, '%Y-%m-%d')), "first_check_state" : 3, "first_check_timestamp" : -1, "last_check_state" : 3, "last_check_timestamp" : -1, 
                        # "daily_0" : 0, "daily_1" : 0, "daily_2" : 0, "daily_3" : 86400, "daily_4" : 59947, "is_downtime" : "0"
                    # })
        
    # return {'app': app, 'user': user, 'records': records, 'range_start': range_start, 'range_end': range_end}
    

pages = {   
    get_element: {'routes': ['/availability/inner/<name:path>'], 'view': 'availability', 'static': True},
    get_page: {'routes': ['/availability'], 'view': 'availability-all', 'static': True},
}
