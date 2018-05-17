#!/usr/bin/python
# -*- coding: utf-8 -*-

from shinken.log import logger
from shinken.misc.perfdata import PerfDatas
from shinken.objects.service import Service
from shinken.objects.host import Host

from collections import OrderedDict

import re

app = None

def _metric_to_json(m):
    return dict(name=m.name, value=m.value, uom=m.uom, warning=m.warning, critical=m.critical, min=m.min, max=m.max)


def show_technical():
    return show_technical_table()

def show_mavis_mode():
    return show_technical_table()

def show_technical_table():

    user = app.request.environ['USER']
    search = app.request.query.get('search', "type:host")
    return {'search': search}


def show_technical_json():

    user = app.request.environ['USER']
    #
    search = app.request.query.get('search', "type:host")
    draw = app.request.query.get('draw', "")

    start  = int(app.request.query.get('start', None) or 0)
    length = int(app.request.query.get('length', None) or 5000)


    items = app.datamgr.search_hosts_and_services(search, user, get_impacts=False)

    data = list()

    hosts = dict()

    _headers = set()
    _groups  = OrderedDict()

    #for h in items:
    #    logger.warning("busqueda::%s" % type(h) )

    hosts_items = [item for item in items if isinstance(item, Host)]

    for h in hosts_items:
        _host = h.get_name()
        if not hosts.get(_host):
            hosts[_host] = dict()

        if hasattr(h,'perf_data'):
            perfdatas = PerfDatas(h.perf_data)
            for m in perfdatas:
                _metric = _metric_to_json(m)
                _name  = _metric.get('name')
                p = re.compile(r"\w+\d+")
                if p.search(_name):
                    continue
                hosts[_host][_name] = _metric
                if not _name in _headers:
                    _headers.add(_name)
                    if not _groups.get('host'):
                        _groups['host'] = list()
                    _groups['host'].append(_name)

        for s in h.services:
            _group = s.get_name()
            if not _groups.get(_group):
                _groups[_group] = list()

            perfdatas = PerfDatas(s.perf_data)
            for m in perfdatas:
                _metric = _metric_to_json(m)
                _name  = _metric.get('name')
                p = re.compile(r"\w+\d+")
                if p.search(_name):
                    continue

                hosts[_host][_name] = _metric
                if not _name in _headers:
                    _headers.add(_name)
                    _groups[_group].append(_name)


    for key, value in hosts.iteritems():
        if not value:
            continue
        _temp = {'host': key}
        for _kk, _vv in value.iteritems():
            _temp[_kk] = _vv

        data.append(_temp)

    xdata = {
        'draw': draw,
        'data': data[start:int(start+length)],
        'recordsFiltered': len(data),
        'recordsTotal': len(data),
        'headers': list(_headers),
        'groups': _groups
    }

    # xdata.update(columns=[
    #     ['title', 'name'],
    #     ['title', 'value'],
    #     ['title', 'uom'],
    #     ['title', 'warning'],
    #     ['title', 'critical'],
    #     ['title', 'min'],
    #     ['title', 'max']
    # ])


    return xdata

pages = {
    show_mavis_mode: {
        'name': 'technical', 'route': '/mavis', 'view': 'technical', 'static': True, 'search_engine': True
    },
    show_technical: {
        'name': 'technical', 'route': '/technical', 'view': 'technical', 'static': True, 'search_engine': True
    },
    show_technical_table: {
        'name': 'technical', 'route': '/technical/table', 'view': 'technical', 'static': True, 'search_engine': True
    },
    show_technical_json: {
        'name': 'technical', 'route': '/technical/json'
    }

}
