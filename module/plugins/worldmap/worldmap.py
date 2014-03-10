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

from shinken.log import logger

### Will be populated by the UI with it's own value
app = None

# Get plugin's parameters from configuration file
params = {}

import os,sys
from webui import config_parser
try:
    currentdir = os.path.dirname(os.path.realpath(__file__))
    configuration_file = "%s/%s" % (currentdir, 'plugin.cfg')
    logger.debug("Plugin configuration file: %s" % (configuration_file))
    scp = config_parser('#', '=')
    params = scp.parse_config(configuration_file)

    params['default_Lat'] = float(params['default_Lat'])
    params['default_Lng'] = float(params['default_Lng'])
    params['default_zoom'] = int(params['default_zoom'])
    
    logger.debug("Plugin configuration, default position: %s / %s" % (params['default_Lat'], params['default_Lng']))
    logger.debug("Plugin configuration, default zoom level: %d" % (params['default_zoom']))
except Exception, exp:
    logger.warning("Plugin configuration file (%s) not available: %s" % (configuration_file, str(exp)))


def checkauth():
    user = app.get_user_auth()

    if not user:
        app.bottle.redirect("/user/login")
    else:
        return user


# Our page. If the user call /worldmap
def get_page():
    user = checkauth()    

    # We are looking for hosts that got valid GPS coordinates,
    # and we just give them to the template to print them.
    valid_hosts = []
    for h in app.datamgr.get_hosts():
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
                print "Host invalid coordinates !"
                continue
            # Look for good range, lat/long must be between -180/180
            if -180 <= _lat <= 180 and -180 <= _lng <= 180:
                valid_hosts.append(h)

    # So now we can just send the valid hosts to the template
    return {'app': app, 'user': user, 'params': params, 'hosts' : valid_hosts}


# We export our properties to the webui
pages = {get_page: {'routes': ['/worldmap'], 'view': 'worldmap', 'static': True}}
