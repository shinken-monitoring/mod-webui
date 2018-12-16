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

from shinken.log import logger

# Will be populated by the UI with it's own value
app = None


def system_parameters():
    user = app.request.environ['USER']
    _ = user.is_administrator() or app.redirect403()

    configs = app.datamgr.get_configs()
    if configs:
        configs = sorted(vars(configs[0]).iteritems())
        return {'configs': configs}

    return {'configs': None}


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
    }
}
