#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright (C) 2009-2014:
#    Gabes Jean, naparuba@gmail.com
#    Gerhard Lausser, Gerhard.Lausser@consol.de
#    Gregory Starck, g.starck@gmail.com
#    Hartmut Goebel, h.goebel@goebel-consult.de
#    Frederic Mohier, frederic.mohier@gmail.com
#    Guillaume Subiron, maethor@subiron.org
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
import datetime
import arrow
import urllib

from collections import OrderedDict

from shinken.log import logger

# Will be populated by the UI with it's own value
app = None


def _get_availability(*args, **kwargs):
    if app.logs_module.is_available():
        return app.logs_module.get_ui_availability(*args, **kwargs)
    else:
        logger.warning("[WebUI-availability] no get availability external module defined!")
        return None


def get_element(name):
    user = app.bottle.request.environ['USER']
    name = urllib.unquote(name)
    elt = app.datamgr.get_element(name, user) or app.redirect404()

    records = []
    today = arrow.now().replace(hour=0,minute=0,second=0)
    records = OrderedDict()
    records['Today'] = _get_availability(elt=elt, range_start=today.timestamp)
    records['This week'] = _get_availability(elt=elt,
                                             range_start=today.replace(days=-today.weekday()).timestamp)
    records['This month'] = _get_availability(elt=elt, range_start=today.replace(day=1).timestamp)
    records['Yesterday'] = _get_availability(elt=elt,
                                             range_start=today.replace(days=-1).timestamp,
                                             range_end=today.timestamp)
    records['Last week'] = _get_availability(elt=elt,
                                             range_start=today.replace(days=-(7+today.weekday())).timestamp,
                                             range_end=today.replace(days=-today.weekday()).timestamp)
    records['Last month'] = _get_availability(elt=elt,
                                              range_start=today.replace(day=1, months=-1).timestamp,
                                              range_end=today.replace(day=1).timestamp)

    # Find as many months as possible in the past
    start = today.replace(day=1, months=-2)
    while True:
        record = _get_availability(elt=elt,
                                   range_start=start.timestamp,
                                   range_end=start.replace(months=1).timestamp)
        if record is None:
            break
        records[start.format('MM-YYYY')] = record
        start = start.replace(months=-1)

    return {'elt': elt, 'records': records}


def get_page():
    user = app.bottle.request.environ['USER']

    # Apply search filter if exists ...
    search = app.request.query.get('search', "type:host")
    if "type:host" not in search:
        search = "type:host " + search
    logger.debug("[WebUI-availability] search parameters '%s'", search)
    hosts = app.datamgr.search_hosts_and_services(search, user)

    midnight_timestamp = time.mktime(datetime.date.today().timetuple())
    range_start = int(app.request.GET.get('range_start', midnight_timestamp))
    range_end = int(app.request.GET.get('range_end', midnight_timestamp + 86399))
    logger.debug("[WebUI-availability] get_page, range: %d - %d", range_start, range_end)

    records = [_get_availability(elt=host, range_start=range_start, range_end=range_end) for host in hosts]

    return {'records': records, 'range_start': range_start, 'range_end': range_end}


pages = {
    get_element: {'routes': ['/availability/inner/<name:path>'], 'view': 'availability-elt', 'static': True},
    get_page: {'routes': ['/availability'], 'view': 'availability-all', 'name': 'Availabilities', 'static': True, 'search_engine': True},
}
