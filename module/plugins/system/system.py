#!/usr/bin/python

# -*- coding: utf-8 -*-

# Copyright (C) 2009-2014:
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
import requests
import traceback

from copy import deepcopy
from logevent import LogEvent

from shinken.log import logger

# Will be populated by the UI with it's own value
app = None


def _get_alignak_livesynthesis():
    """Get Alignak livesynthesis from the Arbiter API:
    {
        "alignak": "My Alignak",
        "livesynthesis": {
            "_overall": {
                "_freshness": 1534237749,
                "livesynthesis": {
                    "hosts_acknowledged": 0,
                    "hosts_down_hard": 0,
                    "hosts_down_soft": 0,
                    "hosts_flapping": 0,
                    "hosts_in_downtime": 0,
                    "hosts_not_monitored": 0,
                    "hosts_total": 13,
                    "hosts_unreachable_hard": 0,
                    "hosts_unreachable_soft": 0,
                    "hosts_up_hard": 13,
                    "hosts_up_soft": 0,
                    "services_acknowledged": 0,
                    "services_critical_hard": 6,
                    "services_critical_soft": 4,
                    "services_flapping": 0,
                    "services_in_downtime": 0,
                    "services_not_monitored": 0,
                    "services_ok_hard": 70,
                    "services_ok_soft": 0,
                    "services_total": 100,
                    "services_unknown_hard": 4,
                    "services_unknown_soft": 6,
                    "services_unreachable_hard": 0,
                    "services_unreachable_soft": 0,
                    "services_warning_hard": 5,
                    "services_warning_soft": 5
                }
            },
            "scheduler-master": {
                "_freshness": 1534237747,
                "livesynthesis": {
                    "hosts_acknowledged": 0,
                    "hosts_down_hard": 0,
                    "hosts_down_soft": 0,
                    "hosts_flapping": 0,
                    "hosts_in_downtime": 0,
                    "hosts_not_monitored": 0,
                    "hosts_total": 13,
                    "hosts_unreachable_hard": 0,
                    "hosts_unreachable_soft": 0,
                    "hosts_up_hard": 13,
                    "hosts_up_soft": 0,
                    "services_acknowledged": 0,
                    "services_critical_hard": 6,
                    "services_critical_soft": 4,
                    "services_flapping": 0,
                    "services_in_downtime": 0,
                    "services_not_monitored": 0,
                    "services_ok_hard": 70,
                    "services_ok_soft": 0,
                    "services_total": 100,
                    "services_unknown_hard": 4,
                    "services_unknown_soft": 6,
                    "services_unreachable_hard": 0,
                    "services_unreachable_soft": 0,
                    "services_warning_hard": 5,
                    "services_warning_soft": 5
                }
            }
        },
        "name": "arbiter-master",
        "running_id": "1534237614.73657398",
        "start_time": 1534237614,
        "type": "arbiter",
        "version": "2.0.0rc2"
    }
    """
    if not getattr(app, 'alignak_endpoint', None):
        logger.info("[WebUI-system] Alignak is not configured. Redirecting to the home page.")
        app.bottle.redirect(app.get_url("Dashboard"))

    logger.debug("[WebUI-system] Get Alignak livesynthesis, endpoint: %s", app.alignak_endpoint)
    try:
        req = requests.Session()
        raw_data = req.get("%s/livesynthesis" % app.alignak_endpoint)
        data = json.loads(raw_data.content)
        logger.debug("[WebUI-system] Result: %s", data)
    except Exception as exp:
        logger.error("[WebUI-system] alignak_livesynthesis, exception: %s", exp)
        app.request.environ['MSG'] = "Alignak Error"
        app.bottle.redirect(app.get_url("Dashboard"))

    return data


def _get_alignak_status():
    """Get Alignak overall status from the Arbiter API:
    {
        "livestate": {
            "long_output": "broker-master - daemon is alive and reachable.\npoller-master - daemon is alive and reachable.\nreactionner-master - daemon is not reachable.\nreceiver-master - daemon is alive and reachable.\nscheduler-master - daemon is alive and reachable.",
            "output": "Some of my daemons are not reachable.",
            "perf_data": "'modules'=2 'timeperiods'=4 'services'=100 'servicegroups'=1 'commands'=10 'hosts'=13 'hostgroups'=5 'contacts'=2 'contactgroups'=2 'notificationways'=2 'checkmodulations'=0 'macromodulations'=0 'servicedependencies'=40 'hostdependencies'=0 'arbiters'=1 'schedulers'=1 'reactionners'=1 'brokers'=1 'receivers'=1 'pollers'=1 'realms'=1 'resultmodulations'=0 'businessimpactmodulations'=0 'escalations'=0 'hostsextinfo'=0 'servicesextinfo'=0",
            "state": "up",
            "timestamp": 1542611507
        },
        "name": "My Alignak",
        "services": [
            {
                "livestate": {
                    "long_output": "",
                    "output": "warning because some daemons are not reachable.",
                    "perf_data": "",
                    "state": "warning",
                    "timestamp": 1542611507
                },
                "name": "arbiter-master"
            },
            {
                "livestate": {
                    "long_output": "Realm: All (True). Listening on: http://127.0.0.1:7772/",
                    "name": "broker_broker-master",
                    "output": "daemon is alive and reachable.",
                    "perf_data": "last_check=0.00",
                    "state": "ok",
                    "timestamp": 1542611507
                },
                "name": "broker-master"
            },
            {
                "livestate": {
                    "long_output": "Realm: All (True). Listening on: http://127.0.0.1:7771/",
                    "name": "poller_poller-master",
                    "output": "daemon is alive and reachable.",
                    "perf_data": "last_check=0.00",
                    "state": "ok",
                    "timestamp": 1542611507
                },
                "name": "poller-master"
            },
            {
                "livestate": {
                    "long_output": "Realm: All (True). Listening on: http://127.0.0.1:7769/",
                    "name": "reactionner_reactionner-master",
                    "output": "daemon is not reachable.",
                    "perf_data": "last_check=0.00",
                    "state": "warning",
                    "timestamp": 1542611507
                },
                "name": "reactionner-master"
            },
            {
                "livestate": {
                    "long_output": "Realm: All (True). Listening on: http://127.0.0.1:7773/",
                    "name": "receiver_receiver-master",
                    "output": "daemon is alive and reachable.",
                    "perf_data": "last_check=0.00",
                    "state": "ok",
                    "timestamp": 1542611507
                },
                "name": "receiver-master"
            },
            {
                "livestate": {
                    "long_output": "Realm: All (True). Listening on: http://127.0.0.1:7768/",
                    "name": "scheduler_scheduler-master",
                    "output": "daemon is alive and reachable.",
                    "perf_data": "last_check=0.00",
                    "state": "ok",
                    "timestamp": 1542611507
                },
                "name": "scheduler-master"
            }
        ],
        "template": {
            "_templates": [
                "alignak",
                "important"
            ],
            "active_checks_enabled": false,
            "alias": "My Alignak",
            "notes": "",
            "passive_checks_enabled": true
        },
        "variables": {}
    }
    """
    if not getattr(app, 'alignak_endpoint', None):
        logger.info("[WebUI-system] Alignak is not configured. Redirecting to the home page.")
        app.bottle.redirect(app.get_url("Dashboard"))

    logger.debug("[WebUI-system] Get Alignak status, endpoint: %s", app.alignak_endpoint)
    try:
        req = requests.Session()
        raw_data = req.get("%s/status" % app.alignak_endpoint)
        data = json.loads(raw_data.content)
        logger.debug("[WebUI-system] Result: %s", data)
    except Exception as exp:
        logger.error("[WebUI-system] alignak_status, exception: %s", exp)
        app.request.environ['MSG'] = "Alignak Error"
        app.bottle.redirect(app.get_url("Dashboard"))

    return data


def alignak_status():
    """Alignak livestate view:
    live state and live synthesis information from the arbiter"""

    return {
        'ls': _get_alignak_livesynthesis(),
        'status': _get_alignak_status()
    }


def alignak_events():
    """Get Alignak Arbiter events:
    """
    if not getattr(app, 'alignak_endpoint', None):
        logger.info("[WebUI-system] Alignak is not configured. Redirecting to the home page.")
        app.bottle.redirect(app.get_url("Dashboard"))

    user = app.request.environ['USER']
    _ = user.is_administrator() or app.redirect403()

    midnight_timestamp = time.mktime(datetime.date.today().timetuple())
    try:
        range_start = int(app.request.query.get('range_start', midnight_timestamp))
    except ValueError:
        range_start = midnight_timestamp

    try:
        range_end = int(app.request.query.get('range_end', midnight_timestamp + 86399))
    except ValueError:
        range_end = midnight_timestamp + 86399
    logger.debug("[WebUI-logs] get_global_history, range: %d - %d", range_start, range_end)

    # Apply search filter if exists ...
    search = app.request.query.get('search', "type:host")
    if "type:host" not in search:
        search = "type:host " + search
    logger.debug("[WebUI-system] search parameters '%s'", search)

    filters = ','.join(app.request.query.getall('filter')) or ""
    logger.debug("[WebUI-system] filters: %s", filters)

    # Fetch elements per page preference for user, default is 25
    elts_per_page = app.prefs_module.get_ui_user_preference(user, 'elts_per_page', 25)

    # We want to limit the number of elements
    step = int(app.request.query.get('step', elts_per_page))
    start = int(app.request.query.get('start', '0'))
    end = int(app.request.query.get('end', start + step))

    items = []
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
            if event.event_type == 'RETENTION':
                type = "retention_save"
                if event.data['state_type'].upper() == 'LOAD':
                    type = "retention_load"
                data.update({
                    "type": type
                })

            if event.event_type == 'TIMEPERIOD':
                data.update({
                    "type": "timeperiod_transition",
                })

            if event.event_type == 'EXTERNAL COMMAND':
                data.update({
                    "type": "external_command",
                    "message": event.data['command']
                })

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

            if event.event_type == 'DOWNTIME':
                downtime_type = "downtime_start"
                if event.data['state'] == 'STOPPED':
                    downtime_type = "downtime_end"
                if event.data['state'] == 'CANCELLED':
                    downtime_type = "downtime_cancelled"

                data.update({
                    "host_name": event.data['hostname'],
                    "service_name": event.data['service_desc'] or 'n/a',
                    "user_name": "Alignak",
                    "type": downtime_type,
                })

            if event.event_type == 'ACKNOWLEDGE':
                ack_type = "acknowledge_start"
                if event.data['state'] == 'EXPIRED':
                    ack_type = "acknowledge_end"
                if event.data['state'] == 'CANCELLED':
                    ack_type = "acknowledge_cancelled"

                data.update({
                    "host_name": event.data['hostname'],
                    "service_name": event.data['service_desc'] or 'n/a',
                    "user_name": "Alignak",
                    "type": ack_type,
                })

            if event.event_type == 'FLAPPING':
                flapping_type = "monitoring.flapping_start"
                if event.data['state'] == 'STOPPED':
                    flapping_type = "monitoring.flapping_stop"

                data.update({
                    "host_name": event.data['hostname'],
                    "service_name": event.data['service_desc'] or 'n/a',
                    "user_name": "Alignak",
                    "type": flapping_type,
                })

            if event.event_type == 'COMMENT':
                data.update({
                    "host_name": event.data['hostname'],
                    "service_name": event.data['service_desc'] or 'n/a',
                    "user_name": event.data['author'] or 'Alignak',
                    "type": "comment",
                })

            if filters and data.get('type', 'unknown') not in filters:
                continue

            items.append(data)
        except ValueError:
            logger.warning("Unable to decode a monitoring event from: %s", log['message'])
            logger.warning(traceback.format_exc())
            continue

    # If we overflow, came back as normal
    total = len(items)
    if start > total:
        start = 0
        end = step

    navi = app.helper.get_navi(total, start, step=step)

    logger.info("[WebUI-system] got %d matching items", len(items))

    return {
        'navi': navi,
        'page': "alignak/events",
        'logs': items[start:end],
        'total': total,
        "filters": filters,
        'range_start': range_start,
        'range_end': range_end
    }


def system_parameters():
    user = app.request.environ['USER']
    _ = user.is_administrator() or app.redirect403()

    # configs = app.datamgr.get_configs()
    # if configs:
    #     configs = sorted(vars(configs[0]).iteritems())
    #     return {'configs': configs}

    return {'configs': app.datamgr.get_configs()}


def alignak_parameters():
    """Get the configuration information received from the schedulers and prepare to display
    in a clean fashion. All schedulers provide the same configuration and maco information
    that may be displayed separately to the end user.
    """
    user = app.request.environ['USER']
    _ = user.is_administrator() or app.redirect403()

    # All the received scheduler configurations send their configuratio nwhich is composed of:
    # _macros: a global part for the macro definition
    # _config: a global part for the framework configuration
    # _running: a scheduler specific part
    configuration = {
        '_config': {},
        '_macros': {},
        '_schedulers': deepcopy(app.datamgr.get_configs())
    }

    for config in configuration['_schedulers']:
        logger.debug("Got a scheduler configuration: %s", config)
        configuration['_macros'] = config.pop('_macros')
        configuration['_config'] = config.pop('_config')
    logger.debug("Global configuration: %s", configuration)

    return {'configuration': configuration}


def system_page():
    user = app.request.environ['USER']
    _ = user.is_administrator() or app.redirect403()

    schedulers = app.datamgr.get_schedulers()
    brokers = app.datamgr.get_brokers()
    reactionners = app.datamgr.get_reactionners()
    receivers = app.datamgr.get_receivers()
    pollers = app.datamgr.get_pollers()

    logger.debug("[WebUI-system] schedulers: %s", schedulers)
    logger.debug("[WebUI-system] brokers: %s", brokers)
    logger.debug("[WebUI-system] reactionners: %s", reactionners)
    logger.debug("[WebUI-system] receivers: %s", receivers)
    logger.debug("[WebUI-system] pollers: %s", pollers)

    return {
        'schedulers': schedulers, 'brokers': brokers, 'reactionners': reactionners,
        'receivers': receivers, 'pollers': pollers,
    }


def system_widget():
    _ = app.request.environ['USER']

    schedulers = app.datamgr.get_schedulers()
    brokers = app.datamgr.get_brokers()
    reactionners = app.datamgr.get_reactionners()
    receivers = app.datamgr.get_receivers()
    pollers = app.datamgr.get_pollers()

    logger.debug("[WebUI-system] schedulers: %s", schedulers)
    logger.debug("[WebUI-system] brokers: %s", brokers)
    logger.debug("[WebUI-system] reactionners: %s", reactionners)
    logger.debug("[WebUI-system] receivers: %s", receivers)
    logger.debug("[WebUI-system] pollers: %s", pollers)

    wid = app.request.query.get('wid', 'widget_system_' + str(int(time.time())))
    collapsed = (app.request.query.get('collapsed', 'False') == 'True')

    options = {}

    return {
        'wid': wid, 'collapsed': collapsed, 'options': options,
        'base_url': '/widget/system', 'title': 'System Information',
        'schedulers': schedulers, 'brokers': brokers, 'reactionners': reactionners,
        'receivers': receivers, 'pollers': pollers,
    }


widget_desc = """
<h4>System state</h4>
Show an aggregated view of all Shinken daemons.
"""

pages = {
    system_parameters: {
        'name': 'Parameters', 'route': '/parameters', 'view': 'parameters',
        'static': True
    },
    system_page: {
        'name': 'System', 'route': '/system', 'view': 'system',
        'static': True
    },
    system_widget: {
        'name': 'wid_System', 'route': '/widget/system', 'view': 'system_widget',
        'widget': ['dashboard'],
        'widget_desc': widget_desc,
        'widget_name': 'system',
        'widget_alias': 'Framework status',
        'widget_icon': 'heartbeat',
        'widget_picture': '/static/system/img/widget_system.png',
        'static': True
    },
    alignak_parameters: {
        'name': 'AlignakParameters', 'route': '/alignak/parameters', 'view': 'alignak-parameters',
        'static': True
    },
    alignak_status: {
        'name': 'AlignakStatus', 'route': '/alignak/status', 'view': 'alignak_status'
    },
    alignak_events: {
        'name': 'AlignakEvents', 'route': '/alignak/events', 'view': 'alignak_events'
    },
}
