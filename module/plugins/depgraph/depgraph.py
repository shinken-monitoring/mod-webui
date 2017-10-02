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

def get_depgraph_widget():
    search = app.request.GET.get('search', '').strip()
    user = app.request.environ['USER']

    elt = app.datamgr.get_element(search, user) or app.redirect404()

    if not search:
        # Ok look for the first host we can find
        hosts = app.datamgr.get_hosts(user)
        for h in hosts:
            search = h.get_name()
            break

    wid = app.request.query.get('wid', 'widget_depgraph_' + str(int(time.time())))
    collapsed = (app.request.query.get('collapsed', 'False') == 'True')

    options = {'search': {'value': search, 'type': 'hst_srv', 'label': 'Search an element'},
               }

    title = 'Relation graph for %s' % search

    return { 'elt': elt,
            'wid': wid, 'collapsed': collapsed, 'options': options, 'base_url': '/widget/depgraph', 'title': title,
            }

widget_desc = '''<h4>Relation graph</h4>
Displays a dependeny graph for the selected object
'''

pages = {
    get_depgraph_widget:{
        'name': 'wid_Depgraph',
        'route': '/widget/depgraph',
        'view': 'widget_depgraph',
        'static': True,
        'widget': ['dashboard'],
        'widget_desc': widget_desc,
        'widget_name': 'depgraph',
        'widget_picture': '/static/depgraph/img/widget_depgraph.png',
        'deprecated': True
    }
}
