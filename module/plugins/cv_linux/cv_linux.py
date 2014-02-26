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

from shinken.misc.perfdata import PerfDatas

### Will be populated by the UI with it's own value
app = None

def _findServiceByName(host, service):
    for s in host.services:
        if service.lower() in s.get_name().lower():
            return s
    return None
    
    
def get_disks(h):
    all_disks = []
    s = _findServiceByName(h, 'disk')
    if not s:
        return 'UNKNOWN',all_disks
    print "Service found", s.get_full_name()

    disks_state = s.state
    p = PerfDatas(s.perf_data)
    print "PERFDATA", p, p.__dict__
    for m in p:
        print "KEY", m
        # Skip void disks?
        if not m.name or m.value is None or m.max is None or m.max == 0:
            continue
        # Skip device we don't care about
        if m.name == '/dev' or m.name.startswith('/sys/'):
            continue

        pct = 100*float(m.value)/m.max
        pct = int(pct)

        all_disks.append((m.name, pct))

    return disks_state,all_disks


def get_memory(h):

    mem_state = swap_state = 'UNKNOWN'

    s = _findServiceByName(h, 'memory')
    if not s:
        return (mem_state,swap_state,0,0)
    print "Service found", s.get_full_name()

    mem_state = swap_state = s.state
    # Now grep perfdata in it
    p = PerfDatas(s.perf_data)
    mem = 0
    swap = 0

    if 'ram_used' in p:
        m = p['ram_used']
        # Maybe it's an invalid metric?
        if m.name and m.value is not None and m.max is not None and m.max != 0:
            # Classic pct compute
            pct = 100*float(m.value)/m.max
            mem = int(pct)

    if 'swap_used' in p:
        m = p['swap_used']
        # Maybe it's an invalid metric?
        if m.name and m.value is not None and m.max is not None and m.max != 0:
            # Classic pct compute
            pct = 100*float(m.value)/m.max
            swap = int(pct)

    return mem_state,swap_state,mem,swap


def get_cpu(h):
    cpu_state = 'UNKNOWN'
    s = _findServiceByName(h, 'cpu')
    if not s:
        return 'UNKNOWN',0
    print "Service found", s.get_full_name()

    cpu_state = s.state
    # Now perfdata
    p = PerfDatas(s.perf_data)
    print "PERFDATA", p, p.__dict__
    cpu = 0

    if 'cpu_prct_used' in p:
        m = p['cpu_prct_used']
        # Maybe it's an invalid metric?
        if m.name and m.value is not None:
            cpu = m.value
            print "Cpu", m.value

    return cpu_state, cpu


def get_printer(h):
    printer_state = 'UNKNOWN'
    s = _findServiceByName(h, 'printer')
    if not s:
        return 'UNKNOWN',0,0
    print "Service found", s.get_full_name()

    return printer_state, cut, retracted
    
    
def get_network(h):
    all_nics = []
    network_state = 'UNKNOWN'
    s = _findServiceByName(h, 'network')
    if not s:
        return 'UNKNOWN',all_nics
    print "Service found", s.get_full_name()

    return network_state, all_nics
    
    
def get_services(h):
    all_services = []
    packages_state = {}

    # Get host's services list
    for item in h.services:
        all_services.append((item.get_name(), item.state))
        packages_state[item.get_name()] = item.state

    # Compute the worst state of all packages
    packages_state = compute_worst_state(packages_state)
    
    return packages_state,all_services


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
        printer_state, cut, retracted = get_printer(h)
        all_perfs["cut"] = cut
        all_perfs["retracted"] = retracted
        all_states['printer'] = printer_state
        # And Network
        network_state, all_nics = get_network(h)
        all_perfs['all_nics'] = all_nics
        all_states['network'] = network_state
        # And services
        all_states['services'], all_perfs['all_services'] = get_services(h)
        # Then global
        all_states["view"] = compute_worst_state(all_states)
        
    return {'app': app, 'elt': h, 'all_perfs':all_perfs, 'all_states':all_states}




# Void plugin
pages = {get_page: {'routes': ['/cv/linux/:hname'], 'view': 'cv_linux', 'static': True}}
