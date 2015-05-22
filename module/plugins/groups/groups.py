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

### Will be populated by the UI with it's own value
app = None

from shinken.util import safe_print
from shinken.misc.sorter import hst_srv_sort
from shinken.misc.filter import only_related_to

# Get plugin's parameters from configuration file
params = {}
params['elts_per_page'] = 10

def load_cfg():
    global params
    
    import os,sys
    from shinken.log import logger
    from webui.config_parser import config_parser
    plugin_name = os.path.splitext(os.path.basename(__file__))[0]
    try:
        currentdir = os.path.dirname(os.path.realpath(__file__))
        configuration_file = "%s/%s" % (currentdir, 'plugin.cfg')
        logger.debug("Plugin configuration file: %s" % (configuration_file))
        scp = config_parser('#', '=')
        params = scp.parse_config(configuration_file)

        params['elts_per_page'] = int(params['elts_per_page'])
        
        logger.info("[webui-groups] configuration loaded.")
        logger.debug("[webui-groups] configuration, elts_per_page: %d", params['elts_per_page'])
        return True
    except Exception, exp:
        logger.warning("[webui-groups] configuration file (%s) not available: %s", configuration_file, str(exp))
        return False

def checkauth():
    user = app.get_user_auth()

    if not user:
        app.bottle.redirect("/user/login")
    else:
        return user

def reload_cfg():
    load_cfg()
    app.bottle.redirect("/config")

def show_hostgroup(name):
    user = checkauth()

    all_hosts = app.get_hosts(user)
    
    if name == 'all':
        my_group = 'all'
        
        items = []
        items.extend(all_hosts)
        # items = all_hosts

    else:
        my_group = app.get_hostgroup(name)

        if not my_group:
            return "Unknown group %s" % name
            
        items = only_related_to(my_group.get_hosts(),user)

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
    hosts = items[start:end]
        
    return {'app': app, 'user': user, 'params': params, 'navi': navi, 'group': my_group, 'hosts': hosts, 'all_hosts': all_hosts, 'progress_bar': False}

def show_hostgroups():
    user = checkauth()    

    return {
        'app': app, 'user': user, 'params': params, 
        'hostgroups': sorted(app.get_hostgroups(), key=lambda hostgroup: hostgroup.hostgroup_name)
        }


def show_servicegroup(name):
    user = checkauth()    

    if name == 'all':
        my_group = 'all'
        
        services = []
        services.extend(app.get_services(user))
        items = services

    else:
        my_group = app.get_servicegroup(name)

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

    return {
        'app': app, 'user': user, 'params': params, 
        'servicegroups': sorted(app.get_servicegroups(), key=lambda servicegroup: servicegroup.servicegroup_name)
        }


# Load plugin configuration parameters
load_cfg()

pages = {
        reload_cfg: {'routes': ['/reload/groups']},
        
        show_hostgroup: {'routes': ['/hosts-group/:name'], 'view': 'hosts-group', 'static': True},
        show_hostgroups: {'routes': ['/hosts-groups'], 'view': 'hosts-groups-overview', 'static': True},
        show_servicegroup: {'routes': ['/services-group/:name'], 'view': 'services-group', 'static': True},
        show_servicegroups: {'routes': ['/services-groups'], 'view': 'services-groups-overview', 'static': True},
        }
