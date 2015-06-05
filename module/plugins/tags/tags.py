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

        logger.debug("WebUI plugin '%s', configuration loaded." % (plugin_name))
        logger.debug("Plugin configuration, elts_per_page: %d" % (params['elts_per_page']))

        return True
    except Exception, exp:
        logger.warning("WebUI plugin '%s', configuration file (%s) not available: %s" % (plugin_name, configuration_file, str(exp)))
        return False

def reload_cfg():
    load_cfg()
    app.bottle.redirect("/config")

def show_tag(name):
    user = app.checkauth()

    if name == 'all':
        items = []
        items.extend(app.get_hosts())

    else:
        items = app.get_hosts_tagged_with(name)

    elts_per_page = params['elts_per_page']
    # We want to limit the number of elements
    start = int(app.request.GET.get('start', '0'))
    end = int(app.request.GET.get('end', elts_per_page))

    # Now sort hosts list ..
    # items.sort(hst_srv_sort)

    # If we overflow, came back as normal
    total = len(items)
    if start > total:
        start = 0
        end = elts_per_page

    navi = app.helper.get_navi(total, start, step=elts_per_page)
    items = items[start:end]

    return {'app': app, 'user': user, 'params': params, 'navi': navi, 'tag': name, 'hosts': items, 'length': total}

def show_stag(name):
    user = app.checkauth()

    if name == 'all':
        items = []
        items.extend(app.get_hosts())

    else:
        items = app.get_services_tagged_with(name)

    elts_per_page = params['elts_per_page']
    # We want to limit the number of elements
    start = int(app.request.GET.get('start', '0'))
    end = int(app.request.GET.get('end', elts_per_page))

    # Now sort hosts list ..
    # items.sort(hst_srv_sort)

    # If we overflow, came back as normal
    total = len(items)
    if start > total:
        start = 0
        end = elts_per_page

    navi = app.helper.get_navi(total, start, step=elts_per_page)
    items = items[start:end]

    return {'app': app, 'user': user, 'params': params, 'navi': navi, 'tag': name, 'services': items, 'length': total}

def show_tags():
    user = app.checkauth()

    fake_htags = []
    for tag in app.get_host_tags_sorted():
        hosts = only_related_to(app.get_hosts_tagged_with(tag[0]),user)
        if len(hosts) > 0:
            fake_htags.append({'name': tag[0], 'hosts': hosts})

    return {'app': app, 'user': user, 'params': params, 'htags': fake_htags}

def show_stags():
    user = app.checkauth()

    fake_stags = []
    for tag in app.get_service_tags_sorted():
        services = only_related_to(app.get_services_tagged_with(tag[0]),user)
        if len(services) > 0:
            fake_stags.append({'name': tag[0], 'services': services})

    return {'app': app, 'user': user, 'params': params, 'stags': fake_stags}

# Load plugin configuration parameters
load_cfg()

pages = {
        reload_cfg: {'routes': ['/reload/tags']},

        show_tag: {'routes': ['/hosts-tag/:name'], 'view': 'hosts-tag', 'static': True},
        show_stag: {'routes': ['/services-tag/:name'], 'view': 'services-tag', 'static': True},
        show_tags: {'routes': ['/hosts-tags'], 'view': 'hosts-tags-overview', 'static': True},
        show_stags: {'routes': ['/services-tags'], 'view': 'services-tags-overview', 'static': True},
        }
