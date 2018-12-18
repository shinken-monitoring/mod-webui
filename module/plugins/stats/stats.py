#!/usr/bin/python

# -*- coding: utf-8 -*-

# Copyright (C) 2009-2014:
#    Guillaume Subiron, maethor@subiron.org
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
from datetime import datetime, timedelta

from collections import Counter, OrderedDict
from itertools import groupby

from shinken.log import logger

from copy import deepcopy
from logevent import LogEvent

# Will be populated by the UI with it's own value
app = None


def _graph(logs):
    groups_hour = groupby(reversed(logs), key=lambda x: (x['time'] - (x['time'] % 3600)))

    data = OrderedDict()
    for k, v in groups_hour:
        # Filling voids with zeros
        if data:
            while next(reversed(data)) < (k - 3600):
                data[next(reversed(data)) + 3600] = 0
        data[k] = len(list(v))

    # Smooth graph
    avg = sum(data.values()) / len(data.values())
    variance = sum([(v - avg)**2 for v in data.values()]) / len(data.values())
    deviation = variance**0.5

    # Remove every value that is 3 times out of standard deviation
    for k, v in data.items():
        if v > (avg + deviation * 3):
            data[k] = avg

    # Remove every value that is out of standard deviation and more than two times previous value
    for k, v in data.items():
        if k - 3600 in data and k + 3600 in data:
            if v > (avg + deviation) and v > (2 * data[k - 3600]):
                data[k] = (data[k - 3600] + data[k + 3600]) / 2

    if datetime.fromtimestamp(logs[-1]['time']) < (datetime.now() - timedelta(7)):
        # Group by 24h
        data_24 = OrderedDict()
        for k, v in data.items():
            t = (k - k % (3600 * 24))
            if t not in data_24:
                data_24[t] = 0
            data_24[t] += v
        data = data_24

    # Convert timestamp to milliseconds
    # Convert timestamp ms to s
    graph = [{'t': k * 1000, 'y': v} for k, v in data.items()]

    return graph


def get_alignak_stats():
    user = app.bottle.request.environ['USER']
    _ = user.is_administrator() or app.redirect403()

    logger.info("Get Alignak stats")

    days = int(app.request.GET.get('days', 30))

    range_end = int(app.request.GET.get('range_end', time.time()))
    range_start = int(app.request.GET.get('range_start', range_end - (days * 86400)))

    # Restrictive filter on contact name
    filters = ['notification']

    logs = []
    for log in app.alignak_events:
        # Try to get a monitoring event
        try:
            logger.debug("Log: %s", log)
            event = LogEvent(log['message'])
            logger.debug("-> event: %s", event)
            if not event.valid:
                logger.warning("No monitoring event detected from: %s", log['message'])
                continue

            # -------------------------------------------
            data = deepcopy(log)

            if event.event_type == 'ALERT':
                data.update({
                    "host_name": event.data['hostname'],
                    "service_name": event.data['service_desc'] or 'n/a',
                    "state": event.data['state'],
                    "state_type": event.data['state_type'],
                    "type": "alert",
                })

            if event.event_type == 'NOTIFICATION':
                data.update({
                    "host_name": event.data['hostname'],
                    "service_name": event.data['service_desc'] or 'n/a',
                    "type": "notification",
                })

            if filters and data.get('type', 'unknown') not in filters:
                continue

            logs.append(data)
            logger.info(data)
        except ValueError:
            logger.warning("Unable to decode a monitoring event from: %s", log['message'])
            continue

    hosts = Counter()
    services = Counter()
    hostsservices = Counter()
    new_logs = []
    for l in logs:
        hosts[l['host_name']] += 1
        if 'service_description' in l:
            services[l['service_description']] += 1
            hostsservices[l['host_name'] + '/' + l['service_description']] += 1
        new_logs.append(l)

    return {
        'hosts': hosts,
        'services': services,
        'hostsservices': hostsservices,
        'days': days,
        'graph': _graph(new_logs) if new_logs else None
    }


def get_global_stats():
    user = app.bottle.request.environ['USER']
    _ = user.is_administrator() or app.redirect403()

    days = int(app.request.GET.get('days', 30))

    range_end = int(app.request.GET.get('range_end', time.time()))
    range_start = int(app.request.GET.get('range_start', range_end - (days * 86400)))

    filters = {'type': 'SERVICE NOTIFICATION',
               'command_name': {'$regex': 'notify-service-by-slack'}}
    if app.alignak:
        # Restrictive filter on contact name
        filters = {
            'alignak.event': {'$in': ['HOST NOTIFICATION', 'SERVICE NOTIFICATION']},
            'alignak.contact': 'notified'
        }

    logs = list(app.logs_module.get_ui_logs(range_start=range_start, range_end=range_end,
                                            filters=filters, limit=None))

    hosts = Counter()
    services = Counter()
    hostsservices = Counter()
    new_logs = []
    for l in logs:
        # Alignak logstash parser....
        if 'alignak' in l:
            l = l['alignak']
            if 'time' not in l:
                l['time'] = int(time.mktime(l.pop('timestamp').timetuple()))

            if 'service' in l:
                l['service_description'] = l.pop('service')

        hosts[l['host_name']] += 1
        if 'service_description' in l:
            services[l['service_description']] += 1
            hostsservices[l['host_name'] + '/' + l['service_description']] += 1
        new_logs.append(l)

    return {
        'hosts': hosts,
        'services': services,
        'hostsservices': hostsservices,
        'days': days,
        'graph': _graph(new_logs) if new_logs else None
    }


def get_service_stats(name):
    user = app.bottle.request.environ['USER']
    _ = user.is_administrator() or app.redirect403()

    days = int(app.request.GET.get('days', 30))

    range_end = int(app.request.GET.get('range_end', time.time()))
    range_start = int(app.request.GET.get('range_start', range_end - (days * 86400)))

    logs = list(app.logs_module.get_ui_logs(
        range_start=range_start, range_end=range_end,
        filters={'type': 'SERVICE NOTIFICATION',
                 'command_name': {'$regex': 'notify-service-by-slack'},
                 'service_description': name},
        limit=None))

    hosts = Counter()
    for l in logs:
        hosts[l['host_name']] += 1
    return {'service': name, 'hosts': hosts, 'days': days}


def get_host_stats(name):
    user = app.bottle.request.environ['USER']
    _ = user.is_administrator() or app.redirect403()

    days = int(app.request.GET.get('days', 30))

    range_end = int(app.request.GET.get('range_end', time.time()))
    range_start = int(app.request.GET.get('range_start', range_end - (days * 86400)))

    filters = {'type': 'SERVICE NOTIFICATION',
               'command_name': {'$regex': 'notify-service-by-slack'},
               'host_name': name}
    if app.alignak:
        # Restrictive filter on contact name
        filters = {
            'alignak.event': {'$in': ['HOST NOTIFICATION', 'SERVICE NOTIFICATION']},
            'alignak.contact': 'notified',
            'alignak.host_name': name
        }

    logs = list(app.logs_module.get_ui_logs(
        range_start=range_start, range_end=range_end,
        filters=filters,
        limit=None))

    hosts = Counter()
    services = Counter()
    for l in logs:
        # Alignak logstash parser....
        if 'alignak' in l:
            l = l['alignak']
            if 'time' not in l:
                l['time'] = int(time.mktime(l.pop('timestamp').timetuple()))

            if 'service' in l:
                l['service_description'] = l.pop('service')

        hosts[l['host_name']] += 1
        if 'service_description' in l:
            services[l['service_description']] += 1
    return {
        'host': name,
        'hosts': hosts,
        'services': services,
        'days': days
    }


pages = {
    get_alignak_stats: {
        'name': 'AlignakStats', 'route': '/alignak/stats', 'view': 'stats'
    },

    get_global_stats: {
        'name': 'GlobalStats', 'route': '/stats', 'view': 'stats'
    },

    get_service_stats: {
        'name': 'Stats', 'route': '/stats/service/<name:path>', 'view': 'stats_service'
    },

    get_host_stats: {
        'name': 'Stats', 'route': '/stats/host/<name:path>', 'view': 'stats_host'
    }
}
