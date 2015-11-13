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

import os,sys,re
from shinken.misc.perfdata import PerfDatas
from shinken.log import logger
from webui2.config_parser import config_parser
plugin_name = os.path.splitext(os.path.basename(__file__))[0]

### Will be populated by the UI with it's own value
app = None

# Get plugin's parameters from configuration file
# Define service/perfdata name for each element in graph
params = {}
params['svc_load_name'] = "load"
params['svc_load_used'] = "load1|load5|load15"
params['svc_load_uom'] = ""
params['svc_cpu_name'] = "cpu|CPU"
params['svc_cpu_used'] = "^cpu_all_idle|cpu_all_iowait|cpu_all_usr|cpu_all_nice"
params['svc_cpu_uom'] = "^%$"
params['svc_dsk_name'] = "disks|Disks"
params['svc_dsk_used'] = "^(.*)used_pct$"
params['svc_dsk_uom'] = "^%$"
params['svc_mem_name'] = "memory|Memory"
params['svc_mem_used'] = "^(.*)$"
params['svc_mem_uom'] = "^%$"
params['svc_net_name'] = "NET Stats"
params['svc_net_used'] = "eth0_rx_by_sec|eth0_tx_by_sec|eth0_rxErrs_by_sec|eth0_txErrs_by_sec"
params['svc_net_uom'] = "p/s"


def _findServiceByName(host, service):
    for s in host.services:
        if re.search(service, s.get_name()):
            return s
    return None


def get_disks(h):
    all = {}
    state = 'UNKNOWN'

    s = _findServiceByName(h, params['svc_dsk_name'])
    if s:
        logger.debug("[WebUI-cvhost], found %s", s.get_full_name())
        state = s.state

        try:
            p = PerfDatas(s.perf_data)
            for m in p:
                if m.name and m.value is not None:
                    logger.debug("[WebUI-cvhost], metric '%s' = %s, uom: %s", m.name, m.value, m.uom)
                    if re.search(params['svc_dsk_used'], m.name) and re.match(params['svc_dsk_uom'], m.uom):
                        all[m.name] = m.value
                        logger.debug("[WebUI-cvhost], got '%s' = %s", m.name, m.value)
        except Exception, exp:
            logger.warning("[WebUI-cvhost] get_disks, exception: %s", str(exp))

    logger.debug("[WebUI-cvhost], get_disks %s", all)
    return state, all


def get_memory(h):
    all = {}
    state = 'UNKNOWN'

    s = _findServiceByName(h, params['svc_mem_name'])
    if s:
        logger.debug("[WebUI-cvhost], found %s", s.get_full_name())
        state = s.state

        try:
            p = PerfDatas(s.perf_data)
            for m in p:
                if m.name and m.value is not None:
                    logger.debug("[WebUI-cvhost], metric '%s' = %s, uom: %s", m.name, m.value, m.uom)
                    if re.search(params['svc_mem_used'], m.name) and re.match(params['svc_mem_uom'], m.uom):
                        logger.debug("[WebUI-cvhost], got '%s' = %s", m.name, m.value)
                        all[m.name] = m.value
        except Exception, exp:
            logger.warning("[WebUI-cvhost] get_memory, exception: %s", str(exp))

    logger.debug("[WebUI-cvhost], get_memory %s", all)
    return state, all


def get_cpu(h):
    all = {}
    state = 'UNKNOWN'

    s = _findServiceByName(h, params['svc_cpu_name'])
    if s:
        logger.debug("[WebUI-cvhost], found %s", s.get_full_name())
        state = s.state

        try:
            p = PerfDatas(s.perf_data)
            for m in p:
                if m.name and m.value is not None:
                    logger.debug("[WebUI-cvhost], metric '%s' = %s, uom: %s", m.name, m.value, m.uom)
                    if re.search(params['svc_cpu_used'], m.name) and re.match(params['svc_cpu_uom'], m.uom):
                        logger.debug("[WebUI-cvhost], got '%s' = %s", m.name, m.value)
                        all[m.name] = m.value
        except Exception, exp:
            logger.warning("[WebUI-cvhost] get_cpu, exception: %s", str(exp))

    logger.debug("[WebUI-cvhost], get_cpu %s", all)
    return state, all


def get_load(h):
    all = {}
    state = 'UNKNOWN'

    s = _findServiceByName(h, params['svc_load_name'])
    if s:
        logger.debug("[WebUI-cvhost], found %s", s.get_full_name())
        state = s.state

        try:
            p = PerfDatas(s.perf_data)
            for m in p:
                if m.name and m.value is not None:
                    logger.debug("[WebUI-cvhost], metric '%s' = %s, uom: %s", m.name, m.value, m.uom)
                    if re.search(params['svc_load_used'], m.name) and re.match(params['svc_load_uom'], m.uom):
                        logger.debug("[WebUI-cvhost], got '%s' = %s", m.name, m.value)
                        all[m.name] = m.value
        except Exception, exp:
            logger.warning("[WebUI-cvhost] get_load, exception: %s", str(exp))

    logger.debug("[WebUI-cvhost], get_load %s", all)
    return state, all


def get_network(h):
    # all = []
    all = {}
    state = 'UNKNOWN'

    s = _findServiceByName(h, params['svc_net_name'])
    if s:
        logger.debug("[WebUI-cvhost], found %s", s.get_full_name())
        state = s.state

        try:
            p = PerfDatas(s.perf_data)
            for m in p:
                if m.name and m.value is not None:
                    logger.debug("[WebUI-cvhost], metric '%s' = %s, uom: %s", m.name, m.value, m.uom)
                    if re.search(params['svc_net_used'], m.name) and re.match(params['svc_net_uom'], m.uom):
                        logger.debug("[WebUI-cvhost], got '%s' = %s", m.name, m.value)
                        all[m.name] = m.value
        except Exception, exp:
            logger.warning("[WebUI-cvhost] get_network, exception: %s", str(exp))

    logger.debug("[WebUI-cvhost], get_network %s", all)
    return state, all


def get_printer(h):
    all = {}
    state = 'UNKNOWN'

    s = _findServiceByName(h, params['svc_prn_name'])
    if s:
        logger.debug("[WebUI-cvhost], found %s", s.get_full_name())
        state = s.state

        try:
            p = PerfDatas(s.perf_data)
            for m in p:
                if m.name and m.value is not None:
                    logger.debug("[WebUI-cvhost], metric '%s' = %s, uom: %s", m.name, m.value, m.uom)
                    if re.search(params['svc_prn_used'], m.name) and re.match(params['svc_prn_uom'], m.uom):
                        logger.debug("[WebUI-cvhost], got '%s' = %s", m.name, m.value)
                        all[m.name] = m.value
        except Exception, exp:
            logger.warning("[WebUI-cvhost] get_printer, exception: %s", str(exp))

    logger.debug("[WebUI-cvhost], get_printer %s", all)
    return state, all


def get_services(h):
    # all = []
    all = {}
    state = 'UNKNOWN'

    # Get host's services list
    for s in h.services:
        state = max(state, s.state_id)

        view_state = s.state
        if s.problem_has_been_acknowledged:
            view_state = 'ACK'
        if s.in_scheduled_downtime:
            view_state = 'DOWNTIME'
        # all.append((s.get_name(), view_state))
        all[s.get_name()] = view_state
        # services_states[s.get_name()] = s.state

    # Compute the worst state of all packages
    state = compute_worst_state(all)

    logger.debug("[WebUI-cvhost], get_services %s", all)
    return state, all


def compute_worst_state(all_states):
    _ref = {'OK':0, 'UP':0, 'DOWN':3, 'UNREACHABLE':1, 'UNKNOWN':1, 'CRITICAL':3, 'WARNING':2, 'PENDING' :1, 'ACK' :1, 'DOWNTIME' :1}
    cur_level = 0
    for (k,v) in all_states.iteritems():
        logger.debug("[WebUI-cvhost], compute_worst_state: %s/%s", k, v)
        level = _ref[v]
        cur_level = max(cur_level, level)
    return {3:'CRITICAL', 2:'WARNING', 1:'UNKNOWN', 0:'OK'}[cur_level]


def get_page(name, type):
    global params

    # user = app.check_user_authentication()

    logger.debug("[WebUI-cvhost], get_page for %s, type: '%s'", name, type)

    try:
        currentdir = os.path.dirname(os.path.realpath(__file__))
        configuration_file = "%s/%s.cfg" % (currentdir, type)
        logger.debug("Plugin configuration file: %s", configuration_file)
        scp = config_parser('#', '=')
        z = params.copy()
        z.update(scp.parse_config(configuration_file))
        params = z

        logger.debug("[WebUI-cvhost] configuration loaded.")
        logger.debug("[WebUI-cvhost] configuration, load: %s (%s)", params['svc_load_name'], params['svc_load_used'])
        logger.debug("[WebUI-cvhost] configuration, cpu: %s (%s)", params['svc_cpu_name'], params['svc_cpu_used'])
        logger.debug("[WebUI-cvhost] configuration, disk: %s (%s)", params['svc_dsk_name'], params['svc_dsk_used'])
        logger.debug("[WebUI-cvhost] configuration, memory: %s (%s)", params['svc_mem_name'], params['svc_mem_used'])
        logger.debug("[WebUI-cvhost] configuration, network: %s (%s)", params['svc_net_name'], params['svc_net_used'])
        # logger.info("[WebUI-cvhost] configuration, printer: %s (%s)", params['svc_prn_name'], params['svc_prn_used'])
    except Exception, exp:
        logger.warning("[WebUI-cvhost] configuration file (%s) not available or bad formed: %s", configuration_file, str(exp))
        app.redirect404()
        all_perfs = {}
        all_states = {}
        return {'app': app, 'config': type, 'all_perfs':all_perfs, 'all_states':all_states}

    all_perfs = {}
    all_states = {"global": 'UNKNOWN', "cpu": 'UNKNOWN', "disks": 'UNKNOWN', "memory": 'UNKNOWN', "network": 'UNKNOWN', "printer": 'UNKNOWN', "services": 'UNKNOWN', "global": 'UNKNOWN'}

    # Ok, we can lookup it
    user = app.request.environ['USER']
    host = app.datamgr.get_host(name, user) or app.redirect404()

    # Set the host state first
    all_states["host"] = host.state
    if host.is_problem and host.problem_has_been_acknowledged:
        all_states["host"] = 'ACK'
    if host.in_scheduled_downtime:
        all_states["host"] = 'DOWNTIME'
    # First look at disks
    all_states["disks"], all_perfs['disks'] = get_disks(host)
    # Then memory
    all_states["memory"], all_perfs['memory']  = get_memory(host)
    # Then CPU
    all_states['cpu'], all_perfs['cpu'] = get_cpu(host)
    # Then load
    all_states['load'], all_perfs['load'] = get_load(host)
    # Then printer ... TODO: later if needed !
    # all_states['printer'], all_perfs['printer'] = get_printer(host)
    # And Network
    all_states['network'], all_perfs['network'] = get_network(host)
    # And services
    all_states['services'], all_perfs['services'] = get_services(host)
    # Then global
    all_states["global"] = compute_worst_state(all_states)

    logger.debug("[WebUI-cvhost] overall state: %s", all_states)

    return {'app': app, 'elt': host, 'config': type, 'all_perfs':all_perfs, 'all_states':all_states}


pages = {
    get_page: {
        'name': 'CustomView', 'route': '/cv/<name:path>/<type:path>', 'view': 'cv_host', 'static': True
    }
}
