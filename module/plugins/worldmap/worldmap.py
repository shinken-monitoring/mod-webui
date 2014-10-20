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

### Will be populated by the UI with it's own value
app = None

# Get plugin's parameters from configuration file
params = {}

import os,sys
from config_parser import config_parser
plugin_name = os.path.splitext(os.path.basename(__file__))[0]
try:
    currentdir = os.path.dirname(os.path.realpath(__file__))
    configuration_file = "%s/%s" % (currentdir, 'plugin.cfg')
    logger.debug("Plugin configuration file: %s" % (configuration_file))
    scp = config_parser('#', '=')
    params = scp.parse_config(configuration_file)

    params['only_geo_hosts'] = bool(params['only_geo_hosts'])
    params['default_Lat'] = float(params['default_Lat'])
    params['default_Lng'] = float(params['default_Lng'])
    params['default_zoom'] = int(params['default_zoom'])
    
    logger.debug("WebUI plugin '%s', configuration loaded." % (plugin_name))
    logger.debug("Plugin configuration, default position: %s / %s" % (params['default_Lat'], params['default_Lng']))
    logger.debug("Plugin configuration, default zoom level: %d" % (params['default_zoom']))
except Exception, exp:
    logger.warning("WebUI plugin '%s', configuration file (%s) not available: %s" % (plugin_name, configuration_file, str(exp)))


def checkauth():
    user = app.get_user_auth()

    if not user:
        app.bottle.redirect("/user/login")
    else:
        return user

def _valid_coords(hostname, lat, lng):

    COORD_MAX = 180
    COORD_MIN = -180

    if not lat and not lng:
        return False

    logger.debug("[worldmap] {}: {},{}".format(hostname, lat, lng))

    try:
        # Maybe the customs are set, but with invalid float?
        lat = float(lat)
        lng = float(lng)
    except ValueError:
        logger.warning("[worldmap] Host {} has invalid coordinates".format(hostname))
        return False

    if lat >= COORD_MAX or lat <= COORD_MIN:
        logger.warning("[worldmap] Host {} has a latitude out of range".format(hostname))
        return False

    if lng >= COORD_MAX or lng <= COORD_MIN:
        logger.warning("[worldmap] Host {} has a longitude out of range".format(hostname))
        return False

    return True

def _get_coords(host):
    lat = host.customs.get('_LOC_LAT', host.customs.get('_LAT'))
    lng = host.customs.get('_LOC_LNG', host.customs.get('_LONG'))
    if not params['only_geo_hosts']:
        lat = params['default_Lat'] if not lat else lat
        lng = params['default_Lng'] if not lng else lng
    return (lat, lng)

# Our page. If the user call /worldmap
def get_page():
    user = checkauth()    

    # We are looking for hosts that got valid GPS coordinates,
    # and we just give them to the template to print them.
    valid_hosts = []
    for h in app.datamgr.get_hosts():
        (_lat, _lng) = _get_coords(h)
        if _valid_coords(h.get_name(), _lat, _lng):
            h.customs['_LOC_LAT'] = _lat
            h.customs['_LOC_LNG'] = _lng
            valid_hosts.append(h)

    # So now we can just send the valid hosts to the template
    return {'app': app, 'user': user, 'params': params, 'hosts' : valid_hosts}


def worldmap_widget():
    user = checkauth()    

    wid = app.request.GET.get('wid', 'widget_system_' + str(int(time.time())))
    collapsed = (app.request.GET.get('collapsed', 'False') == 'True')

    options = {}

    # We are looking for hosts that got valid GPS coordinates,
    # and we just give them to the template to print them.
    valid_hosts = []
    for h in app.datamgr.get_hosts():
        (_lat, _lng) = _get_coords(h)
        if _valid_coords(h.get_name(), _lat, _lng):
            h.customs['_LOC_LAT'] = _lat
            h.customs['_LOC_LNG'] = _lng
            valid_hosts.append(h)
                
    return {'app': app, 'user': user, 'wid': wid,
            'collapsed': collapsed, 'options': options,
            'base_url': '/widget/worldmap', 'title': 'Worldmap',
            'params': params, 'hosts' : valid_hosts
            }


widget_desc = '''<h4>Worldmap</h4>
Show a map of all monitored hosts.
'''

# We export our properties to the webui
pages = {get_page: {'routes': ['/worldmap'], 'view': 'worldmap', 'static': True}, 
         worldmap_widget: {'routes': ['/widget/worldmap'], 'view': 'worldmap_widget', 'static': True, 'widget': ['dashboard'], 'widget_desc': widget_desc, 'widget_name': 'worldmap', 'widget_picture': '/static/worldmap/img/widget_worldmap.png'},
}
