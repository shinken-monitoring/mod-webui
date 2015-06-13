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

### Will be populated by the UI with it's own value
app = None

from shinken.log import logger
from shinken.misc.sorter import hst_srv_sort
from shinken.misc.filter import only_related_to

# Get plugin's parameters from configuration file
params = {}
params['elts_per_page'] = 10

def load_cfg():
    global params
    
    import os,sys
    from webui.config_parser import config_parser
    plugin_name = os.path.splitext(os.path.basename(__file__))[0]
    try:
        currentdir = os.path.dirname(os.path.realpath(__file__))
        configuration_file = "%s/%s" % (currentdir, 'plugin.cfg')
        logger.debug("Plugin configuration file: %s" % (configuration_file))
        scp = config_parser('#', '=')
        params = scp.parse_config(configuration_file)

        params['elts_per_page'] = int(params['elts_per_page'])
        
        params['minemap_hostsLevel'] = [int(item) for item in params['minemap_hostsLevel'].split(',')]
        params['minemap_hostsShow'] = [item for item in params['minemap_hostsShow'].split(',')]
        params['minemap_hostsHide'] = [item for item in params['minemap_hostsHide'].split(',')]
        params['minemap_servicesLevel'] = [int(item) for item in params['minemap_servicesLevel'].split(',')]
        params['minemap_servicesHide'] = [item for item in params['minemap_servicesHide'].split(',')]
        
        logger.info("[webui-minemap] configuration loaded.")
        logger.debug("[webui-minemap] configuration, elts_per_page: %d", params['elts_per_page'])
        logger.debug("[webui-minemap] configuration, minemap hosts level: %s", params['minemap_hostsLevel'])
        logger.debug("[webui-minemap] configuration, minemap hosts always shown: %s", params['minemap_hostsShow'])
        logger.debug("[webui-minemap] configuration, minemap hosts always hidden: %s", params['minemap_hostsHide'])
        logger.debug("[webui-minemap] configuration, minemap services level: %s", params['minemap_servicesLevel'])
        logger.debug("[webui-minemap] configuration, minemap services hide: %s", params['minemap_servicesHide'])
        return True
    except Exception, exp:
        logger.warning("[webui-minemap] configuration file (%s) not available: %s", configuration_file, str(exp))
        return False

def reload_cfg():
    load_cfg()
    app.bottle.redirect("/config")

def show_minemap(name):
    user = app.check_user_authentication()

    if name == 'all':
        my_group = 'all'
        
        hosts = app.get_hosts(user)

    else:
        my_group = app.get_hostgroup(name)
        if not my_group:
            return "Unknown group %s" % name
            
        hosts = only_related_to(my_group.get_hosts(),user)

    items = []
    for h in hosts:
        # Filter hosts
        if h.get_name() in params['minemap_hostsHide']:
            continue
            
        if h.get_name() not in params['minemap_hostsShow'] and h.business_impact not in params['minemap_hostsLevel']:
            continue
            
        logger.debug("[webui-minemap] found host '%s': %d", h.get_name(), h.business_impact)
        items.append(h)
        
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

    return {'app': app, 'user': user, 'navi': navi, 'params': params, 'group': my_group, 'hosts': items}

def show_minemaps():
    user = app.check_user_authentication()

    app.bottle.redirect("/minemap/all")


# Load plugin configuration parameters
load_cfg()

pages = {
    reload_cfg: {'routes': ['/reload/minemap']},

    show_minemap: {'routes': ['/minemap/:name'], 'view': 'minemap', 'static': True},
    show_minemaps: {'routes': ['/minemaps'], 'view': 'minemap', 'static': True}
}
