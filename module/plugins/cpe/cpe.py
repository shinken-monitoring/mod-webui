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

import time
import yaml

from shinken.log import logger
from shinken.external_command import ExternalCommand, ExternalCommandManager

from libkrill.kws.datamanager import KwsDataManager
from libkrill.config import Config as KrillConfig

# Will be populated by the UI with it's own value
app = None


# Our page
def show_cpe(cpe_name):

    kc = KrillConfig('/etc/krill')
    datamanager = KwsDataManager(kc.kws_list or [])

    cpe = None
    parent = None

    ''' Mostrar la ficha del CPE con nombre cpe_name.'''
    # Ok, we can lookup it
    user = app.bottle.request.environ['USER']

    # if not cpe_name.startswith('cpe'):
        # app.redirect404()

    cpe = app.datamgr.get_host(cpe_name, user) #or app.redirect404()

    if not cpe:
        cpe = datamanager.get_cpehost_by_hostname(cpe_name)

        logger.error('=>>>>>>>>>>> %s', cpe)

    # if not cpe:
    #     app.redirect404()

    if hasattr(cpe, 'cpe_registration_host'):
        parent = app.datamgr.get_host(cpe.cpe_registration_host, user)

    # Set hostgroups level ...
    app.datamgr.set_hostgroups_level(user)

    # Get graph data. By default, show last 4 hours
    maxtime = int(time.time())
    mintime = maxtime - 7 * 24 * 3600


    try:
        with open("/etc/krill/cpe_models.yml", 'r') as stream:
            models = yaml.load(stream)
    except:
        pass

    models = {}
    model = {}
    if '_CPE_MODEL' in cpe.customs:
        #model.update(in=1)
        _model = cpe.customs.get('_CPE_MODEL')
        if _model and _model in models:
            model.update(models.get(_model))

    return {'cpe': cpe, 'parent': parent, 'mintime': mintime, 'maxtime': maxtime, 'model': model}



def show_quick_services(cpe_name):

    cpe = None
    parent = None

    ''' Mostrar la ficha del CPE con nombre cpe_name.'''
    # Ok, we can lookup it
    user = app.bottle.request.environ['USER']

    # if not cpe_name.startswith('cpe'):
        # app.redirect404()

    cpe = app.datamgr.get_host(cpe_name, user) or app.redirect404()

    if cpe.cpe_registration_host:
        parent = app.datamgr.get_host(cpe.cpe_registration_host, user)

    # Set hostgroups level ...
    app.datamgr.set_hostgroups_level(user)

    # Get graph data. By default, show last 4 hours
    maxtime = int(time.time())
    mintime = maxtime - 7 * 24 * 3600

    return {'cpe': cpe, 'parent': parent, 'mintime': mintime, 'maxtime': maxtime}

pages = {
    show_cpe: {
        'name': 'CPE', 'route': '/cpe/:cpe_name', 'view': 'cpe', 'static': True,
    },

    show_quick_services: {
        'name': 'QUICKSERVICES', 'route': '/cpe/quickservices/:cpe_name', 'view': 'quickservices', 'static': True,
    }

}
