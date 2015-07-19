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
import time


### Will be populated by the UI with it's own value
app = None


# Our page
def get_graphs_widget():
    search = app.request.GET.get('search', '')
    duration = app.request.GET.get('duration', '86400')
    duration_list = {
        '1h'   : '3600',
        '1d'   : '86400',
        '7d'   : '604800',
        '30d'  : '2592000',
        '365d' : '31536000' ,
    }

    if not search:
        search = 'localhost'

    # Look for an host or a service?
    elt = None
    if not '/' in search:
        elt = app.datamgr.get_host(search)
    else:
        parts = search.split('/', 1)
        elt = app.datamgr.get_service(parts[0], parts[1])

    wid = app.request.GET.get('wid', 'widget_graphs_' + str(int(time.time())))
    collapsed = (app.request.GET.get('collapsed', 'False') == 'True')

    options = {
        'search': {
            'value': search,
            'type': 'hst_srv',
            'label': 'Element name'
        },
        'duration': {
            'value': duration,
            'values':  duration_list,
            'type': 'select',
            'label': 'Duration'
        },
    }

    title = 'Element graphs for %s' % search

    return {
        'elt': elt,
        'wid': wid,
        'collapsed': collapsed,
        'options': options,
        'base_url': '/widget/graphs',
        'title': title,
        'duration': int(duration),
    }

widget_desc = '''<h4>Graphs</h4>
Show the perfdata graph
'''

pages = {
    get_graphs_widget: {'routes': ['/widget/graphs'], 'view': 'widget_graphs', 'static': True, 'widget': ['dashboard'], 'widget_desc': widget_desc, 'widget_name': 'graphs', 'widget_picture': '/static/graphs/img/widget_graphs.png'},
    }
