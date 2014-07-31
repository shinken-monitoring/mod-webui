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
### Will be populated by the UI with it's own value
app = None

import time

from shinken.util import safe_print

# Get plugin's parameters from configuration file
params = {}
# Tabs to be displayed or not ...
params['tab_info'] = 'yes'
params['tab_additional'] = 'yes'
params['tab_commands'] = 'yes'
params['tab_gesture'] = 'no'
params['tab_custom_views'] = 'yes'
params['tab_impacts'] = 'yes'
params['tab_comments'] = 'yes'
params['tab_downtimes'] = 'yes'
params['tab_timeline'] = 'yes'
params['tab_graphs'] = 'yes'
params['tab_depgraph'] = 'yes'
params['tab_history'] = 'yes'

params['cfg_nb_impacts'] = 5

def load_cfg():
    global params
    
    import os,sys
    from config_parser import config_parser
    from shinken.log import logger
    plugin_name = os.path.splitext(os.path.basename(__file__))[0]
    try:
        currentdir = os.path.dirname(os.path.realpath(__file__))
        configuration_file = "%s/%s" % (currentdir, 'plugin.cfg')
        logger.debug("Plugin configuration file: %s" % (configuration_file))
        scp = config_parser('#', '=')
        params = scp.parse_config(configuration_file)

        logger.debug("WebUI plugin '%s', configuration loaded." % (plugin_name))
        return True
    except Exception, exp:
        logger.warning("WebUI plugin '%s', configuration file (%s) not available: %s" % (plugin_name, configuration_file, str(exp)))
        return False

def checkauth():
    user = app.get_user_auth()

    if not user:
        app.bottle.redirect("/user/login")
    else:
        return user

def reload_cfg():
    load_cfg()
    app.bottle.redirect("/config")


# Main impacts view
def show_host(name):
    user = checkauth()

    # Ok we are in a detail page but the user ask for a specific search
    search = app.request.GET.get('global_search', None)
    if search:
        new_h = app.datamgr.get_host(search)
        if new_h:
            app.bottle.redirect("/host/" + search)

    # Get graph data. By default, show last 4 hours
    now = int(time.time())
    graphstart = int(app.request.GET.get('graphstart', str(now - 4*3600)))
    graphend = int(app.request.GET.get('graphend', str(now)))

    # Ok, we can lookup it
    h = app.datamgr.get_host(name)
    return {'app': app, 'elt': h, 'valid_user': True, 'user': user, 'params': params, 'graphstart': graphstart,
            'graphend': graphend}


def show_service(hname, desc):
    user = checkauth()

    # Ok we are in a detail page but the user ask for a specific search
    search = app.request.GET.get('global_search', None)
    if search:
        new_h = app.datamgr.get_host(search)
        if new_h:
            app.bottle.redirect("/host/" + search)

    # Get graph data. By default, show last 4 hours
    now = int(time.time())
    graphstart = int(app.request.GET.get('graphstart', str(now - 4*3600)))
    graphend = int(app.request.GET.get('graphend', str(now)))

    # Ok, we can lookup it :)
    s = app.datamgr.get_service(hname, desc)
    return {'app': app, 'elt': s, 'valid_user': True, 'user': user, 'params': params, 'graphstart': graphstart,
            'graphend': graphend}

# Load plugin configuration parameters
load_cfg()

pages = {
        reload_cfg: {'routes': ['/reload/eltdetail'], 'view': 'groups', 'static': True},
        show_host: {'routes': ['/host/:name'], 'view': 'eltdetail', 'static': True},
        show_service: {'routes': ['/service/:hname/:desc#.+#'], 'view': 'eltdetail', 'static': True},
        }
