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

# Mongodb lib
try:
    import pymongo
    from pymongo.connection import Connection
    import gridfs
except ImportError:
    Connection = None


### Will be populated by the UI with it's own value
app = None

# Get plugin's parameters from configuration file (not useful currently but future ideas ...)
params = {}
params['fake'] = "localhost"

import os,sys
from config_parser import config_parser
plugin_name = os.path.splitext(os.path.basename(__file__))[0]
try:
    currentdir = os.path.dirname(os.path.realpath(__file__))
    configuration_file = "%s/%s" % (currentdir, 'plugin.cfg')
    logger.debug("Plugin configuration file: %s", configuration_file)
    scp = config_parser('#', '=')
    params = scp.parse_config(configuration_file)

    # mongo_host = params['mongo_host']
    params['fake'] = params['fake']
    
    logger.debug("WebUI plugin '%s', configuration loaded." % (plugin_name))
    # logger.debug("Plugin %s configuration, database: %s (%s)", plugin_name, params['mongo_host'], params['mongo_port'])
except Exception, exp:
    logger.warning("WebUI plugin '%s', configuration file (%s) not available: %s", plugin_name, configuration_file, str(exp))


def checkauth():
    user = app.get_user_auth()

    if not user:
        app.bottle.redirect("/user/login")
    else:
        return user


def system_page():
    user = checkauth()    

    schedulers = app.datamgr.get_schedulers()
    brokers = app.datamgr.get_brokers()
    reactionners = app.datamgr.get_reactionners()
    receivers = app.datamgr.get_receivers()
    pollers = app.datamgr.get_pollers()

    return {'app': app, 'user': user, 'schedulers': schedulers,
            'brokers': brokers, 'reactionners': reactionners,
            'receivers': receivers, 'pollers': pollers,
            }


def system_widget():
    user = checkauth()    

    schedulers = app.datamgr.get_schedulers()
    brokers = app.datamgr.get_brokers()
    reactionners = app.datamgr.get_reactionners()
    receivers = app.datamgr.get_receivers()
    pollers = app.datamgr.get_pollers()

    wid = app.request.GET.get('wid', 'widget_system_' + str(int(time.time())))
    collapsed = (app.request.GET.get('collapsed', 'False') == 'True')
    print "SYSTEM COLLAPSED?", collapsed, type(collapsed)

    got_childs = (app.request.GET.get('got_childs', 'False') == 'True')
    key = app.request.GET.get('key', 1)

    options = {}

    return {'app': app, 'user': user, 'wid': wid,
            'collapsed': collapsed, 'options': options,
            'base_url': '/widget/system', 'title': 'System Information',
            'schedulers': schedulers,
            'brokers': brokers, 'reactionners': reactionners,
            'receivers': receivers, 'pollers': pollers,
            }



widget_desc = '''<h4>System state</h4>
Show an aggregated view of all Shinken daemons.
'''

pages = {system_page: {'routes': ['/system', '/system/'], 'view': 'system', 'static': True},
         system_widget: {'routes': ['/widget/system'], 'view': 'system_widget', 'static': True, 'widget': ['dashboard'], 'widget_desc': widget_desc, 'widget_name': 'system', 'widget_picture': '/static/system/img/widget_system.png'},
         }
