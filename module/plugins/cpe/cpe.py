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
def show_cpe(cpe_name):
    ''' Mostrar la ficha del CPE con nombre cpe_name.'''
    # Ok, we can lookup it
    user = app.bottle.request.environ['USER']
    cpe = app.datamgr.get_host(cpe_name, user) or app.redirect404()

    # Set hostgroups level ...
    app.datamgr.set_hostgroups_level(user)

    # Get graph data. By default, show last 4 hours
    maxtime = int(time.time())
    mintime = maxtime - 7 * 24 * 3600

    return {'cpe': cpe, 'mintime': mintime, 'maxtime': maxtime}


pages = {
    show_cpe: {
        'name': 'CPE', 'route': '/cpe/:cpe_name', 'view': 'cpe', 'static': True
    }
}
