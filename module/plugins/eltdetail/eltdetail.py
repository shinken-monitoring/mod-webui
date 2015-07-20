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

# Get plugin's parameters from configuration file
params = {}
# Tabs to be displayed or not ...
params['tabs'] = ['information', 'additional', 'configuration', 'custom_views', 'impacts', 'comments', 'downtimes', 'metrics', 'graphs', 'depgraph', 'history', 'availability', 'helpdesk']
params['cfg_nb_impacts'] = 5

# Main impacts view
def show_host(host_name):
    # Ok we are in a detail page but the user ask for a specific search
    if host_name.startswith('all'):  # :DEBUG:maethor:150718: WHAT ?
        search = ' '.join(app.request.GET.getall('search')) or ""
        app.bottle.redirect('/'+host_name+'?search='+search)

    # Get graph data. By default, show last 4 hours
    now = int(time.time())
    graphstart = int(app.request.GET.get('graphstart', str(now - 4*3600)))
    graphend = int(app.request.GET.get('graphend', str(now)))

    # Ok, we can lookup it
    h = app.datamgr.get_host(host_name)
    return {'elt': h, 'valid_user': True, 'params': params, 'graphstart': graphstart,
            'graphend': graphend}


def show_service(host_name, service):
    # Ok we are in a detail page but the user ask for a specific search
    if host_name.startswith('all'):  # :DEBUG:maethor:150718: WHAT ?
        search = ' '.join(app.request.GET.getall('search')) or ""
        app.bottle.redirect('/'+host_name+'?search='+search)

    # Get graph data. By default, show last 4 hours
    now = int(time.time())
    graphstart = int(app.request.GET.get('graphstart', str(now - 4*3600)))
    graphend = int(app.request.GET.get('graphend', str(now)))

    # Ok, we can lookup it :)
    s = app.datamgr.get_service(host_name, service)
    return {'elt': s, 'valid_user': True, 'params': params, 'graphstart': graphstart,
            'graphend': graphend}

pages = {
        # reload_cfg: {'routes': ['/reload/eltdetail'], 'view': 'groups', 'static': True},
        show_host: {'routes': ['/host/:host_name'], 'view': 'eltdetail', 'static': True},
        show_service: {'routes': ['/service/:host_name/:service#.+#'], 'view': 'eltdetail', 'static': True},
        }

