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

# Get plugin's parameters from configuration file
params = {}
params['elts_per_page'] = 10

def load_cfg():
    global params
    
    import os,sys
    from shinken.log import logger
    currentdir = os.path.dirname(os.path.realpath(__file__)) 
    sys.path.insert(0,currentdir+"/../..") 
    from config_parser import config_parser 
    plugin_name = os.path.splitext(os.path.basename(__file__))[0]
    try:
        configuration_file = "%s/%s" % (currentdir, 'plugin.cfg')
        logger.debug("Plugin configuration file: %s" % (configuration_file))
        scp = config_parser('#', '=')
        params = scp.parse_config(configuration_file)

        params['elts_per_page'] = int(params['elts_per_page'])
        
        logger.debug("WebUI plugin '%s', configuration loaded." % (plugin_name))
        logger.debug("Plugin configuration, elts_per_page: %d" % (params['elts_per_page']))
        
        return True
    except Exception, exp:
        logger.warning("WebUI plugin '%s', configuration file (%s) not available: %s" % (plugin_name, configuration_file, str(exp)))
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

def show_hostgroup(name):
    user = checkauth()

    if name == 'all':
        my_group = 'all'
        
        items = []
        items.extend(app.datamgr.get_hosts())

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
        
    return {'app': app, 'user': user, 'params': params, 'navi': navi, 'group': my_group, 'hosts': items, 'length': total}

def show_hostgroups():
    user = checkauth()    

    my_hostgroups = app.datamgr.get_hostgroups()

    return {'app': app, 'user': user, 'params': params, 'hgroups': my_hostgroups}


def show_servicegroup(name):
    user = checkauth()    

    if name == 'all':
        my_group = 'all'
        
        services = []
        services.extend(app.datamgr.get_services())
        items = services

    else:
        my_group = app.datamgr.get_servicegroup(name)

        if not my_group:
            return "Unknown group %s" % name
            
        items = my_group.get_services()

    elts_per_page = params['elts_per_page']
    # We want to limit the number of elements
    start = int(app.request.GET.get('start', '0'))
    end = int(app.request.GET.get('end', elts_per_page))
        
    # Now sort services list ..
    items.sort(hst_srv_sort)
        
    # If we overflow, came back as normal
    total = len(items)
    if start > total:
        start = 0
        end = elts_per_page

    navi = app.helper.get_navi(total, start, step=elts_per_page)
    items = items[start:end]
        
    return {'app': app, 'user': user, 'params': params, 'navi': navi, 'group': my_group, 'services': items, 'length': total}

def show_servicegroups():
    user = checkauth()    

    my_servicegroups = app.datamgr.get_servicegroups()

    return {'app': app, 'user': user, 'params': params, 'sgroups': my_servicegroups}


# Load plugin configuration parameters
load_cfg()

# This is the dict the webui will try to "load".
#  *here we register one page with both addresses /dummy/:arg1 and /dummy/, both addresses
#   will call the function get_page.
#  * we say that for this page, we are using the template file dummy (so view/dummy.tpl)
#  * we said this page got some static stuffs. So the webui will match /static/dummy/ to
#    the dummy/htdocs/ directory. Beware: it will take the plugin name to match.
#  * optional: you can add 'method': 'POST' so this address will be only available for
#    POST calls. By default it's GET. Look at the lookup module for sample about this.
pages = {reload_cfg: {'routes': ['/hostgroups/reload','/servicegroups/reload'], 'view': 'hostgroups-overview', 'static': True},
         show_hostgroup: {'routes': ['/hostgroup/:name'], 'view': 'hostgroup', 'static': True},
         show_hostgroups: {'routes': ['/hostgroups'], 'view': 'hostgroups-overview', 'static': True},
         show_servicegroup: {'routes': ['/servicegroup/:name'], 'view': 'servicegroup', 'static': True},
         show_servicegroups: {'routes': ['/servicegroups'], 'view': 'servicegroups-overview', 'static': True},
         }
