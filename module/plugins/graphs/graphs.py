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
import requests
import random
from shinken.log import logger


### Will be populated by the UI with it's own value
app = None


def proxy_graph():
    ''' This route proxies graphs returned by the graph module.
        The pnp4nagios/graphite image url have to be in the GET attributes,
        encoded with urlencode. The graphs metamodule takes care of that. This
        route should not be usefull anywhere else.
    '''
    url = app.request.GET.get('url', '')
    try:
        r = requests.get(url)
        if r.status_code != 200:
            logger.error("[WebUI-graph] Image URL not found: %s", url)
            raise Exception("Image not found")
    except Exception as e:
        app.redirect404(e)
    app.bottle.response.content_type = str(r.headers['content-type'])
    return r.content


# Our page
def get_graphs_widget():
    user = app.request.environ['USER']
    search = app.request.GET.get('search', '') or app.datamgr.get_hosts(user)[0].host_name
    elt = app.datamgr.get_element(search, user) or app.redirect(404)

    duration = app.request.GET.get('duration', '86400')
    duration_list = {
        '1h'   : '3600',
        '1d'   : '86400',
        '7d'   : '604800',
        '30d'  : '2592000',
        '365d' : '31536000' ,
    }

    wid = app.request.query.get('wid', 'widget_graphs_' + str(int(time.time())))
    collapsed = (app.request.query.get('collapsed', 'False') == 'True')

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

    graphsId = "graphs_%d" % random.randint(1, 9999)

    return {
        'elt': elt,
        'wid': wid,
        'graphsId': graphsId,
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
    proxy_graph: {
        'name': 'Graph', 'route': '/graph', 'view': 'graph', 'static': True
    },
    get_graphs_widget: {
        'name': 'wid_Graph', 'route': '/widget/graphs', 'view': 'widget_graphs', 'static': True, 'widget': ['dashboard'], 'widget_desc': widget_desc, 'widget_name': 'graphs', 'widget_picture': '/static/graphs/img/widget_graphs.png'
    }
}
