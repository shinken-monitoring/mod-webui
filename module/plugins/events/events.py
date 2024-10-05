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
import json
from bson import json_util
import pymongo


# Will be populated by the UI with it's own value
app = None

# TODO event module
def _get_events(host_name, range_start, range_end, level):
    # TODO event module
    return list(app.logs_module.module.db['events'].find({'host_name': host_name, 'time': {'$gte': range_start, '$lte': range_end}, 'level': {'$gte': level}}).sort([('time', pymongo.DESCENDING)]))

# TODO event module
def _add_event(host_name, message, t, level, source):
    app.logs_module.module.db['events'].insert_one({'host_name': host_name, 'message': message, 'time': int(t), 'level': int(level), 'source': source})


# Host element view
def host(host_name):
    # Ok, we can lookup it
    user = app.bottle.request.environ['USER']
    h = app.datamgr.get_host(host_name, user) or app.redirect404()

    # Set hostgroups level ...
    app.datamgr.set_hostgroups_level(user)

    # Get graph data. By default, show last 4 hours
    now = int(time.time())

    midnight_timestamp = time.mktime(datetime.date.today().timetuple())

    range_start = int(app.request.query.get('range_start', midnight_timestamp))
    range_end = int(app.request.query.get('range_end', midnight_timestamp + 86399))
    level = int(app.request.query.get('level', 0))

    events = _get_events(host_name, range_start, range_end, level)

    filters = dict()
    filters['host_name'] = host_name
    filters['logclass'] = 1
    filters['state_type'] = 'HARD'
    if app.logs_module.is_available():
        logs=app.logs_module.get_ui_logs(filters=filters, range_start=range_start, range_end=range_end)[0]

    for l in logs:
        # if host, level 3, else level 1 ?
        # se baser sur business_impact ???
        if l['state'] == 0:
            continue
        elif l['state'] == 2:
            if l['service_description']:
                l['level'] = 2
            else:
                l['level'] = 3
        else:
            l['level'] = 1

        if l['level'] >= level:
            events.append({'level': l['level'], 'time': l['time'], 'author': 'shinken', 'source': 'Shinken', 'message': l['service_description'] + ': ' + l['plugin_output'], 'log': l})

    if level <= 1:
        comments = [ c for c in h.comments if c.entry_time >= range_start and c.entry_type <= range_end ]
        for s in h.services:
            comments += [ c for c in s.comments if c.entry_time >= range_start and c.entry_type <= range_end ]
        for c in comments:
            events.append({'level': 1, 'time': c.entry_time, 'author': c.author, 'source': 'Comments', 'message': c.comment})

    return {
        'elt': h,
        'range_start': range_start,
        'range_end': range_end,
        'level': level,
        'events': sorted(events, key=lambda d: d['time'], reverse=True)
    }


def add_event(host_name):
    user = app.bottle.request.environ['USER']
    h = app.datamgr.get_host(host_name, user) or app.redirect404()

    t = app.request.forms.get('time', int(time.time()))
    level = app.request.forms.get('level', 0)
    message = app.request.forms.get('message', 'msg')
    source = app.request.forms.get('source', '')

    _add_event(host_name, message, t, level, source)

    app.response.content_type = 'application/json'
    return "{'status': 200, 'text': 'New event : %s'}" % message


pages = {
    host: {
        'name': 'EventsHost', 'route': '/events/host/:host_name',
        'view': 'events',
        'static': True
    },
    add_event: {
        'name': 'AddEvent', 'route': '/api/events/add/:host_name',
        'method': 'POST'
    }
}
