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
import re

from shinken.misc.sorter import hst_srv_sort, last_state_change_earlier

# Will be populated by the UI with it's own value
app = None


def get_page():
    app.bottle.redirect("/all?search=%s" % app.PROBLEMS_SEARCH_STRING)


def get_all():
    user = app.bottle.request.environ['USER']

    # Update the default filter according to the logged-in user minimum business impact
    default_filtering = app.PROBLEMS_SEARCH_STRING

    # Fetch elements per page preference for user, default is 25
    elts_per_page = app.prefs_module.get_ui_user_preference(user, 'elts_per_page', 25)
    display_impacts = app.prefs_module.get_ui_user_preference(user, 'display_impacts', True)
    display_impacts = display_impacts and display_impacts != 'false'

    # Fetch sound preference for user, default is 'no'
    sound_pref = app.prefs_module.get_ui_user_preference(user, 'sound',
                                                         'yes' if app.play_sound else 'no')
    sound = app.request.GET.get('sound', '')
    if sound != sound_pref and sound in ['yes', 'no']:
        app.prefs_module.set_ui_user_preference(user, 'sound', sound)
        sound_pref = sound

    # Set hostgroups level ...
    # todo @mohierf: why here? Should be done only once on initialization...
    app.datamgr.set_hostgroups_level(user)

    # Set servicegroups level ...
    # todo @mohierf: why here? Should be done only once on initialization...
    app.datamgr.set_servicegroups_level(user)

    # We want to limit the number of elements
    step = int(app.request.GET.get('step', elts_per_page))
    if step != elts_per_page:
        elts_per_page = step
    start = int(app.request.GET.get('start', '0'))
    end = int(app.request.GET.get('end', start + step))

    title = app.request.GET.get('title', 'All problems')

    search = app.get_search_string() or ""
    items = list(app.datamgr.search_hosts_and_services(search, user))

    pbs = list(sorted(items, hst_srv_sort))

    if not display_impacts:
        # Remove impacts when source of impact (dependency) is in list
        for pb in pbs:
            if pb.impacts:
                for i in pb.impacts:
                    if i in pbs and i != pb and i.business_impact <= pb.business_impact:
                        pbs.remove(i)

    # If we overflow, came back as normal
    if start > len(pbs):
        start = 0
        end = start + step

    navi = app.helper.get_navi(len(pbs), start, step=step)

    return {
        'pbs': pbs[start:end],
        'problems_search': True if search == default_filtering else False,
        'all_pbs': items,
        'navi': navi,
        'title': title,
        'bookmarks': app.prefs_module.get_user_bookmarks(user),
        'bookmarksro': app.prefs_module.get_common_bookmarks(),
        'sound': sound_pref,
        'elts_per_page': elts_per_page,
        'display_impacts': display_impacts
    }


def get_pbs_widget():
    user = app.bottle.request.environ['USER']

    # We want to limit the number of elements, The user will be able to increase it
    nb_elements = max(0, int(app.request.GET.get('nb_elements', '10')))
    refine_search = app.request.GET.get('search', '')

    items = app.datamgr.search_hosts_and_services(app.PROBLEMS_SEARCH_STRING,
                                                  user)

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
                    continue

            for src in p.source_problems:
                if pat.search(src.get_full_name()):
                    to_add = True
                    continue

            if to_add:
                new_pbs.append(p)

        items = new_pbs[:nb_elements]

    pbs = items[:nb_elements]

    wid = app.request.query.get('wid', 'widget_problems_' + str(int(time.time())))
    collapsed = (app.request.query.get('collapsed', 'false') == 'true')
    header = (app.request.query.get('header', 'false') == 'true')
    commands = (app.request.query.get('commands', 'false') == 'true')

    options = {
        'search': {
            'value': refine_search,
            'type': 'text',
            'label': 'Filter by name'
        },
        'nb_elements': {
            'value': nb_elements,
            'type': 'int',
            'label': 'Max number of elements to show'
        },
        'commands': {
            'value': commands,
            'type': 'bool',
            'label': 'Commands buttons bar'
        },
        'header': {
            'value': header,
            'type': 'bool',
            'label': 'Hosts/services problems table header'
        }
    }

    title = 'IT problems'
    if refine_search:
        title = 'IT problems (%s)' % refine_search

    return {
        'pbs': pbs, 'all_pbs': items, 'search': refine_search, 'page': 'problems',
        'wid': wid, 'collapsed': collapsed, 'options': options, 'base_url': '/widget/problems',
        'title': title, 'header': header, 'commands': commands
    }


def get_last_errors_widget():
    user = app.bottle.request.environ['USER']

    # We want to limit the number of elements, The user will be able to increase it
    nb_elements = max(0, int(app.request.GET.get('nb_elements', '10')))
    refine_search = app.request.GET.get('search', '')

    # Apply search filter if exists ...
    items = app.datamgr.search_hosts_and_services(app.PROBLEMS_SEARCH_STRING,
                                                  user)

    # Sort it now
    items.sort(last_state_change_earlier)

    # Keep only nb_elements
    pbs = items[:nb_elements]

    wid = app.request.query.get('wid', 'widget_last_problems_' + str(int(time.time())))
    collapsed = (app.request.query.get('collapsed', 'false') == 'true')
    header = (app.request.query.get('header', 'false') == 'true')
    commands = (app.request.query.get('commands', 'false') == 'true')

    options = {
        'nb_elements': {
            'value': nb_elements,
            'type': 'int',
            'label': 'Max number of elements to show'
        },
        'commands': {
            'value': commands,
            'type': 'bool',
            'label': 'Commands buttons bar'
        },
        'header': {
            'value': header,
            'type': 'bool',
            'label': 'Hosts/services problems table header'
        }
    }

    title = 'Last IT problems'

    return {
        'pbs': pbs, 'all_pbs': items, 'page': 'problems',
        'wid': wid, 'collapsed': collapsed, 'options': options, 'base_url': '/widget/last_problems',
        'title': title, 'header': header, 'commands': commands
    }


widget_desc = """<h4>IT problems</h4>
Show the most impacting IT problems
"""


last_widget_desc = """<h4>Last IT problems</h4>
Show the most recent IT problems
"""


pages = {
    get_page: {
        'name': 'Problems', 'route': '/problems', 'view': 'problems',
        'static': True
    },
    get_all: {
        'name': 'All', 'route': '/all', 'view': 'problems',
        'static': True,
        'search_engine': True
    },
    get_pbs_widget: {
        'name': 'wid_Problems', 'route': '/widget/problems', 'view': 'widget_problems',
        'widget': ['dashboard'], 'widget_desc': widget_desc,
        'widget_name': 'problems',
        'widget_alias': 'Current problems',
        'widget_icon': 'exclamation',
        'widget_picture': '/static/problems/img/widget_problems.png',
        'static': True
    },
    get_last_errors_widget: {
        'name': 'wid_LastProblems', 'route': '/widget/last_problems', 'view': 'widget_problems',
        'widget': ['dashboard'], 'widget_desc': last_widget_desc,
        'widget_name': 'last_problems',
        'widget_alias': 'Most recent problems',
        'widget_icon': 'exclamation-circle',
        'widget_picture': '/static/problems/img/widget_last_problems.png',
        'static': True
    }
}
