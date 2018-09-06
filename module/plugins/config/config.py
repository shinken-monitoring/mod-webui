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

import os
from shinken.log import logger
from webui2.config_parser import config_parser

# Get plugin's parameters from configuration file (not useful currently but future ideas ...)
params = {
    'fake': "fake"
}

plugin_name = os.path.splitext(os.path.basename(__file__))[0]
currentdir = os.path.dirname(os.path.realpath(__file__))
configuration_file = "%s/%s" % (currentdir, 'plugin.cfg')
logger.debug("Plugin configuration file: %s", configuration_file)
try:
    scp = config_parser('#', '=')
    params = scp.parse_config(configuration_file)

    # mongo_host = params['mongo_host']
    params['fake'] = params['fake']

    logger.debug("WebUI plugin '%s', configuration loaded." % (plugin_name))
    # logger.debug("Plugin %s configuration, database: %s (%s)",
    # plugin_name, params['mongo_host'], params['mongo_port'])
except Exception as exp:
    logger.warning("WebUI plugin '%s', configuration file (%s) not available: %s",
                   plugin_name, configuration_file, str(exp))

# Will be populated by the UI with it's own value
app = None


def config_page():
    app.bottle.redirect("/")
    return {}


pages = {
    config_page: {
        'name': 'Config', 'route': '/config', 'view': 'config', 'static': True
    }
}
