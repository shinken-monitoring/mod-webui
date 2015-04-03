#!/usr/bin/python

# -*- coding: utf-8 -*-

# Copyright (C) 2009-2012:
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

import re
from shinken.misc.perfdata import PerfDatas

### Will be populated by the UI with it's own value
app = None

# Get plugin's parameters from configuration file
params = {}
params['view_name'] = "cv_linux-nrpe"
params['svc_cpu_name'] = "cpu"
params['svc_cpu_used'] = "cpu_prct_used"
params['svc_disk_name'] = "disk"
params['svc_mem_name'] = "mem"
params['svc_mem_ram_used'] = "ram_used"
params['svc_mem_swap_used'] = "swap_used"

import os,sys
from shinken.log import logger
from webui.config_parser import config_parser
plugin_name = os.path.splitext(os.path.basename(__file__))[0]
try:
    currentdir = os.path.dirname(os.path.realpath(__file__))
    configuration_file = "%s/%s" % (currentdir, 'plugin.cfg')
    logger.debug("Plugin configuration file: %s", configuration_file)
    scp = config_parser('#', '=')
    params = scp.parse_config(configuration_file)

    logger.debug("WebUI plugin '%s', configuration loaded.", plugin_name)
    logger.debug("Plugin %s configuration, view: %s", plugin_name, params['view_name'])
    logger.debug("Plugin %s configuration, cpu: %s (%s)", plugin_name, params['svc_cpu_name'], params['svc_cpu_used'])
    logger.debug("Plugin %s configuration, disk: %s (%s)", plugin_name, params['svc_disk_name'], params['svc_disk_used'])
    logger.debug("Plugin %s configuration, memory: %s (%s / %s)", plugin_name, params['svc_mem_name'], params['svc_mem_ram_used'], params['svc_mem_swap_used'])
except Exception, exp:
    logger.warning("WebUI plugin '%s', configuration file (%s) not available: %s", plugin_name, configuration_file, str(exp))

def _findServiceByName(host, service):
    for s in host.services:
        if re.search(service, s.get_name()):
            return s
    return None
    
    
def get_disks(h):
    all_disks = []
    s = _findServiceByName(h, params['svc_disk_name'])
    if not s:
        return 'UNKNOWN',all_disks

    disks_state = s.state
    p = PerfDatas(s.perf_data)

    if params['svc_disk_used'] in p:
        m = p[params['svc_disk_used']]
        # Maybe it's an invalid metric?
        if m.name and m.value is not None and m.max is not None and m.max != 0:
            # Classic pct compute
            pct = 100*float(m.value)/m.max
            mem = int(pct)

            all_disks.append((m.name, pct))
            
    for m in p:
        # Maybe it's an invalid metric?
        if not m.name or m.value is None or m.max is None or m.max == 0:
            continue
        # Skip device we don't care about
        # if m.name == '/dev' or m.name.startswith('/sys/'):
            # continue

        pct = 100*float(m.value)/m.max
        pct = int(pct)

        all_disks.append((m.name, pct))

    return disks_state,all_disks


def get_memory(h):
    mem_state = swap_state = 'UNKNOWN'
    s = _findServiceByName(h, params['svc_mem_name'])
    if not s:
        return (mem_state,swap_state,0,0)

    mem_state = swap_state = s.state
    # Now grep perfdata in it
    p = PerfDatas(s.perf_data)
    mem = 0
    swap = 0

    if params['svc_mem_ram_used'] in p:
        m = p[params['svc_mem_ram_used']]
        # Maybe it's an invalid metric?
        if m.name and m.value is not None and m.max is not None and m.max != 0:
            # Classic pct compute
            pct = 100*float(m.value)/m.max
            mem = int(pct)

    if params['svc_mem_swap_used'] in p:
        m = p[params['svc_mem_swap_used']]
        # Maybe it's an invalid metric?
        if m.name and m.value is not None and m.max is not None and m.max != 0:
            # Classic pct compute
            pct = 100*float(m.value)/m.max
            swap = int(pct)

    return mem_state,swap_state,mem,swap


def get_cpu(h):
    cpu_state = 'UNKNOWN'
    s = _findServiceByName(h, params['svc_cpu_name'])
    if not s:
        return 'UNKNOWN',0

    cpu_state = s.state
    # Now perfdata
    p = PerfDatas(s.perf_data)
    cpu = 0

    if params['svc_cpu_used'] in p:
        m = p[params['svc_cpu_used']]
        # Maybe it's an invalid metric?
        if m.name and m.value is not None:
            cpu = m.value
            print "Cpu", m.value

    return cpu_state, cpu


def get_printer(h):
    s = _findServiceByName(h, 'printer')
    if not s:
        return 'UNKNOWN',0
    print "Service found", s.get_full_name()

    printed_pages = 0
    printer_state = s.state
    
    # Now perfdata
    p = PerfDatas(s.perf_data)
    # p = PerfDatas("'CutPages'=12[c];;;; 'RetractedPages'=8[c];;;;")
    print "PERFDATA", p, p.__dict__
    
    if 'CutPages' in p:
        m = p['CutPages']
        if m.name and m.value is not None:
            printed_pages = m.value
    if 'Cut Pages' in p:
        m = p['Cut Pages']
        if m.name and m.value is not None:
            printed_pages = m.value
    # if 'Retracted Pages' in p:
        # m = p['Retracted Pages']
        # if m.name and m.value is not None:
            # retracted = m.value

    return printer_state, printed_pages


def get_network(h):
    all_nics = []
    network_state = 'UNKNOWN'
    s = _findServiceByName(h, 'network')
    if not s:
        return 'UNKNOWN',all_nics
    print "Service found", s.get_full_name()

    # Host perfdata
    p = PerfDatas(h.perf_data)
    print "PERFDATA", p, p.__dict__
    # all_nics.append(('perfdata', h.perf_data))
    
    network_state = s.state
    p = PerfDatas(s.perf_data)
    
    if 'BytesTotalPersec' in p:
        all_nics.append(('BytesTotalPersec', p['BytesTotalPersec'].value))
        
    if 'CurrentBandwidth' in p:
        all_nics.append(('CurrentBandwidth', p['CurrentBandwidth'].value))

    return network_state, all_nics
    
    
def get_services(h):
    all_services = []
    services_states = {}

    # Get host's services list
    for item in h.services:
        all_services.append((item.get_name(), item.state))
        services_states[item.get_name()] = item.state

    # Compute the worst state of all packages
    services_states = compute_worst_state(services_states)
    
    return services_states,all_services


def compute_worst_state(d):
    _ref = {'OK':0, 'UP':0, 'DOWN':3, 'UNREACHABLE':1, 'UNKNOWN':1, 'CRITICAL':3, 'WARNING':2, 'PENDING' :1}
    cur_level = 0
    for (k,v) in d.iteritems():
        level = _ref[v]
        cur_level = max(cur_level, level)
    return {3:'CRITICAL', 2:'WARNING', 1:'UNKNOWN', 0:'OK'}[cur_level]


def get_page(hname):
    # First we look for the user sid
    # so we bail out if it's a false one
    user = app.get_user_auth()

    if not user:
        app.bottle.redirect("/user/login")

    # Ok, we can lookup it
    h = app.datamgr.get_host(hname)

    all_perfs = {}
    all_states = {"global": "UNKNOWN", "cpu": "UNKNOWN", "disks": "UNKNOWN", "memory": "UNKNOWN", "virtual": "UNKNOWN", "paged": "UNKNOWN", "printer": "UNKNOWN"}

    if h:
        # Set the host state firt
        all_states["global"] = h.state
        # First look at disks
        all_states["disks"], all_perfs['all_disks'] = get_disks(h)
        # Then memory
        mem_state, swap_state, mem,swap = get_memory(h)
        all_perfs["memory"] = mem
        all_perfs["swap"] = swap
        all_states['swap'] = swap_state
        all_states['memory'] = mem_state
        # And CPU too
        all_states['cpu'], all_perfs['cpu'] = get_cpu(h)
        # Then printer
        all_states['printer'], all_perfs['printed_pages'] = get_printer(h)
        # And Network
        network_state, all_nics = get_network(h)
        all_perfs['all_nics'] = all_nics
        all_states['network'] = network_state
        # And services
        all_states['services'], all_perfs['all_services'] = get_services(h)
        # Then global
        all_states["view"] = compute_worst_state(all_states)
        
    return {'app': app, 'elt': h, 'all_perfs':all_perfs, 'all_states':all_states, 'view_name':params['view_name']}


# Void plugin
pages = {get_page: {'routes': ['/cv/linux-nrpe/:hname'], 'view': 'cv_linux-nrpe', 'static': True}}
