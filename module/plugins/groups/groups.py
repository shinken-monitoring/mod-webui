#!/usr/bin/python

# -*- coding: utf-8 -*-

# Copyright (C) 2009-2014:
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

# Get plugin's parameters from configuration file
params = {}
params['elts_per_page'] = 10

def load_cfg():
    global params
    
    import os,sys
    from shinken.log import logger
    from config_parser import config_parser
    try:
        currentdir = os.path.dirname(os.path.realpath(__file__))
        configuration_file = "%s/%s" % (currentdir, 'plugin.cfg')
        logger.debug("Plugin configuration file: %s" % (configuration_file))
        scp = config_parser('#', '=')
        params = scp.parse_config(configuration_file)

        params['elts_per_page'] = int(params['elts_per_page'])
        
        logger.debug("Plugin configuration, elts_per_page: %d" % (params['elts_per_page']))
        
        return True
    except Exception, exp:
        logger.warning("Plugin configuration file (%s) not available: %s" % (configuration_file, str(exp)))
        return False

def checkauth():
    user = app.get_user_auth()

    if not user:
        app.bottle.redirect("/user/login")
    else:
        return user

def reload_cfg():
    load_cfg()
    app.bottle.redirect("/hostgroups")

def get_page(name):
    user = checkauth()    

    # Here we can call app.datamgr because when the webui "loaded" us, it
    # populate app with it's own value.
    if name == 'all':
        my_group = 'all'
        
        hosts = []
        hosts.extend(app.datamgr.get_hosts())
        items = hosts

    else:
        my_group = app.datamgr.get_hostgroup(name)

        if not my_group:
            return "Unknown group %s" % name
            
        items = my_group.get_hosts()

    elts_per_page = params['elts_per_page']
    # We want to limit the number of elements
    start = int(app.request.GET.get('start', '0'))
    end = int(app.request.GET.get('end', elts_per_page))
        
    # Now sort hosts list ..
    items.sort(hst_srv_sort)
        
    # If we overflow, came back as normal
    total = len(items)
    if start > total:
        start = 0
        end = elts_per_page

    navi = app.helper.get_navi(total, start, step=elts_per_page)
    items = items[start:end]
        
    # we return values for the template (view). But beware, theses values are the
    # only one the template will have, so we must give it an app link and the
    # user we are logged with (it's a contact object in fact)
    return {'app': app, 'user': user, 'params': params, 'navi': navi, 'group': my_group, 'hosts': items}

def show_hostgroups():
    user = checkauth()    

    # Here we can call app.datamgr because when the webui "loaded" us, it
    # populate app with it's own value.
    my_hostgroups = app.datamgr.get_hostgroups()

    # we return values for the template (view). But beware, theses values are the
    # only one the template will have, so we must give it an app link and the
    # user we are logged with (it's a contact object in fact)
    return {'app': app, 'user': user, 'params': params, 'hgroups': my_hostgroups}


# This is the dict the webui will try to "load".
#  *here we register one page with both addresses /dummy/:arg1 and /dummy/, both addresses
#   will call the function get_page.
#  * we say that for this page, we are using the template file dummy (so view/dummy.tpl)
#  * we said this page got some static stuffs. So the webui will match /static/dummy/ to
#    the dummy/htdocs/ directory. Beware: it will take the plugin name to match.
#  * optional: you can add 'method': 'POST' so this address will be only available for
#    POST calls. By default it's GET. Look at the lookup module for sample about this.

load_cfg()

pages = {reload_cfg: {'routes': ['/group/reload'], 'view': 'groups', 'static': True},
         get_page: {'routes': ['/group/:name'], 'view': 'groups', 'static': True},
         show_hostgroups: {'routes': ['/hostgroups'], 'view': 'groups-overview', 'static': True},
         }
