#!/usr/bin/python

# -*- coding: utf-8 -*-

from pymongo.connection import Connection
import time, datetime

import os,sys
currentdir = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0,currentdir+"/../..")
from webui2.config_parser import config_parser

scp = config_parser('#', '=')
params = scp.parse_config('plugin.cfg')
print params

mongo_host = params['mongo_host']
mongo_port = int(params['mongo_port'])
logs_limit = int(params['logs_limit'])
# logs_type = [item.strip() for item in params['logs_type'].split(',')]
# logs_hosts = [item.strip() for item in params['logs_hosts'].split(',')]
# logs_services = [item.strip() for item in params['logs_services'].split(',')]
logs_type = params['logs_type'].split(',')
logs_hosts = params['logs_hosts'].split(',')
logs_services = params['logs_services'].split(',')

con = Connection(mongo_host, mongo_port)
db = con['logs']
app = None # app is not otherwise
if not db:
    message = "Error : Unable to connect to mongo database"
    print message
    # return {'app': app, 'eue_data': {}, 'message': message }

# 1/ count records
print "Logs are : %d" % db.logs.count()
print "Host notifications are : %d" % db.logs.find({'type': 'HOST NOTIFICATION' }).count()

today = datetime.datetime.now()
today_beginning = datetime.datetime(today.year, today.month, today.day,0,0,0,0)
today_beginning_time = int(time.mktime(today_beginning.timetuple()))
today_end = datetime.datetime(today.year, today.month, today.day,23,59,59,999)
today_end_time = int(time.mktime(today_end.timetuple()))

yesterday = datetime.datetime.now() - datetime.timedelta(days = 1)
yesterday_beginning = datetime.datetime(yesterday.year, yesterday.month, yesterday.day,0,0,0,0)
yesterday_beginning_time = int(time.mktime(yesterday_beginning.timetuple()))
yesterday_end = datetime.datetime(yesterday.year, yesterday.month, yesterday.day,23,59,59,999)
yesterday_end_time = int(time.mktime(yesterday_end.timetuple()))

print "Host notifications since today are: %d" % db.logs.find( {"$and":[ {"type": "HOST NOTIFICATION" }, { "time": {"$gte": today_beginning_time} } ]} ).count()
print "Host notifications yesterday are: %d" % db.logs.find( {"$and":[ {"type": "HOST NOTIFICATION" }, { "time": {"$gte": yesterday_beginning_time} }, { "time": {"$lte": yesterday_end_time} } ]} ).count()

print "Host and service notifications logs are: %d" % db.logs.find({ "type" : { "$in":[ "HOST NOTIFICATION",  "SERVICE NOTIFICATION" ] }}).count()

print "Configured logs type logs are: %d" % db.logs.find({ "type" : { "$in": logs_type }}).count()

print "Configured hosts logs are: %d" % db.logs.find({ "host_name" : { "$in": logs_hosts }}).count()

print "Configured services logs are: %d" % db.logs.find({ "service_description" : { "$in": logs_services }}).count()

records=[]
for log in db.logs.find({'type': 'HOST NOTIFICATION' }).sort("time",-1).limit(logs_limit):
    records.append({
        "date" : int(log["time"]),
        "host" : log['host_name'],
        "service" : log['service_description'],
        "message" : log['message']
    })

    
query = []
print "Logs type: %s (%d)." % (str(logs_type), len(logs_type))
if len(logs_type) > 0 and logs_type[0] != '':
    query.append({ "type" : { "$in": logs_type }})
print "Logs hosts: %s (%d)." % (str(logs_hosts), len(logs_hosts))
if len(logs_hosts) > 0 and logs_hosts[0] != '':
    query.append({ "host_name" : { "$in": logs_hosts }})
print "Logs services: %s (%d)." % (str(logs_services), len(logs_services))
if len(logs_services) > 0 and logs_services[0] != '':
    query.append({ "service_description" : { "$in": logs_services }})
results = db.collection.find({'$and': query})
print "Query: %s." % str(query)    
    
records=[]
if len(query) > 0:
    for log in db.logs.find({'$and': query}).sort("time",-1).limit(logs_limit):
        records.append({
            "date" : int(log["time"]),
            "host" : log['host_name'],
            "service" : log['service_description'],
            "message" : log['message']
        })
else:
    for log in db.logs.find().sort("time",-1).limit(logs_limit):
        records.append({
            "date" : int(log["time"]),
            "host" : log['host_name'],
            "service" : log['service_description'],
            "message" : log['message']
        })
print "%d records fetched from database." % len(records)
