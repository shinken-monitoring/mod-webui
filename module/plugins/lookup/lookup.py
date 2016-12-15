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

from shinken.log import logger

try:
    import json
except ImportError:
    # For old Python version, load
    # simple json (it can be hard json?! It's 2 functions guy!)
    try:
        import simplejson as json
    except ImportError:
        print "Error: you need the json or simplejson module"
        raise


def lookup():
    app.response.content_type = 'application/json'

    query = app.request.GET.get('q', '')
    name = query
    user = app.request.environ['USER']

    logger.debug("[WebUI] lookup: %s", name)

    if '/' in name:
        logger.debug("[WebUI] lookup services for %s", name)
        splitted = name.split('/')
        hname = splitted[0]
        filtered_services = app.datamgr.get_host_services(hname, user)
        snames = ("%s/%s" % (hname, s.service_description) for s in filtered_services)
        r = [n for n in snames]
    else:
        filtered_hosts = app.datamgr.get_hosts(user)
        hnames = (h.host_name for h in filtered_hosts)
        r = [n for n in hnames if name in n]

    return json.dumps(r)


pages = {
    lookup: {
        'name': 'GetLookup', 'route': '/lookup', 'method': 'GET'
    }
 }
