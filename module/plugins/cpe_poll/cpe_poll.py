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

    data = dict(
        host_name=cpe_name,
        source='krillui',
        type='null',
        ts=int(time.time()),
        data={
            # 'cpe_registration_host': cpe.cpe_registration_host or None,
            # 'cpe_registration_id': cpe.cpe_registration_id or None
        },
    )

    result = app.krillui_module.get_data(cpe_name)

    if not bool(result) or not result.get('last_pollresquest_time') or (result.get('last_pollresquest_time') and (time.time() - result.get('last_pollresquest_time')) > 5 ):
        # logger.info("[WebUI:cpe_poll] pollrequest! cpe=%s" % cpe_name)
        result.update({'last_pollresquest_time': time.time()})
        b = Brok(type='pollrequest', data=data)
        app.from_q.put(b)

    return result


def cpe_reboot(name):
    # logger.info("[WebUI:cpe_poll] cpe_reboot! cpe=%s" % name)
    try:
        b = Brok('reboot_host', {'host_name': name})
        app.from_q.put(b)
        return {'result': 'ok'}
    except Exception as e:
        return {'result': 'fail', 'msg': str(e)}

def cpe_factory(name):
    # logger.info("[WebUI:cpe_poll] cpe_factory! cpe=%s" % name)
    try:
        b = Brok('restore_factory_host', {'host_name': name})
        app.from_q.put(b)
        return {'result': 'ok'}
    except Exception as e:
        return {'result': 'fail', 'msg': str(e)}

def cpe_tr069(name):
    # logger.info("[WebUI:tr069] cpe_tr069! cpe=%s" % name)
    try:
        b = Brok('restore_tr069_host', {'host_name': name})
        app.from_q.put(b)
        return {'result': 'ok'}
    except Exception as e:
        return {'result': 'fail', 'msg': str(e)}

def cpe_unprovision(name):
    # logger.info("[WebUI:cpe_poll] cpe_unprovision! cpe=%s" % name)
    try:
        b = Brok('unprovision_host', {'host_name': name})
        app.from_q.put(b)
        return {'result': 'ok'}
    except Exception as e:
        return {'result': 'fail', 'msg': str(e)}

def cpe_test(name):
    return {'result': 'ok'}

pages = {
    json_cpe: {
        'name': 'CPE-JSON', 'route': '/cpe_poll/:cpe_name'
    },
    cpe_reboot:      { 'name': 'cpe_reboot'     , 'route': '/cpe_poll/reboot/:name' },
    cpe_unprovision: { 'name': 'cpe_unprovision', 'route': '/cpe_poll/unprovision/:name' },
    cpe_factory:     { 'name': 'cpe_factory'    , 'route': '/cpe_poll/factory/:name' },
    cpe_tr069:       { 'name': 'cpe_tr069'      , 'route': '/cpe_poll/tr069/:name' },

    cpe_test:       { 'name': 'cpe_test'      , 'route': '/cpe_poll/test/:name' }
}
