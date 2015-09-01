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
import random

### Will be populated by the UI with it's own value
app = None

# :TODO:maethor:150821: These function needs huge rewrite.

def depgraph_host(name):
    # Ok we are in a detail page but the user ask for a specific search
    search = app.request.GET.get('global_search', '')
    loop = bool(int(app.request.GET.get('loop', '0')))
    loop_time = int(app.request.GET.get('loop_time', '10'))

    user = app.request.environ['USER']
    
    if search:
        new_h = app.datamgr.get_host(search, user)
        if new_h:
            app.bottle.redirect("/depgraph/" + search)

    else:
        # Ok look for the first host we can find
        hosts = app.datamgr.get_hosts(user)
        for h in hosts:
            search = h.get_name()
            break

    h = app.datamgr.get_host(name, user) or app.redirect404()
    
    graphId = "graph_%d" % random.randint(1, 9999)

    return {'elt': h, 'graphId': graphId, 'loop' : loop, 'loop_time' : loop_time}


def depgraph_service(hname, desc):
    loop = bool(int(app.request.GET.get('loop', '0')))
    loop_time = int(app.request.GET.get('loop_time', '10'))

    user = app.request.environ['USER']

    # Ok we are in a detail page but the user ask for a specific search
    search = app.request.GET.get('global_search', None)
    if search:
        new_h = app.datamgr.get_host(search, user)
        if new_h:
            app.bottle.redirect("/depgraph/" + search)

    s = app.datamgr.get_service(hname, desc, user)
    
    graphId = "graph_%d" % random.randint(1, 9999)

    return {'elt': s, 'graphId': graphId, 'loop' : loop, 'loop_time' : loop_time}


def get_depgraph_widget():
    search = app.request.GET.get('search', '').strip()
    user = app.request.environ['USER']

    if not search:
        # Ok look for the first host we can find
        hosts = app.datamgr.get_hosts(user)
        for h in hosts:
            search = h.get_name()
            break

    elt = app.datamgr.get_element(search, user) or app.redirect404() 

    wid = app.request.GET.get('wid', 'widget_depgraph_' + str(int(time.time())))
    collapsed = (app.request.GET.get('collapsed', 'False') == 'True')

    options = {'search': {'value': search, 'type': 'hst_srv', 'label': 'Search an element'},
               }

    title = 'Relation graph for %s' % search

    graphId = "graph_%d" % random.randint(1, 9999)

    return {'elt': elt, 'graphId': graphId, 
            'wid': wid, 'collapsed': collapsed, 'options': options, 'base_url': '/widget/depgraph', 'title': title,
            }


def get_depgraph_inner(name):
    user = app.request.environ['USER']
    elt = app.datamgr.get_element(name, user) or app.redirect404()
    
    graphId = "graph_%d" % random.randint(1, 9999)

    return {'elt': elt, 'graphId': graphId}

widget_desc = '''<h4>Relation graph</h4>
Show a graph of an object relations
'''

pages = {
    depgraph_host:          {'routes': ['/depgraph/:name'], 'view': 'depgraph', 'static': True},
    depgraph_service:       {'routes': ['/depgraph/:hname/:desc'], 'view': 'depgraph', 'static': True},
    get_depgraph_widget:    {'routes': ['/widget/depgraph'], 'view': 'widget_depgraph', 'static': True, 'widget': ['dashboard'], 'widget_desc': widget_desc, 'widget_name': 'depgraph', 'widget_picture': '/static/depgraph/img/widget_depgraph.png'},
    get_depgraph_inner:     {'routes': ['/inner/depgraph/:name#.+#'], 'view': 'inner_depgraph', 'static': True},
}
