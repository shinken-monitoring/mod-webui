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
    return {'records': _get_availability(name)}


def get_page():
    # Find start and end date if provided in parameters ...
    # Default is current day
    midnight_timestamp = time.mktime(datetime.date.today().timetuple())
    
    range_start = int(app.request.GET.get('range_start', midnight_timestamp))
    range_end = int(app.request.GET.get('range_end', midnight_timestamp + 86399))
    logger.debug("[WebUI-availability] get_page, range: %d - %d", range_start, range_end)

    records = _get_availability(name=None, range_start=range_start, range_end=range_end)

    return {'records': records, 'range_start': range_start, 'range_end': range_end}


pages = {
    get_element: {'routes': ['/availability/inner/<name:path>'], 'view': 'availability', 'static': True},
    get_page: {'routes': ['/availability'], 'view': 'availability-all', 'static': True},
}
