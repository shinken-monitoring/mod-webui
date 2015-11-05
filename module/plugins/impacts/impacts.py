#!/usr/bin/python

# -*- coding: utf-8 -*-

# Copyright (C) 2009-2014:
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

# Global value that will be changed by the main app
app = None

from shinken.log import logger

def show_impacts():
    user = app.request.environ['USER']

    # Apply search filter if exists ...
    search = app.request.query.get('search', "bi:>=0 type:all isnot:ACK isnot:DOWNTIME")
    logger.debug("[WebUI-impacts] search parameters '%s'", search)

    items = app.datamgr.get_impacts(user, search)

    impacts = {}

    imp_id = 0
    for imp in items:
        imp_id += 1
        impacts[imp_id] = imp

    return {'impacts': impacts, 'page': "Impacts"}


def impacts_widget():
    d = show_impacts()

    wid = app.request.GET.get('wid', 'widget_impacts_' + str(int(time.time())))
    collapsed = (app.request.GET.get('collapsed', 'False') == 'True')

    nb_elements = max(1, int(app.request.GET.get('nb_elements', '5')))
    # Now filter for the good number of impacts to show
    new_impacts = {}
    for (k, v) in d['impacts'].iteritems():
        if k <= nb_elements:
            new_impacts[k] = v
    d['impacts'] = new_impacts

    options = {'nb_elements': {'value': nb_elements, 'type': 'int', 'label': 'Max number of elements to show'},
               }

    d.update({'wid': wid, 'collapsed': collapsed, 'options': options,
            'base_url': '/widget/impacts', 'title': 'Impacts'})

    return d

widget_desc = """
<h4>Impacts</h4>
Show an aggregated view of the most important business impacts!
"""

pages = {
    show_impacts: {'routes': ['/impacts'], 'view': 'impacts', 'name': 'Impacts', 'static': True, 'search_engine': True},
    impacts_widget: {'routes': ['/widget/impacts'], 'view': 'widget_impacts', 'static': True, 'widget': ['dashboard'], 'widget_desc': widget_desc, 'widget_name': 'impacts', 'widget_picture': '/static/impacts/img/widget_impacts.png'},
}
