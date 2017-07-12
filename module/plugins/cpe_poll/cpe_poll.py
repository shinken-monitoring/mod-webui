#!/usr/bin/python

# -*- coding: utf-8 -*-


import time

from shinken.log import logger
from shinken.external_command import ExternalCommand, ExternalCommandManager

from shinken.brok import Brok

# Will be populated by the UI with it's own value
app = None

# Our page
def json_cpe(cpe_name):

    user = app.bottle.request.environ['USER']
    cpe = app.datamgr.get_host(cpe_name, user)
    
    # pollrequest
    #app.put_brok(cpe_name, 'null', {}, 'pollrequest')
    
    #app.krillui_module.pollrequest(cpe_name)
    
    
    data = dict(
        host_name=cpe_name,
        source='krillui',
        type='null',
        ts=int(time.time()),
        data={},
    )

    b = Brok(type='pollrequest', data=data)
    app.from_q.put(b)
    
    return app.krillui_module.get_data(cpe_name)


def show_test():
    return {'dummy': 'test'}
    
pages = {
    json_cpe: {
        'name': 'CPE-JSON', 'route': '/cpe/:cpe_name.json', 'view': None, 'static': True
    }
}

