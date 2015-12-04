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

from shinken.log import logger

try:
    import json
except ImportError:
    # For old Python version, load
    # simple json (it can be hard json?! It's 2 functions guy!)
    try:
        import simplejson as json
    except ImportError:
        logger.error("[WebUI-dashboard] Error: you need the json or simplejson module")
        raise

### Will be populated by the UI with it's own value
app = None


# Our page
def get_page():
    user = app.request.environ['USER']

    # Look for the widgets as the json entry
    s = app.prefs_module.get_ui_user_preference(user, 'widgets')
    # If void, create an empty one
    if not s:
        app.prefs_module.set_ui_user_preference(user, 'widgets', '[]')
        s = '[]'
    widget_names = json.loads(s)
    widgets = []

    for w in widget_names:
        if not 'id' in w or not 'position' in w:
            continue

        # by default the widget is for /dashboard
        w['for'] = w.get('for', 'dashboard')
        if not w['for'] == 'dashboard':
            # Not a dashboard widget? I don't want it so
            continue

        pos = w['position']
        options = w.get('options', {})
        collapsed = w.get('collapsed', '0')

        options["wid"] = w["id"]
        options["collapsed"] = collapsed
        w['options'] = options
        w['options_json'] = json.dumps(options)
        args = {'wid': w['id'], 'collapsed': collapsed}
        args.update(options)
        w['options_uri'] = '&'.join('%s=%s' % (k, v) for (k, v) in args.iteritems())
        widgets.append(w)

    return {'widgets': widgets}

def get_currently():
    return {}

pages = {
    get_page: {
        'name': 'Dashboard', 'route': '/dashboard', 'view': 'dashboard', 'static': True
    },
    get_currently: {
        'name': 'Currently', 'route': '/dashboard/currently', 'view': 'currently', 'static': True
    }
}
