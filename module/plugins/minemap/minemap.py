#!/usr/bin/python
# -*- coding: utf-8 -*-
# Copyright (C) 2009-2012:
#    Gabes Jean, naparuba@gmail.com
#    Mohier Frederic frederic.mohier@gmail.com
#    Karfusehr Andreas, frescha@unitedseed.de
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

# Will be populated by the UI with it's own value
app = None


def show_minemap():
    user = app.request.environ['USER']

    # Apply search filter if exists ...
    search = app.request.query.get('search', "type:host")
    if "type:host" not in search:
        search = "type:host " + search
    logger.debug("[WebUI-minemap] search parameters '%s'", search)
    items = app.datamgr.search_hosts_and_services(search, user)
    logger.info("[WebUI-minemap] got %d matching items: %s", len(items), items)

    # Fetch elements per page preference for user, default is 25
    elts_per_page = app.prefs_module.get_ui_user_preference(user, 'elts_per_page', 25)

    # We want to limit the number of elements
    step = int(app.request.GET.get('step', elts_per_page))
    if step != elts_per_page:
        elts_per_page = step
    start = int(app.request.GET.get('start', '0'))
    end = int(app.request.GET.get('end', start + step))

    # If we overflow, came back as normal
    total = len(items)
    if start > total:
        start = 0
        end = step

    navi = app.helper.get_navi(total, start, step=step)

    return {'navi': navi, 'items': items[start:end], 'page': "minemap"}


def show_minemaps():
    app.bottle.redirect("/minemap/all")


# Load plugin configuration parameters
# load_cfg()

pages = {
    show_minemap: {
        'name': 'Minemap', 'route': '/minemap', 'view': 'minemap', 'search_engine': True,
        'static': True
    },
    show_minemaps: {
        'name': 'Minemaps', 'route': '/minemaps', 'view': 'minemap',
        'static': True
    }
}
