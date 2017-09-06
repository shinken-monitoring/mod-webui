#!/usr/bin/python

# -*- coding: utf-8 -*-

import time
import json

from shinken.log import logger
from shinken.external_command import ExternalCommand, ExternalCommandManager

# Will be populated by the UI with it's own value
app = None

def _get_logs(*args, **kwargs):
    if app.logs_module.is_available():
        return app.logs_module.get_ui_logs(*args, **kwargs)
    else:
        logger.warning("[WebUI-logs] no get history external module defined!")
        return None

def get_timeline(name):
    user = app.request.environ['USER']
    elt = app.datamgr.get_element(name, user) or app.redirect404()
    logs = _get_logs(elt=elt)

    timeline = {}

    maxtime = int(time.time())
    mintime = maxtime - 24 * 3600 * 7

    # Ordenamos los logs en base al timestamp
    _logs_sorted = sorted(logs, key=lambda k: k.get('timestamp'))


    for log in _logs_sorted:
        _service = log.get('service')
        if not len(_service):
            _service = 'host'

        if not isinstance(timeline.get(_service), dict):
            timeline[_service] = {'times': []}

        if len(timeline.get(_service).get('times')) >= 1:
            last_item = timeline.get(_service).get('times')[-1]
            last_item['end'] = log.get('timestamp')
            last_item['diff'] = last_item['end'] - last_item['start']

        timeline[_service].get('times').append({
            'start': log.get('timestamp'),
            'end': maxtime,
            'state': log.get('state'),
            'message': log.get('message')
        })



    return json.dumps(timeline)


# Our page
def show_cpe2(name):

    cpe = None
    parent = None

    ''' Mostrar la ficha del CPE con nombre cpe_name.'''
    # Ok, we can lookup it
    user = app.bottle.request.environ['USER']

    # if not cpe_name.startswith('cpe'):
        # app.redirect404()

    cpe = app.datamgr.get_host(name, user) or app.redirect404()

    if cpe.cpe_registration_host:
        parent = app.datamgr.get_host(cpe.cpe_registration_host, user)

    # Set hostgroups level ...
    app.datamgr.set_hostgroups_level(user)

    # Get graph data. By default, show last 4 hours
    maxtime = int(time.time())
    mintime = maxtime - 24 * 3600

    elt = app.datamgr.get_element(name, user) or app.redirect404()
    logs = _get_logs(elt=elt)

    return {'cpe': cpe, 'parent': parent, 'mintime': mintime, 'maxtime': maxtime, 'logs': logs}

pages = {
    show_cpe2: {
        'name': 'CPE', 'route': '/cpe2/:name', 'view': 'cpe2', 'static': True
    },
    get_timeline: {
        'name': 'CPE', 'route': '/timeline/:name'
    }
}
