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

### Will be populated by the UI with it's own value
app = None


# Test user preferences page ...

def show_pref():
    return {}


def save_pref():
    user = app.request.environ['USER']
    key = app.request.forms.get('key', None)
    value = app.request.forms.get('value', None)

    if key is None or value is None:
        return

    s = json.dumps('{%s: %s}' % (key, value))

    app.prefs_module.set_ui_user_preference(user, key, value)

    return


def save_common_pref():
    user = app.request.environ['USER']
    key = app.request.forms.get('key', None)
    value = app.request.forms.get('value', None)

    if key is None or value is None:
        return

    s = json.dumps('{%s: %s}' % (key, value))

    print "We will save common pref ", key, ':', value
    print "As %s" % s

    if user.is_admin:
        app.prefs_module.set_ui_common_preference( key, value)

    return


pages = {
        show_pref: {'routes': ['/user/pref'], 'view': 'user_pref', 'static': True},
        
        save_pref: {'routes': ['/user/save_pref'], 'method': 'POST'}, 
        save_common_pref: {'routes': ['/user/save_common_pref'], 'method': 'POST'}
        }

