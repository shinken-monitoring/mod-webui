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

import re
from shinken.misc.perfdata import PerfDatas

### Will be populated by the UI with it's own value
app = None

# Get plugin's parameters from configuration file
# Define service/perfdata name for each element in graph
params = {}
params['view_name'] = "cv_kiosk"
params['svc_cpu_name'] = "cpu"
params['svc_cpu_used'] = "total (.*)"
params['svc_disk_name'] = "disk"
params['svc_disk_used'] = "^[A-Z]: used %$"
params['svc_mem_name'] = "memory"
params['svc_mem_used'] = "^(.*) %$"
params['svc_printer_name'] = "printer"
params['svc_printer_used'] = "^(.*) Pages$"
params['svc_net_name'] = "network"
params['svc_net_used'] = "CurrentBandwidth|BytesReceivedPersec|BytesSentPersec"

import os,sys
from shinken.log import logger
from webui.config_parser import config_parser
plugin_name = os.path.splitext(os.path.basename(__file__))[0]
try:
    currentdir = os.path.dirname(os.path.realpath(__file__))
    configuration_file = "%s/%s" % (currentdir, 'plugin.cfg')
    logger.debug("Plugin configuration file: %s", configuration_file)
    scp = config_parser('#', '=')
    z = params.copy()
    z.update(scp.parse_config(configuration_file))
    params = z

    logger.info("[WebUI-cvkiosk] configuration loaded.")
    logger.info("[WebUI-cvkiosk] configuration, view: %s", params['view_name'])
    logger.info("[WebUI-cvkiosk] configuration, cpu: %s (%s)", params['svc_cpu_name'], params['svc_cpu_used'])
    logger.info("[WebUI-cvkiosk] configuration, disk: %s (%s)", params['svc_disk_name'], params['svc_disk_used'])
    logger.info("[WebUI-cvkiosk] configuration, memory: %s (%s)", params['svc_mem_name'], params['svc_mem_used'])
    logger.info("[WebUI-cvkiosk] configuration, network: %s (%s)", params['svc_net_name'], params['svc_net_used'])
except Exception, exp:
    logger.warning("[WebUI-cvkiosk] configuration file (%s) not available: %s", configuration_file, str(exp))


def _findServiceByName(host, service):
    for s in host.services:
        if re.search(service, s.get_name()):
            return s
    return None
    
    
def get_disks(h):
    # all = []
    all = {}
    state = 'UNKNOWN'
    
    s = _findServiceByName(h, params['svc_disk_name'])
    if s:
        logger.info("[WebUI-cvkiosk], found %s", s.get_full_name())
        state = s.state
        
        try:
            p = PerfDatas(s.perf_data)
            for m in p:
                if m.name and m.value is not None:
                    logger.info("[WebUI-cvkiosk], metric '%s' = %s", m.name, m.value)
                    if re.match(params['svc_disk_used'], m.name):
                        all[m.name] = m.value
                        logger.info("[WebUI-cvkiosk], got '%s' = %s", m.name, m.value)
        except Exception, exp:
            logger.warning("[WebUI-cvkiosk] get_disks, exception: %s", str(exp))

    logger.info("[WebUI-cvkiosk], get_disks %s", all)
    return state, all


def get_memory(h):
    # all = []
    all = {}
    state = 'UNKNOWN'
    
    s = _findServiceByName(h, params['svc_mem_name'])
    if s:
        logger.info("[WebUI-cvkiosk], found %s", s.get_full_name())
        state = s.state

        try:
            p = PerfDatas(s.perf_data)
            for m in p:
                if m.name and m.value is not None:
                    logger.info("[WebUI-cvkiosk], metric '%s' = %s", m.name, m.value)
                    if re.match(params['svc_mem_used'], m.name):
                        logger.info("[WebUI-cvkiosk], got '%s' = %s", m.name, m.value)
                        # all.append({m.name, m.value})
                        all[m.name] = m.value
        except Exception, exp:
            logger.warning("[WebUI-cvkiosk] get_memory, exception: %s", str(exp))

    logger.info("[WebUI-cvkiosk], get_memory %s", all)
    return state, all


def get_cpu(h):
    # all = []
    all = {}
    state = 'UNKNOWN'
    
    s = _findServiceByName(h, params['svc_cpu_name'])
    if s:
        logger.info("[WebUI-cvkiosk], found %s", s.get_full_name())
        state = s.state

        try:
            p = PerfDatas(s.perf_data)
            for m in p:
                if m.name and m.value is not None:
                    logger.info("[WebUI-cvkiosk], metric '%s' = %s", m.name, m.value)
                    if re.match(params['svc_cpu_used'], m.name):
                        logger.debug("[WebUI-cvkiosk], got '%s' = %s", m.name, m.value)
                        all[m.name] = m.value
        except Exception, exp:
            logger.warning("[WebUI-cvkiosk] get_cpu, exception: %s", str(exp))

    logger.info("[WebUI-cvkiosk], get_cpu %s", all)
    return state, all


def get_network(h):
    # all = []
    all = {}
    state = 'UNKNOWN'
    
    s = _findServiceByName(h, params['svc_net_name'])
    if s:
        logger.info("[WebUI-cvkiosk], found %s", s.get_full_name())
        state = s.state

        try:
            p = PerfDatas(s.perf_data)
            for m in p:
                if m.name and m.value is not None:
                    logger.info("[WebUI-cvkiosk], metric '%s' = %s", m.name, m.value)
                    if re.match(params['svc_net_used'], m.name):
                        logger.info("[WebUI-cvkiosk], got bandwidth %s = %s", m.name, m.value)
                        # all.append({"Bandwidth", float(m.value)})
                        # all["Bandwidth"] = m.value
                        all[m.name] = m.value
                    # if re.match(params['svc_net_received'], m.name):
                        # logger.info("[WebUI-cvkiosk], got bandwidth %s = %s", m.name, m.value)
                        # all["Received"] = m.value
                    # if re.match(params['svc_net_sent'], m.name):
                        # logger.info("[WebUI-cvkiosk], got bandwidth %s = %s", m.name, m.value)
                        # all["Sent"] = m.value
        except Exception, exp:
            logger.warning("[WebUI-cvkiosk] get_network, exception: %s", str(exp))

    logger.info("[WebUI-cvkiosk], get_network %s", all)
    return state, all
    
    
def get_printer(h):
    # all = []
    all = {}
    state = 'UNKNOWN'
    
    s = _findServiceByName(h, params['svc_printer_name'])
    if s:
        logger.info("[WebUI-cvkiosk], found %s", s.get_full_name())
        state = s.state

        try:
            p = PerfDatas(s.perf_data)
            for m in p:
                if m.name and m.value is not None:
                    logger.info("[WebUI-cvkiosk], metric '%s' = %s", m.name, m.value)
                    if re.match(params['svc_printer_used'], m.name):
                        logger.debug("[WebUI-cvkiosk], got '%s' = %s", m.name, m.value)
                        # all.append({m.name, m.value})
                        all[m.name] = m.value
        except Exception, exp:
            logger.warning("[WebUI-cvkiosk] get_printer, exception: %s", str(exp))

    logger.info("[WebUI-cvkiosk], get_printer %s", all)
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
    
    logger.info("[WebUI-cvkiosk], get_services %s", all)
    return state, all


def compute_worst_state(all_states):
    _ref = {'OK':0, 'UP':0, 'DOWN':3, 'UNREACHABLE':1, 'UNKNOWN':1, 'CRITICAL':3, 'WARNING':2, 'PENDING' :1, 'ACK' :1, 'DOWNTIME' :1}
    cur_level = 0
    for (k,v) in all_states.iteritems():
        logger.info("[WebUI-cvkiosk], compute_worst_state: %s/%s", k, v)
        level = _ref[v]
        cur_level = max(cur_level, level)
    return {3:'CRITICAL', 2:'WARNING', 1:'UNKNOWN', 0:'OK'}[cur_level]


def get_page(hname):
    user = app.check_user_authentication()

    logger.info("[WebUI-cvkiosk], get_page for %s", hname)

    all_perfs = {}
    all_states = {"global": 'UNKNOWN', "cpu": 'UNKNOWN', "disks": 'UNKNOWN', "memory": 'UNKNOWN', "network": 'UNKNOWN', "printer": 'UNKNOWN', "services": 'UNKNOWN', "global": 'UNKNOWN'}
    
    # Ok, we can lookup it
    h = app.get_host(hname)
    if h:
        # Set the host state first
        all_states["host"] = h.state
        # First look at disks
        all_states["disks"], all_perfs['disks'] = get_disks(h)
        # Then memory
        all_states["memory"], all_perfs['memory']  = get_memory(h)
        # And CPU too
        all_states['cpu'], all_perfs['cpu'] = get_cpu(h)
        # Then printer
        all_states['printer'], all_perfs['printer'] = get_printer(h)
        # And Network
        all_states['network'], all_perfs['network'] = get_network(h)
        # And services
        all_states['services'], all_perfs['services'] = get_services(h)
        # Then global
        all_states["global"] = compute_worst_state(all_states)
        
    logger.info("[WebUI-cvkiosk], overall state: %s", all_states)
        
    return {'app': app, 'elt': h, 'all_perfs':all_perfs, 'all_states':all_states, 'view_name':params['view_name']}


# Void plugin
pages = {get_page: {'routes': ['/cv/kiosk/:hname'], 'view': 'cv_kiosk', 'static': True}}
