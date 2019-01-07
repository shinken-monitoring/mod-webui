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

import json
from shinken.log import logger


# Will be populated by the UI with it's own value
app = None


# Test user preferences page ...

def show_pref():
    return {}


def get_pref():
    user = app.request.environ.get('USER', None)
    key = app.request.query.get('key', None)

    if not key or not user:
        return ''

    return app.prefs_module.get_ui_user_preference(user, key)


def get_common_pref():
    user = app.request.environ.get('USER', None)
    key = app.request.query.get('key', None)

    if not key or not user:
        return ''

    return app.prefs_module.get_ui_common_preference(user, key)


def save_pref():
    user = app.request.environ.get('USER', None)
    key = app.request.query.get('key', None)
    value = app.request.query.get('value', None)

    if key is None or value is None:
        return

    s = json.dumps('{%s: %s}' % (key, value))
    logger.debug("We will save pref %s=%s, as %s", key, value, s)

    app.prefs_module.set_ui_user_preference(user, key, value)


def save_common_pref():
    user = app.request.environ.get('USER', None)
    key = app.request.query.get('key', None)
    value = app.request.query.get('value', None)

    if key is None or value is None:
        return

    s = json.dumps('{%s: %s}' % (key, value))
    logger.debug("We will save common pref %s=%s, as %s", key, value, s)

    if user.is_administrator():
        app.prefs_module.set_ui_common_preference(key, value)


pages = {
    show_pref: {
        'name': 'ShowPref', 'route': '/user/pref', 'view': 'user_pref',
        'static': True
    },
    save_pref: {
        'name': 'SetPref', 'route': '/user/save_pref'
    },
    save_common_pref: {
        'name': 'SetCommonPref', 'route': '/user/save_common_pref'
    },
    get_pref: {
        'name': 'GetPref', 'route': '/user/get_pref'
    },
    get_common_pref: {
        'name': 'GetCommonPref', 'route': '/user/get_common_pref'
    }
}
