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

from shinken.util import safe_print
from shinken.misc.sorter import hst_srv_sort

def get_page(groupname):
    # First we look for the user sid
    # so we bail out if it's a false one
    user = app.get_user_auth()

    if not user:
        app.bottle.redirect("/user/login")
        return

    # Here we can call app.datamgr because when the webui "loaded" us, it
    # populate app with it's own value.
    if groupname == 'all':
        my_group = 'all'
        
        hosts = []
        hosts.extend(app.datamgr.get_hosts())
        items = hosts

    else:
        my_group = app.datamgr.get_hostgroup(groupname)

        if not my_group:
            return "Unknown group %s" % groupname
            
        items = my_group.get_hosts()

    # Now sort hosts list ..
    items.sort(hst_srv_sort)
        
    # We want to limit the number of elements
    start = int(app.request.GET.get('start', '0'))
    end = int(app.request.GET.get('end', '30'))
        
    # If we overflow, came back as normal
    total = len(items)
    if start > total:
        start = 0
        end = 30

    navi = app.helper.get_navi(total, start, step=30)
    items = items[start:end]
        
    # we return values for the template (view). But beware, theses values are the
    # only one the template will have, so we must give it an app link and the
    # user we are logged with (it's a contact object in fact)
    return {'app': app, 'user': user, 'navi': navi, 'group': my_group, 'hosts': items}

def show_minemaps():
    # First we look for the user sid
    # so we bail out if it's a false one
    user = app.get_user_auth()

    if not user:
        app.bottle.redirect("/user/login")
        return

    app.bottle.redirect("/minemap/all")


# This is the dict the webui will try to "load".
#  *here we register one page with both addresses /dummy/:arg1 and /dummy/, both addresses
#   will call the function get_page.
#  * we say that for this page, we are using the template file dummy (so view/dummy.tpl)
#  * we said this page got some static stuffs. So the webui will match /static/dummy/ to
#    the dummy/htdocs/ directory. Beware: it will take the plugin name to match.
#  * optional: you can add 'method': 'POST' so this address will be only available for
#    POST calls. By default it's GET. Look at the lookup module for sample about this.

pages = {get_page: {'routes': ['/minemap/:groupname'], 'view': 'minemap', 'static': True},
         show_minemaps: {'routes': ['/minemaps'], 'view': 'minemap', 'static': True},
        }