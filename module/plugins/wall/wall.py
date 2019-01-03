#!/usr/bin/python

# -*- coding: utf-8 -*-

# Copyright (C) 2009-2012:
#    Gabes Jean, naparuba@gmail.com
#    Gerhard Lausser, Gerhard.Lausser@consol.de
#    Gregory Starck, g.starck@gmail.com
#    Hartmut Goebel, h.goebel@goebel-consult.de
#    Frederic Mohier, frederic.mohier@gmail.com
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
from shinken.log import logger

# Will be populated by the UI with it's own value
app = None


# Our page
def get_page():
    user = app.request.environ['USER']

    search = app.get_and_update_search_string_with_problems_filters()

    # Impacts
    impacts = app.datamgr.get_impacts(user, search)

    # Last problems
    problems = app.datamgr.search_hosts_and_services(search, user)

    # Get only the last hour problems
    now = time.time()
    last_problems = [pb for pb in problems if pb.last_state_change > now - 3600]

    return {
        'app': app, 'user': user,
        'impacts': impacts, 'problems': problems, 'last_problems': last_problems
    }


pages = {
    get_page: {
        'name': 'Wall', 'route': '/wall', 'view': 'wall',
        'static': True,
        'search_engine': True
    }
}
