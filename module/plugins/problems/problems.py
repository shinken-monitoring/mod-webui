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

from shinken.misc.filter  import only_related_to
from shinken.misc.sorter import hst_srv_sort
from shinken.objects.service import Service
from shinken.log import logger

### Will be populated by the UI with it's own value
app = None

import time
import re
import json


# Our page
def get_page():
    return get_view('problems')


# Our page
def get_all():
    return get_view('all')


# Our View code. We will get different data from all and /problems
# but it's mainly filtering changes
def get_view(page):

    user = app.get_user_auth()
    if not user:
        app.bottle.redirect("/user/login")


    # Look for the toolbar pref
    toolbar_pref = app.get_user_preference(user, 'toolbar')
    # If void, create an empty one
    if not toolbar_pref:
        app.set_user_preference(user, 'toolbar', 'show')
        toolbar_pref = 'show'
    toolbar = app.request.GET.get('toolbar', '')
    if toolbar != toolbar_pref and len(toolbar) > 0:
        print "Need to change user prefs for Toolbar",
        app.set_user_preference(user, 'toolbar', toolbar)
    toolbar_pref = app.get_user_preference(user, 'toolbar')


    # We want to limit the number of elements
    step = int(app.request.GET.get('step', '30'))
    start = int(app.request.GET.get('start', '0'))
    end = int(app.request.GET.get('end', start + step))

    # We will keep a trace of our filters
    filters = {}
    ts = ['hst_srv', 'hg', 'realm', 'htag', 'stag', 'ack', 'downtime', 'crit']
    for t in ts:
        filters[t] = []

    search = app.request.GET.getall('search')
    if search == []:
        search = app.request.GET.get('global_search', '')

    # Most of the case, search will be a simple string, if so
    # make it a list of this string
    if isinstance(search, basestring):
        search = [search]

    search_str = '&'.join(search)

    # Load the bookmarks
    bookmarks_r = app.get_user_preference(user, 'bookmarks')
    if not bookmarks_r:
        app.set_user_preference(user, 'bookmarks', '[]')
        bookmarks_r = '[]'
    bookmarks = json.loads(bookmarks_r)
    bookmarks_ro = app.get_common_preference('bookmarks')
    if not bookmarks_ro:
        bookmarks_ro = '[]'

    bookmarksro = json.loads(bookmarks_ro)
    bookmarks = json.loads(bookmarks_r)

    items = []
    if page == 'problems':
        items = app.get_all_problems(user, to_sort=True, get_acknowledged=False)
    elif page == 'all':
        items = app.get_all_hosts_and_services(user)
    else:
        app.bottle.redirect("/problems")

    logger.debug("[%s] problems", app.name)
    for i in items:
        logger.debug("[%s] problems, item: %s", app.name, i.get_full_name())
        
    # Filter with the user interests
    # my_items = only_related_to(items, user)
    my_items = items

    # Check for related host contacts
    if not user.is_admin:
      for i in items:
        if isinstance(i,Service):
          if user in i.host.contacts:
            my_items.append(i)
            continue

    items = my_items
    logger.debug("[%s] problems after user filtering", app.name)
    for i in items:
        logger.debug("[%s] problems, item: %s", app.name, i.get_full_name())
        

    # Ok, if needed, apply the search filter
    for s in search:
        s = s.strip()
        if not s:
            continue

        logger.debug("[%s] problems, searching for: %s in %d items", app.name, s, len(items))

        elts = s.split(':', 1)
        t = 'hst_srv'
        if len(elts) > 1:
            t = elts[0]
            s = elts[1]

        logger.debug("[%s] problems, searching for type %s, pattern: %s", app.name, t, s)
        if not t in filters:
            filters[t] = []
        filters[t].append(s)

        if t == 'hst_srv':
            # We compile the pattern
            pat = re.compile(s, re.IGNORECASE)
            new_items = []
            for i in items:
                if pat.search(i.get_full_name()):
                    new_items.append(i)
                    continue
                to_add = False
                for imp in i.impacts:
                    if pat.search(imp.get_full_name()):
                        to_add = True
                for src in i.source_problems:
                    if pat.search(src.get_full_name()):
                        to_add = True
                if to_add:
                    new_items.append(i)

            items = new_items

        if t == 'hg':
            hg = app.datamgr.get_hostgroup(s)
            items = [i for i in items if hg in i.get_hostgroups()]

        if t == 'realm':
            r = app.datamgr.get_realm(s)
            items = [i for i in items if i.get_realm() == r]

        if t == 'htag':
            items = [i for i in items if s in i.get_host_tags()]

        if t == 'stag':
            items = [i for i in items if i.__class__.my_type == 'service' and s in i.get_service_tags()]

        if t == 'ack':
            if s == 'false':
                # First look for hosts, so ok for services, but remove problem_has_been_acknowledged elements
                items = [i for i in items if i.__class__.my_type == 'service' or not i.problem_has_been_acknowledged]
                # Now ok for hosts, but look for services, and service hosts
                items = [i for i in items if i.__class__.my_type == 'host' or (not i.problem_has_been_acknowledged and not i.host.problem_has_been_acknowledged)]
            if s == 'true':
                # First look for hosts, so ok for services, but remove problem_has_been_acknowledged elements
                items = [i for i in items if i.__class__.my_type == 'service' or i.problem_has_been_acknowledged]
                # Now ok for hosts, but look for services, and service hosts
                items = [i for i in items if i.__class__.my_type == 'host' or (i.problem_has_been_acknowledged or i.host.problem_has_been_acknowledged)]

        if t == 'downtime':
            if s == 'false':
                # First look for hosts, so ok for services, but remove problem_has_been_acknowledged elements
                items = [i for i in items if i.__class__.my_type == 'service' or not i.in_scheduled_downtime]
                # Now ok for hosts, but look for services, and service hosts
                items = [i for i in items if i.__class__.my_type == 'host' or (not i.in_scheduled_downtime and not i.host.in_scheduled_downtime)]
            if s == 'true':
                # First look for hosts, so ok for services, but remove problem_has_been_acknowledged elements
                items = [i for i in items if i.__class__.my_type == 'service' or i.in_scheduled_downtime]
                # Now ok for hosts, but look for services, and service hosts
                items = [i for i in items if i.__class__.my_type == 'host' or (i.in_scheduled_downtime or i.host.in_scheduled_downtime)]

        if t == 'crit':
            items = [i for i in items if (i.__class__.my_type == 'service' and i.state_id == 2) or (i.__class__.my_type == 'host' and i.state_id == 1)]



        logger.debug("[%s] problems, found %d elements for type %s, pattern: %s", app.name, len(items), t, s)

    # If we are in the /problems and we do not have an ack filter
    # we apply by default the ack:false one
    if page == 'problems' and len(filters['ack']) == 0:
        # First look for hosts, so ok for services, but remove problem_has_been_acknowledged elements
        items = [i for i in items if i.__class__.my_type == 'service' or not i.problem_has_been_acknowledged]
        # Now ok for hosts, but look for services, and service hosts
        items = [i for i in items if i.__class__.my_type == 'host' or (not i.problem_has_been_acknowledged and not i.host.problem_has_been_acknowledged)]

    # If we are in the /problems and we do not have an downtime filter
    # we apply by default the downtime:false one
    if page == 'problems' and len(filters['downtime']) == 0:
        # First look for hosts, so ok for services, but remove problem_has_been_acknowledged elements
        items = [i for i in items if i.__class__.my_type == 'service' or not i.in_scheduled_downtime]
        # Now ok for hosts, but look for services, and service hosts
        items = [i for i in items if i.__class__.my_type == 'host' or (not i.in_scheduled_downtime and not i.host.in_scheduled_downtime)]

    logger.debug("[%s] problems after search filtering", app.name)
    for i in items:
        logger.debug("[%s] problems, item: %s, %d, %d", app.name, i.get_full_name(), i.business_impact, i.state_id)

    # Now sort it!
    items.sort(hst_srv_sort)

    logger.debug("[%s] problems after host/service sort", app.name)
    for i in items:
        logger.debug("[%s] problems, item: %s, %d, %d", app.name, i.get_full_name(), i.business_impact, i.state_id)

    total = len(items)
    # If we overflow, came back as normal
    if start > total:
        start = 0
        end = start + step

    navi = app.helper.get_navi(total, start, step=step)
    items = items[start:end]

    return {'app': app, 'pbs': items, 'user': user, 'navi': navi, 'search': search_str, 'page': page, 'filters': filters, 'bookmarks': bookmarks, 'bookmarksro': bookmarksro, 'toolbar': toolbar_pref }


# Our page
def get_pbs_widget():

    user = app.get_user_auth()
    if not user:
        app.bottle.redirect("/user/login")

    # We want to limit the number of elements, The user will be able to increase it
    nb_elements = max(0, int(app.request.GET.get('nb_elements', '10')))
    search = app.request.GET.get('search', '')

    pbs = app.datamgr.get_all_problems(to_sort=False)

    # Filter with the user interests
    pbs = only_related_to(pbs, user)

    # Sort it now
    pbs.sort(hst_srv_sort)

    # Ok, if need, appli the search filter
    if search:
        print "SEARCHING FOR", search
        print "Before filtering", len(pbs)
        # We compile the pattern
        pat = re.compile(search, re.IGNORECASE)
        new_pbs = []
        for p in pbs:
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

        pbs = new_pbs[:nb_elements]
        print "After filtering", len(pbs)

    pbs = pbs[:nb_elements]

    wid = app.request.GET.get('wid', 'widget_problems_' + str(int(time.time())))
    collapsed = (app.request.GET.get('collapsed', 'False') == 'True')

    options = {'search': {'value': search, 'type': 'text', 'label': 'Filter by name'},
               'nb_elements': {'value': nb_elements, 'type': 'int', 'label': 'Max number of elements to show'},
               }

    title = 'IT problems'
    if search:
        title = 'IT problems (%s)' % search

    return {'app': app, 'pbs': pbs, 'user': user, 'search': search, 'page': 'problems',
            'wid': wid, 'collapsed': collapsed, 'options': options, 'base_url': '/widget/problems', 'title': title,
            }


# Our page
def get_last_errors_widget():

    user = app.get_user_auth()
    if not user:
        app.bottle.redirect("/user/login")

    # We want to limit the number of elements, The user will be able to increase it
    nb_elements = max(0, int(app.request.GET.get('nb_elements', '10')))

    pbs = app.datamgr.get_problems_time_sorted()

    # Filter with the user interests
    pbs = only_related_to(pbs, user)

    # Keep only nb_elements
    pbs = pbs[:nb_elements]

    wid = app.request.GET.get('wid', 'widget_last_problems_' + str(int(time.time())))
    collapsed = (app.request.GET.get('collapsed', 'False') == 'True')

    options = {'nb_elements': {'value': nb_elements, 'type': 'int', 'label': 'Max number of elements to show'},
               }

    title = 'Last IT problems'

    return {'app': app, 'pbs': pbs, 'user': user, 'page': 'problems',
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
