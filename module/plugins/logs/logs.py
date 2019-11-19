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

import os
import json
import time
import datetime

from config_parser import ConfigParser

from shinken.log import logger

# Get plugin's parameters from configuration file
params = {
    'logs_type': ['INFO', 'WARNING', 'ERROR'],
    'logs_hosts': [],
    'logs_services': []
}

# Will be populated by the UI with it's own value
app = None


def _get_logs(*args, **kwargs):
    if app.logs_module.is_available():
        return app.logs_module.get_ui_logs(*args, **kwargs)

    logger.warning("[WebUI-logs] no get history external module defined!")
    return None


# pylint: disable=global-statement
def load_config(app):
    """Load the configuration from specific parameters used in the global WebUI configuration
    :param app: the current application
    :return:
    """
    global params

    try:
        logger.info("[WebUI-logs] loading configuration...")

        # Get the WebUI configuration parameters
        app_conf = app.modconf.__dict__
        logger.debug("[WebUI-logs] configuration parameters: %s", app_conf)
        for key, value in app_conf.items():
            if not key.startswith('plugin.logs'):
                continue
            logger.info("[WebUI-logs] configuration parameter: %s = %s", key, value)

        params['time_field'] = app_conf.get('plugin.logs.time_field', 'time')

        params['date_format'] = app_conf.get('plugin.logs.date_format', 'timestamp')

        params['other_fields'] = app_conf.get('plugin.logs.other_fields', 'message')
        if isinstance(params['other_fields'], basestring):
            if ',' in params['other_fields']:
                params['other_fields'] = [item.strip() for item in params['other_fields'].split(',')]
            else:
                params['other_fields'] = [params['other_fields']]

        params['logs_type'] = app_conf.get('plugin.logs.types', ['INFO', 'WARNING', 'ERROR'])
        if isinstance(params['logs_type'], basestring):
            if ',' in params['logs_type']:
                params['logs_type'] = [item.strip() for item in params['logs_type'].split(',')]
            else:
                params['logs_type'] = [params['logs_type']]

        params['logs_hosts'] = app_conf.get('plugin.logs.hosts', [])
        if isinstance(params['logs_hosts'], basestring):
            if ',' in params['logs_hosts']:
                params['logs_hosts'] = [item.strip() for item in params['logs_hosts'].split(',')]
            else:
                params['logs_hosts'] = [params['logs_hosts']]

        params['logs_services'] = app_conf.get('plugin.logs.services', [])
        if isinstance(params['logs_services'], basestring):
            if ',' in params['logs_services']:
                params['logs_services'] = [item.strip() for item in params['logs_services'].split(',')]
            else:
                params['logs_services'] = [params['logs_services']]

        logger.info("[WebUI-logs] configuration, timestamp field: %s", params['time_field'])
        logger.info("[WebUI-logs] configuration, date format: %s", params['date_format'])
        logger.info("[WebUI-logs] configuration, other fields: %s", params['other_fields'])
        logger.info("[WebUI-logs] configuration, fetching types: %s", params['logs_type'])
        logger.info("[WebUI-logs] configuration, hosts: %s", params['logs_hosts'])
        logger.info("[WebUI-logs] configuration, services: %s", params['logs_services'])

        logger.info("[WebUI-logs] configuration loaded.")
        return True
    except Exception as exp:
        logger.warning("[WebUI-logs] configuration exception: %s", str(exp))
        logger.error("[WebUI-logs] traceback: %s", traceback.format_exc())
        return False


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
        logger.debug("[WebUI-logs] - host : %s", host)
        params['logs_hosts'].append(host)

    app.bottle.redirect("/logs")


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
        logger.debug("[WebUI-logs] - service : %s", service)
        params['logs_services'].append(service)

    app.bottle.redirect("/logs")


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
        logger.debug("[WebUI-logs] - log type : %s", log_type)
        params['logs_type'].append(log_type)

    app.bottle.redirect("/logs")


def get_history():
    user = app.request.environ['USER']

    filters = dict()

    service = app.request.query.get('service', None)
    host = app.request.query.get('host', None)

    if host:
        if service:
            _ = app.datamgr.get_element(host + '/' + service, user) or app.redirect404()
        else:
            _ = app.datamgr.get_element(host, user) or app.redirect404()
    else:
        _ = user.is_administrator() or app.redirect403()

    if service:
        filters['service_description'] = service

    if host:
        filters['host_name'] = host

    logclass = app.request.query.get('logclass', None)
    if logclass is not None:
        filters['logclass'] = int(logclass)

    command_name = app.request.query.get('commandname', None)
    if command_name is not None:
        try:
            command_name = json.loads(command_name)
        except Exception:
            pass
        filters['command_name'] = command_name

    limit = int(app.request.query.get('limit', 100))
    offset = int(app.request.query.get('offset', 0))

    logs = _get_logs(filters=filters, limit=limit, offset=offset, time_field=params['time_field'])

    return {
        'time_field': params['time_field'],
        'other_fields': params['other_fields'],
        'records': logs
    }


# :TODO:maethor:171017: This function should be merge in get_history
def get_global_history():
    user = app.request.environ['USER']
    _ = user.is_administrator() or app.redirect403()

    midnight_timestamp = time.mktime(datetime.date.today().timetuple())

    # Date search range
    range_start = int(app.request.query.get('range_start', midnight_timestamp))
    search_range_start = range_start
    range_end = int(app.request.query.get('range_end', midnight_timestamp + 86399))
    search_range_end = range_end
    if params['date_format'] in ['datetime']:
        search_range_start = datetime.datetime.fromtimestamp(range_start)
        search_range_end = datetime.datetime.fromtimestamp(range_end)

    logger.debug("[WebUI-logs] get_global_history, range: %d - %d", range_start, range_end)

    filters = {}
    if params['logs_type'] and params['logs_type'][0]:
        filters = {'type': {'$in': params['logs_type']}}

    # logs is a pymongo Cursor object
    logs = _get_logs(filters=filters, range_start=search_range_start, range_end=search_range_end,
                     time_field=params['time_field'])
    logger.info("[WebUI-logs] got %d records.", logs.count())

    message = ""
    if logs is None:
        message = "No module configured to get Shinken logs from database!"

    return {
        'records': logs,
        'time_field': params['time_field'],
        'other_fields': params['other_fields'],
        'params': params,
        'message': message,
        'range_start': range_start, 'range_end': range_end
    }


pages = {
    get_global_history: {
        'name': 'History', 'route': '/logs',
        'view': 'logs',
        'static': True
    },
    get_history: {
        'name': 'HistoryHost', 'route': '/logs/inner',
        'view': 'history',
        'static': True
    },
    form_hosts_list: {
        'name': 'GetHostsList', 'route': '/logs/hosts_list',
        'view': 'form_hosts_list',
        'static': True
    },
    set_hosts_list: {
        'name': 'SetHostsList', 'route': '/logs/set_hosts_list',
        'view': 'logs', 'method': 'POST'
    },
    form_services_list: {
        'name': 'GetServicesList', 'route': '/logs/services_list',
        'view': 'form_services_list',
        'static': True
    },
    set_services_list: {
        'name': 'SetServicesList', 'route': '/logs/set_services_list',
        'view': 'logs', 'method': 'POST'
    },
    form_logs_type_list: {
        'name': 'GetLogsTypeList', 'route': '/logs/logs_type_list',
        'view': 'form_logs_type_list',
        'static': True
    },
    set_logs_type_list: {
        'name': 'SetLogsTypeList', 'route': '/logs/set_logs_type_list',
        'view': 'logs', 'method': 'POST'
    }
}
