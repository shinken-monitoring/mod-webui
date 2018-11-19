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
        'widget_picture': '/static/system/img/widget_system.png',
        'static': True
    }
}
