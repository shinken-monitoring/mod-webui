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

### Will be populated by the UI with it's own value
app = None

from shinken.log import logger

import time
import re
import random

try:
    import json
except ImportError:
    # For old Python version, load
    # simple json (it can be hard json?! It's 2 functions guy!)
    try:
        import simplejson as json
    except ImportError:
        print "Error: you need the json or simplejson module"
        raise

### Plugin's parameters
params = {}

# Hook called by WebUI module once the plugin is loaded ...
def load_config(app):
    global params

    logger.info("[WebUI-worldmap] loading configuration ...")

    properties = {
            'worldmap-zoom': '{"default_zoom": 16}',
            'worldmap-lng': '{"default_lng": 5.080625}',
            'worldmap-lat': '{"default_lat": 45.054148}',
            'worldmap-hosts': '{"hosts_level": [1,2,3,4,5]}',
            'worldmap-services': '{"services_level": [1,2,3,4,5]}',
            'worldmap-layer': '{"layer": ""}',
            }

    for p, default in properties.items():
        params.update(json.loads(app.prefs_module.get_ui_common_preference(p, default)))

    logger.info("[WebUI-worldmap] configuration loaded.")
    logger.info("[WebUI-worldmap] configuration, params: %s", params)


def search_hosts_with_coordinates(search, user):
    logger.debug("[WebUI-worldmap] search parameters '%s'", search)
    items = app.datamgr.search_hosts_and_services(search, user, get_impacts=True)
    
    # We are looking for hosts with valid GPS coordinates,
    # and we just give them to the template to print them.
    # :COMMENT:maethor:150810: If you want default coordinates, just put them
    # in the 'generic-host' template.
    valid_hosts = []
    for h in items:
        logger.debug("[WebUI-worldmap] found host '%s'", h.get_name())
        
        if h.business_impact not in params['hosts_level']:
            continue

        try:
            _lat = float(h.customs.get('_LOC_LAT', None))
            _lng = float(h.customs.get('_LOC_LNG', None))
            # lat/long must be between -180/180
            if not (-180 <= _lat <= 180 and -180 <= _lng <= 180):
                raise Exception()
        except Exception:
            logger.debug("[WebUI-worldmap] host '%s' has invalid GPS coordinates", h.get_name())
            continue
            
        logger.debug("[WebUI-worldmap] host '%s' located on worldmap: %f - %f", h.get_name(), _lat, _lng)
        valid_hosts.append(h)

    return valid_hosts

# Our page. If the user call /worldmap
def show_worldmap():
    user = app.request.environ['USER']

    # Apply search filter if exists ...
    search = app.request.query.get('search', "type:host")

    # So now we can just send the valid hosts to the template
    return {'search_string': search, 'params': params,
            'mapId': 'hostsMap', 
            'hosts': search_hosts_with_coordinates(search, user)}


def show_worldmap_widget():
    user = app.request.environ['USER']

    wid = app.request.GET.get('wid', 'widget_worldmap_' + str(int(time.time())))
    collapsed = (app.request.GET.get('collapsed', 'False') == 'True')

    # We want to limit the number of elements, The user will be able to increase it
    nb_elements = max(0, int(app.request.GET.get('nb_elements', '10')))
    refine_search = app.request.GET.get('search', '')
    
    # Apply search filter if exists ...
    search = app.request.query.get('search', "type:host")

    items = search_hosts_with_coordinates(search, user)
    
    # Ok, if needed, apply the widget refine search filter
    if refine_search:
        pat = re.compile(refine_search, re.IGNORECASE)
        items = [ i for i in items if pat.search(i.get_full_name()) ]

    items = items[:nb_elements]

    options = {'search': {'value': refine_search, 'type': 'text', 'label': 'Filter by name'},
               'nb_elements': {'value': nb_elements, 'type': 'int', 'label': 'Max number of elements to show'},
               }

    title = 'Worldmap'
    if refine_search:
        title = 'Worldmap (%s)' % refine_search

    mapId = "map_%d" % random.randint(1, 9999)

    return {'wid': wid, 'mapId': mapId, 
            'collapsed': collapsed, 'options': options,
            'base_url': '/widget/worldmap', 'title': title,
            'params': params, 'hosts' : items
            }


widget_desc = '''<h4>Worldmap</h4>
Show a map of all monitored hosts.
'''

# We export our properties to the webui
pages = {
    show_worldmap: {'routes': ['/worldmap'], 'view': 'worldmap', 'static': True},
    show_worldmap_widget: {'routes': ['/widget/worldmap'], 'view': 'worldmap_widget', 'static': True, 'widget': ['dashboard'], 'widget_desc': widget_desc, 'widget_name': 'worldmap', 'widget_picture': '/static/worldmap/img/widget_worldmap.png'},
}
