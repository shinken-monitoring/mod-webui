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

from shinken.misc.sorter import hst_srv_sort, last_state_change_earlier

# Will be populated by the UI with it's own value
app = None

import time
import re


def get_page():
    app.bottle.redirect("/all?search=isnot:UP isnot:OK isnot:PENDING isnot:ACK isnot:DOWNTIME bp:>0")


def get_all():
    user = app.bottle.request.environ['USER']
    # Fetch elements per page preference for user, default is 25
    elts_per_page = app.prefs_module.get_ui_user_preference(user, 'elts_per_page', 25)

    # Fetch sound preference for user, default is 'no'
    sound_pref = app.prefs_module.get_ui_user_preference(user, 'sound', 'yes' if app.play_sound else 'no')
    sound = app.request.GET.get('sound', '')
    if sound != sound_pref and sound in ['yes', 'no']:
        app.prefs_module.set_ui_user_preference(user, 'sound', sound)
        sound_pref = sound

    # We want to limit the number of elements
    step = int(app.request.GET.get('step', elts_per_page))
    start = int(app.request.GET.get('start', '0'))
    end = int(app.request.GET.get('end', start + step))

    title = app.request.GET.get('title', 'All problems')
    
    search = ' '.join(app.request.GET.getall('search')) or ""
    items = app.datamgr.search_hosts_and_services(search, user)

    # Now sort it!
    # @mohierf: sorting is really necessary ?
    items.sort(hst_srv_sort)

    total = len(items)
    # If we overflow, came back as normal
    if start > total:
        start = 0
        end = start + step

    navi = app.helper.get_navi(total, start, step=step)
    pbs = items[start:end]

    return {'pbs': pbs, 'all_pbs': items, 'navi': navi, 'title': title, 'search_string': search, 'bookmarks': app.prefs_module.get_user_bookmarks(user), 'bookmarksro': app.prefs_module.get_common_bookmarks(), 'sound': sound_pref, 'elts_per_page': elts_per_page}


def get_pbs_widget():
    user = app.bottle.request.environ['USER']

    # We want to limit the number of elements, The user will be able to increase it
    nb_elements = max(0, int(app.request.GET.get('nb_elements', '10')))
    refine_search = app.request.GET.get('search', '')

    items = app.datamgr.search_hosts_and_services("isnot:UP isnot:OK isnot:PENDING ack:false downtime:false", user, get_impacts=False)

    # Sort it now
    items.sort(hst_srv_sort)

    # Ok, if needed, apply the widget refine search filter
    if refine_search:
        # We compile the pattern
        pat = re.compile(refine_search, re.IGNORECASE)
        new_pbs = []
        for p in items:
            if pat.search(p.get_full_name()):
                new_pbs.append(p)
                continue
            to_add = False
            for imp in p.impacts:
                if pat.search(imp.get_full_name()):
                    to_add = True
            for src in p.source_problems:
                if pat.search(src.get_full_name()):
                    to_add = True
            if to_add:
                new_pbs.append(p)

        items = new_pbs[:nb_elements]

    pbs = items[:nb_elements]

    wid = app.request.GET.get('wid', 'widget_problems_' + str(int(time.time())))
    collapsed = (app.request.GET.get('collapsed', 'False') == 'True')

    options = {'search': {'value': refine_search, 'type': 'text', 'label': 'Filter by name'},
               'nb_elements': {'value': nb_elements, 'type': 'int', 'label': 'Max number of elements to show'},
               }

    title = 'IT problems'
    if refine_search:
        title = 'IT problems (%s)' % refine_search

    return {'pbs': pbs, 'search': refine_search, 'page': 'problems',
            'wid': wid, 'collapsed': collapsed, 'options': options, 'base_url': '/widget/problems', 'title': title,
            }


def get_last_errors_widget():
    user = app.bottle.request.environ['USER']

    # We want to limit the number of elements, The user will be able to increase it
    nb_elements = max(0, int(app.request.GET.get('nb_elements', '10')))

    pbs = app.datamgr.get_problems(user, sorter=last_state_change_earlier)

    # Keep only nb_elements
    pbs = pbs[:nb_elements]

    wid = app.request.GET.get('wid', 'widget_last_problems_' + str(int(time.time())))
    collapsed = (app.request.GET.get('collapsed', 'False') == 'True')

    options = {'nb_elements': {'value': nb_elements, 'type': 'int', 'label': 'Max number of elements to show'},
               }

    title = 'Last IT problems'

    return {'pbs': pbs, 'page': 'problems',
            'wid': wid, 'collapsed': collapsed, 'options': options, 'base_url': '/widget/last_problems', 'title': title,
            }

widget_desc = '''<h4>IT problems</h4>
Show the most impacting IT problems
'''

last_widget_desc = '''<h4>Last IT problems</h4>
Show the IT problems sorted by time
'''

pages = {
    get_page: {'routes': ['/problems'], 'view': 'problems', 'static': True},
    get_all: {'routes': ['/all'], 'view': 'problems', 'static': True},
    get_pbs_widget: {'routes': ['/widget/problems'], 'view': 'widget_problems', 'static': True, 'widget': ['dashboard'], 'widget_desc': widget_desc, 'widget_name': 'problems', 'widget_picture': '/static/problems/img/widget_problems.png'},
    get_last_errors_widget: {'routes': ['/widget/last_problems'], 'view': 'widget_last_problems', 'static': True, 'widget': ['dashboard'], 'widget_desc': last_widget_desc, 'widget_name': 'last_problems', 'widget_picture': '/static/problems/img/widget_problems.png'},
}
