#!/usr/bin/python
# -*- coding: utf-8 -*-
# Copyright (C) 2009-2012:
#    Gabes Jean, naparuba@gmail.com
#    Mohier Frédéric frederic.mohier@gmail.com
#    Karfusehr Andreas, frescha@unitedseed.de
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
from shinken.misc.filter import only_related_to

### Will be populated by the UI with it's own value
app = None

# Get plugin's parameters from configuration file
params = {}

def load_cfg():
    global params


    import os,sys
    from webui.config_parser import config_parser
    plugin_name = os.path.splitext(os.path.basename(__file__))[0]
    try:
        currentdir = os.path.dirname(os.path.realpath(__file__))
        configuration_file = "%s/%s" % (currentdir, 'plugin.cfg')
        logger.debug("Plugin configuration file: %s" % (configuration_file))
        scp = config_parser('#', '=')
        params = scp.parse_config(configuration_file)

        params['default_Lat'] = float(params['default_Lat'])
        params['default_Lng'] = float(params['default_Lng'])
        params['default_zoom'] = int(params['default_zoom'])

        params['map_hostsLevel'] = [int(item) for item in params['map_hostsLevel'].split(',')]
        params['map_hostsShow'] = [item for item in params['map_hostsShow'].split(',')]
        params['map_hostsHide'] = [item for item in params['map_hostsHide'].split(',')]
        params['map_servicesLevel'] = [int(item) for item in params['map_servicesLevel'].split(',')]
        params['map_servicesHide'] = [item for item in params['map_servicesHide'].split(',')]
        
        logger.info("[webui-worldmap] configuration loaded.")
        logger.debug("[webui-worldmap] configuration, default position and zoom level: %s / %s - zoom: %s", params['default_Lat'], params['default_Lng'], params['default_zoom'])
        logger.debug("[webui-worldmap] configuration, map hosts level: %s", params['map_hostsLevel'])
        logger.debug("[webui-worldmap] configuration, map hosts always shown: %s", params['map_hostsShow'])
        logger.debug("[webui-worldmap] configuration, map hosts always hidden: %s", params['map_hostsHide'])
        logger.debug("[webui-worldmap] configuration, map services level: %s", params['map_servicesLevel'])
        logger.debug("[webui-worldmap] configuration, map services hide: %s", params['map_servicesHide'])
    except Exception, exp:
        logger.warning("[webui-worldmap] configuration file (%s) not available: %s", configuration_file, str(exp))


def reload_cfg():
    load_cfg()
    app.bottle.redirect("/config")


# Our page. If the user call /worldmap
def show_worldmap():
    user = app.check_user_authentication()

    # We are looking for hosts with valid GPS coordinates,
    # and we just give them to the template to print them.
    valid_hosts = []
    for h in app.get_hosts(user):
        logger.debug("[webui-worldmap] found host '%s'", h.get_name())
        
        # Filter hosts
        if h.get_name() in params['map_hostsHide']:
            continue
            
        if h.get_name() not in params['map_hostsShow'] and h.business_impact not in params['map_hostsLevel']:
            continue
        
        _lat = h.customs.get('_LOC_LAT', params['default_Lat'])
        _lng = h.customs.get('_LOC_LNG', params['default_Lng'])

        try:
            print "Host", h.get_name(), _lat, _lng
        except:
            pass
        if _lat and _lng:
            try:
                # Maybe the customs are set, but with invalid float?
                _lat = float(_lat)
                _lng = float(_lng)
            except ValueError:
                logger.debug("[webui-worldmap] host '%s' has invalid GPS coordinates (not float)", h.get_name())
                continue
            # Look for good range, lat/long must be between -180/180
            if -180 <= _lat <= 180 and -180 <= _lng <= 180:
                logger.debug("[webui-worldmap] host '%s' located on worldmap: %f - %f", h.get_name(), _lat, _lng)
                valid_hosts.append(h)

    # So now we can just send the valid hosts to the template
    return {'app': app, 'user': user, 'params': params, 'hosts': valid_hosts}


def show_worldmap_widget():
    user = check_user_authentication()

    wid = app.request.GET.get('wid', 'widget_worldmap_' + str(int(time.time())))
    collapsed = (app.request.GET.get('collapsed', 'False') == 'True')

    options = {}

    # We are looking for hosts that got valid GPS coordinates,
    # and we just give them to the template to print them.
    valid_hosts = []
    for h in app.get_hosts(user):
        # Filter hosts
        if h.get_name() in params['map_hostsHide']:
            continue
            
        if h.get_name() not in params['map_hostsShow'] and h.business_impact not in params['map_hostsLevel']:
            continue
        
        _lat = h.customs.get('_LOC_LAT', params['default_Lat'])
        _lng = h.customs.get('_LOC_LNG', params['default_Lng'])

        try:
            print "Host", h.get_name(), _lat, _lng
        except:
            pass
        if _lat and _lng:
            try:
                # Maybe the customs are set, but with invalid float?
                _lat = float(_lat)
                _lng = float(_lng)
            except ValueError:
                logger.debug("[webui-worldmap] host '%s' has invalid GPS coordinates (not float)", h.get_name())
                continue
            # Look for good range, lat/long must be between -180/180
            if -180 <= _lat <= 180 and -180 <= _lng <= 180:
                valid_hosts.append(h)

    return {'app': app, 'user': user, 'wid': wid,
            'collapsed': collapsed, 'options': options,
            'base_url': '/widget/worldmap', 'title': 'Worldmap',
            'params': params, 'hosts' : valid_hosts
            }


widget_desc = '''<h4>Worldmap</h4>
Show a map of all monitored hosts.
'''

# Load plugin configuration parameters
load_cfg()

# We export our properties to the webui
pages = {
    reload_cfg: {'routes': ['/reload/worldmap']},

    show_worldmap: {'routes': ['/worldmap'], 'view': 'worldmap', 'static': True},
    show_worldmap_widget: {'routes': ['/widget/worldmap'], 'view': 'worldmap_widget', 'static': True, 'widget': ['dashboard'], 'widget_desc': widget_desc, 'widget_name': 'worldmap', 'widget_picture': '/static/worldmap/img/widget_worldmap.png'},
}
