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

# Get plugin's parameters from configuration file
params = {}
params['elts_per_page'] = 10

def load_cfg():
    global params
    
    import os
    from shinken.log import logger
    from webui.config_parser import config_parser
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

def reload_cfg():
    load_cfg()
    app.bottle.redirect("/config")

def show_hostgroup(name):
    app.bottle.redirect("/all?search=type:host hg:" + name)

def show_hostgroups():
    user = app.check_user_authentication()    

    # Set hostgroups level ...
    app.set_hostgroups_level(user)
    
    return {
        'app': app, 'user': user, 'params': params, 
        'hostgroups': sorted(app.get_hostgroups(), key=lambda hostgroup: hostgroup.hostgroup_name)
        }


def show_servicegroup(name):
    app.bottle.redirect("/all?search=type:service hg:" + name)

def show_servicegroups():
    user = app.check_user_authentication()    

    # Set servicegroups level ...
    app.set_servicegroups_level(user)

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
