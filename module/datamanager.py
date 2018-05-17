#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright (C) 2009-2014:
#   Gabes Jean, naparuba@gmail.com
#   Gerhard Lausser, Gerhard.Lausser@consol.de
#   Gregory Starck, g.starck@gmail.com
#   Hartmut Goebel, h.goebel@goebel-consult.de
#   Frederic Mohier, frederic.mohier@gmail.com
#   Guillaume Subiron, maethor@subiron.org
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
import json
import itertools
import time
import operator
from shinken.log import logger

from shinken.misc.datamanager import DataManager
from shinken.objects.contact import Contact

# Import all objects we will need
from shinken.objects.host import Host, Hosts
from shinken.objects.hostgroup import Hostgroup, Hostgroups
from shinken.objects.service import Service, Services
from shinken.objects.servicegroup import Servicegroup, Servicegroups
from shinken.objects.contact import Contact, Contacts
from shinken.objects.contactgroup import Contactgroup, Contactgroups
from shinken.objects.notificationway import NotificationWay, NotificationWays
from shinken.objects.timeperiod import Timeperiod, Timeperiods
from shinken.objects.command import Command, Commands

from shinken.misc.perfdata import PerfDatas


# Sort hosts and services by impact, states and co
def hst_srv_sort(s1, s2):
    if s1.business_impact > s2.business_impact:
        return -1
    if s2.business_impact > s1.business_impact:
        return 1

    # Ok, we compute a importance value so
    # For host, the order is UP, UNREACH, DOWN
    # For service: OK, UNKNOWN, WARNING, CRIT
    # And DOWN is before CRITICAL (potential more impact)
    tab = {'host': {0: 0, 1: 4, 2: 1},
           'service': {0: 0, 1: 2, 2: 3, 3: 1}
           }
    state1 = tab[s1.__class__.my_type].get(s1.state_id, 0)
    state2 = tab[s2.__class__.my_type].get(s2.state_id, 0)
    # ok, here, same business_impact
    # Compare warn and crit state
    if state1 > state2:
        return -1
    if state2 > state1:
        return 1

    # Ok, so by name...
    if s1.get_full_name() > s2.get_full_name():
        return 1
    else:
        return -1


# Sort hosts and services by impact, states and co
def worse_first(s1, s2):
    # Ok, we compute a importance value so
    # For host, the order is UP, UNREACH, DOWN
    # For service: OK, UNKNOWN, WARNING, CRIT
    # And DOWN is before CRITICAL (potential more impact)
    tab = {'host': {0: 0, 1: 4, 2: 1},
           'service': {0: 0, 1: 2, 2: 3, 3: 1}
           }
    state1 = tab[s1.__class__.my_type].get(s1.state_id, 0)
    state2 = tab[s2.__class__.my_type].get(s2.state_id, 0)

    # ok, here, same business_impact
    # Compare warn and crit state
    if state1 > state2:
        return -1
    if state2 > state1:
        return 1

    # Same? ok by business impact
    if s1.business_impact > s2.business_impact:
        return -1
    if s2.business_impact > s1.business_impact:
        return 1

    # Ok, so by name...
    # Ok, so by name...
    if s1.get_full_name() > s2.get_full_name():
        return -1
    else:
        return 1


# Sort hosts and services by last_state_change time
def last_state_change_earlier(s1, s2):
    # ok, here, same business_impact
    # Compare warn and crit state
    if s1.last_state_change > s2.last_state_change:
        return -1
    if s1.last_state_change < s2.last_state_change:
        return 1

    return 0


class WebUIDataManager(DataManager):

    def __init__(self, rg=None, frontend=None, alignak=False):
        super(WebUIDataManager, self).__init__()
        self.rg = rg

        self.fe = frontend
        self.logged_in_user = None
        self.alignak = alignak if self.fe else False

    @staticmethod
    def _is_related_to(item, user):
        """
        """
        # if no user or user is an admin, always consider there is a relation
        if not user or user.is_administrator():
            return item

        logger.debug("[WebUI - relation], DM _is_related_to: %s", item.__class__)
        return user._is_related_to(item)

    @staticmethod
    def _only_related_to(items, user):
        """ This function is just a wrapper to _is_related_to for a list.

            :returns: List of elements related to the user
        """
        # if no user or user is an admin, always consider there is a relation
        if not user or user.is_administrator():
            return items

        try:
            logger.debug("[WebUI - relation], DM _only_related_to: %s", items)
            return [item for item in items if user._is_related_to(item)]
        except TypeError:
            return items if user._is_related_to(items) else None

    def set_logged_in_user(self, user):
        """ Set the logged in user
        """
        self.logged_in_user = user

    ##
    # Hosts
    ##
    def get_hosts(self, user=None, get_impacts=False):
        """ Get a list of all hosts.

            :param user: concerned user
            :param get_impacts: should impact hosts be included in the list?
            :returns: list of all hosts
        """
        items = self.search_hosts_and_services(
            'type:host' if not get_impacts else 'type:host is:impact',
            user
        )

        return items

    def get_host(self, name, user=None):
        """ Get a host by its hostname. """

        if self.alignak:
            parameters = {
                'where': json.dumps({
                    'name': name
                })
            }
            logger.debug("[WebUI - datamanager] get_host, backend parameters: %s", parameters)

            hosts = self.fe.get_hosts(parameters=parameters, all_elements=False, update=True)
            if hosts:
                logger.debug("[WebUI - datamanager] get_host, found: %s", hosts[0])
                return self._only_related_to(hosts[0], user)

            return None

        hosts = self.search_hosts_and_services('type:host host:^%s$' % (name), user=user)
        return hosts[0] if hosts else None

    def get_host_services(self, hname, user):
        """ Get host services by its hostname. """
        return self.search_hosts_and_services('type:service host:%s' % (hname), user=user)

    def get_percentage_hosts_state(self, user=None, problem=False):
        """ Get percentage of hosts not in (or in) problems.

            :param problem: False to return the % of hosts not in problems,
                            True to return the % of hosts in problems.
                            False by default
        """
        ### TODO: Use livestate
        ###
        all_hosts = self.get_hosts(user=user)
        if not all_hosts:
            return 0

        problems = [h for h in all_hosts if h.is_problem and not h.is_impact]

        if problem:
            return int((len(problems) * 100) / float(len(all_hosts)))
        else:
            return int(100 - (len(problems) * 100) / float(len(all_hosts)))

    def get_hosts_synthesis(self, elts=None, user=None):
        if elts != None:
            hosts = [item for item in elts if item.__class__.my_type == 'host']
        else:
            hosts = self.get_hosts(user=user)
        # logger.info("[WebUI - datamanager] get_hosts_synthesis, %d hosts", len(hosts))

        h = dict()
        h['nb_elts'] = len(hosts)
        if hosts:
            h['bi'] = max(h.business_impact for h in hosts)

            for state in 'up', 'pending':
                h['nb_' + state] = sum(1 for host in hosts if host.state == state.upper())
                h['pct_' + state] = round(100.0 * h['nb_' + state] / h['nb_elts'], 2)
            for state in 'down', 'unreachable', 'unknown':
                h['nb_' + state] = sum(1 for host in hosts if host.state == state.upper()  and not (host.problem_has_been_acknowledged or host.in_scheduled_downtime))
                h['pct_' + state] = round(100.0 * h['nb_' + state] / h['nb_elts'], 2)

            # h['nb_problems'] = sum(1 for host in hosts if host.is_problem and not host.problem_has_been_acknowledged)
            # Shinken does not always reflect the "problem" state ... to make UI more consistent, build our own problems counter!
            h['nb_problems'] = 0
            for host in hosts:
                if host.state.lower() in ['down', 'unreachable'] and not host.problem_has_been_acknowledged:
                    h['nb_problems'] += 1
                    # logger.debug("[WebUI - datamanager] get_hosts_synthesis: %s: %s, %s, %s", host.get_name(), host.state, host.is_problem, host.problem_has_been_acknowledged)

            h['pct_problems'] = round(100.0 * h['nb_problems'] / h['nb_elts'], 2)
            h['nb_ack'] = sum(1 for host in hosts if host.is_problem and host.problem_has_been_acknowledged)
            h['pct_ack'] = round(100.0 * h['nb_ack'] / h['nb_elts'], 2)
            h['nb_downtime'] = sum(1 for host in hosts if host.in_scheduled_downtime)
            h['pct_downtime'] = round(100.0 * h['nb_downtime'] / h['nb_elts'], 2)
        else:
            h['bi'] = 0
            for state in 'up', 'down', 'unreachable', 'pending', 'unknown', 'ack', 'downtime', 'problems':
                h['nb_' + state] = 0
                h['pct_' + state] = 0

        # logger.info("[WebUI - datamanager] get_hosts_synthesis: %s", h)
        return h

    ##
    # Services
    ##
    def get_services(self, user, get_impacts=False):
        """ Get a list of all services.

            :param user: concerned user
            :param get_impacts: should impact services be included in the list?
            :returns: list of all services
        """
        items = self.search_hosts_and_services(
            'type:service' if not get_impacts else 'type:service is:impact',
            user
        )

        return items

    def get_service(self, hname, sname, user):
        """ Get a service by its hostname and service description. """
        if self.alignak:
            parameters = {
                'where': json.dumps({
                    'host_name': hname, 'service_description': sname
                })
            }
            # logger.debug("[WebUI - datamanager] get_service, backend parameters: %s", parameters)

            services = self.fe.get_services(parameters=parameters, all_elements=False, update=True)
            if services:
                # logger.debug("[WebUI - datamanager] get_service, found: %s", services[0])
                return self._only_related_to(services[0], user)

            return None

        services = self.search_hosts_and_services('type:service host:^%s$ service:"^%s$"' % (hname, sname), user=user)
        return services[0] if services else None

    def get_percentage_service_state(self, user=None, problem=False):
        """ Get percentage of services not in (or in) problems.

            :param problem: False to return the % of services not in problems,
                            True to return the % of services in problems.
                            False by default
        """
        ### TODO: Use livestate
        ###
        all_services = self.get_services(user=user)
        if not all_services:
            return 0

        problems = [s for s in all_services if s.is_problem and not s.is_impact]

        if problem:
            return int((len(problems) * 100) / float(len(all_services)))
        else:
            return int(100 - (len(problems) * 100) / float(len(all_services)))

    def get_services_synthesis(self, elts=None, user=None):
        if elts != None:
            services = [item for item in elts if item.__class__.my_type == 'service']
        else:
            services = self.get_services(user=user)
        # logger.info("[WebUI - datamanager] get_services_synthesis, %d services", len(services))

        s = dict()
        s['nb_elts'] = len(services)
        if services:
            s['bi'] = max(s.business_impact for s in services)

            for state in 'ok', 'pending':
                s['nb_' + state] = sum(1 for service in services if service.state == state.upper())
                s['pct_' + state] = round(100.0 * s['nb_' + state] / s['nb_elts'], 2)
            for state in 'warning', 'critical', 'unknown':
                s['nb_' + state] = sum(1 for service in services if service.state == state.upper()  and not (service.problem_has_been_acknowledged or service.in_scheduled_downtime))
                s['pct_' + state] = round(100.0 * s['nb_' + state] / s['nb_elts'], 2)

            # s['nb_problems'] = sum(1 for service in services if service.is_problem and not service.problem_has_been_acknowledged)
            # Shinken does not always reflect the "problem" state ... to make UI more consistent, build our own problems counter!
            s['nb_problems'] = 0
            for service in services:
                if service.state.lower() in ['warning', 'critical'] and not service.problem_has_been_acknowledged:
                    s['nb_problems'] += 1
                    # logger.debug("[WebUI - datamanager] get_services_synthesis: %s: %s, %s, %s", service.get_name(), service.state, service.is_problem, service.problem_has_been_acknowledged)

            s['pct_problems'] = round(100.0 * s['nb_problems'] / s['nb_elts'], 2)
            s['nb_ack'] = sum(1 for service in services if service.is_problem and service.problem_has_been_acknowledged)
            s['pct_ack'] = round(100.0 * s['nb_ack'] / s['nb_elts'], 2)
            s['nb_downtime'] = sum(1 for service in services if service.in_scheduled_downtime)
            s['pct_downtime'] = round(100.0 * s['nb_downtime'] / s['nb_elts'], 2)
        else:
            s['bi'] = 0
            for state in 'ok', 'warning', 'critical', 'pending', 'unknown', 'ack', 'downtime', 'problems':
                s['nb_' + state] = 0
                s['pct_' + state] = 0

        # logger.info("[WebUI - datamanager] get_services_synthesis: %s", s)
        return s

    ##
    # Elements
    ##
    def get_element(self, name, user):
        """ Get an element by its name.
            :name: Must be "host" or "host/service"
        """
        if '/' in name:
            return self.get_service(name.split('/')[0], '/'.join(name.split('/')[1:]), user)
        else:
            host = self.get_host(name, user)
            if not host:
                return self.get_contact(name=name, user=user)
            return host

    ##
    # Searching
    ##
    def search_hosts_and_services(self, search, user, get_impacts=True, sorter=None):
        """ Search hosts and services.

            This method is the heart of the datamanager. All other methods should be based on this one.

            :search: Search string
            :user: concerned user
            :get_impacts: should impacts be included in the list?
            :sorter: function to sort the items. default=None (means no sorting)
            :returns: list of hosts and services
        """


        def _append_based_on_filtered_by_type(new_items, i, filtered_by_type):

            def _append_host_and_its_services(new_items, i):
                    def _doit(new_items, host):
                        if host not in new_items:
                            new_items.append(host)

                            for s in host.get_services():
                                if s not in new_items:
                                    new_items.append(s)

                    if i.my_type == 'host':
                        _doit(new_items, i)
                    elif i.my_type == 'service':
                        _doit(new_items, i.host)

            if filtered_by_type:
                if i not in new_items:
                    new_items.append(i)
            else:
                _append_host_and_its_services(new_items, i)


        def _filter_item(i):
            if pat.search(i.get_full_name()) or pat.search(i.output):
                return True
            for v in i.customs.values():
                if pat.search(v):
                    return True

            try:
                h = i if i.__class__.my_type == 'host' else i.host
                if h.address and pat.search(h.address):
                    return True
                if h.cpe_address and pat.search(h.cpe_address):
                    return True
                if h.cpe_registration_host and pat.search(h.cpe_registration_host):
                    return True
                if h.cpe_registration_id and pat.search(h.cpe_registration_id):
                    return True
                if h.cpe_registration_state and pat.search(h.cpe_registration_state):
                    return True
                if h.cpe_ipleases and pat.search(h.cpe_ipleases):
                    return True
            except Exception, exc:
                logger.warning("[WebUI - datamanager] _filter_item: (%s) - %s / %s", exc, type(h.cpe_ipleases), h.cpe_ipleases)


            return False

        # Make user an User object ... simple protection.
        if isinstance(user, basestring):
            user = self.rg.contacts.find_by_name(user)

        items = []
        if self.alignak and self.fe.initialized:
            logger.debug("[WebUI - datamanager] frontend hosts: %d items", len(self.fe.hosts))
            items.extend(
                self._only_related_to(
                    self.fe.hosts,
                    user
                )
            )
            logger.debug("[WebUI - datamanager] frontend services: %d items", len(self.fe.services))
            items.extend(
                self._only_related_to(
                    self.fe.services,
                    user
                )
            )

        else:
            items.extend(
                self._only_related_to(
                    super(WebUIDataManager, self).get_hosts(),
                    user
                )
            )
            items.extend(
                self._only_related_to(
                    super(WebUIDataManager, self).get_services(),
                    user
                )
            )

        logger.debug("[WebUI - datamanager] search_hosts_and_services, search for %s in %d items", search, len(items))

        # Search patterns like: isnot:0 isnot:ack isnot:"downtime fred" name "vm fred"
        regex = re.compile(
            r'''
                                    # 1/ Search a key:value pattern.
                (?P<key>\w+):       # Key consists of only a word followed by a colon
                (?P<quote2>["']?)   # Optional quote character.
                (?P<value>.*?)      # Value is a non greedy match
                (?P=quote2)         # Closing quote equals the first.
                ($|\s)              # Entry ends with whitespace or end of string
                |                   # OR
                                    # 2/ Search a single string quoted or not
                (?P<quote>["']?)    # Optional quote character.
                (?P<name>.*?)       # Name is a non greedy match
                (?P=quote)          # Closing quote equals the opening one.
                ($|\s)              # Entry ends with whitespace or end of string
            ''',
            re.VERBOSE
            )

        filtered_by_type = False
        patterns = []
        for match in regex.finditer(search):
            if match.group('name'):
                patterns.append( ('name', match.group('name')) )
            elif match.group('key'):
                patterns.append( (match.group('key'), match.group('value')) )
        logger.debug("[WebUI - datamanager] search patterns: %s", patterns)

        for t, s in patterns:
            t = t.lower()
            logger.debug("[WebUI - datamanager] searching for %s %s", t, s)

            if t == 'name':
                # Case insensitive
                pat = re.compile(s, re.IGNORECASE)
                new_items = []
                for i in items:
                    if _filter_item(i):
                        _append_based_on_filtered_by_type(new_items, i, filtered_by_type)
                    else:
                        for j in (i.impacts + i.source_problems):
                            if (pat.search(j.get_full_name()) or
                                (j.__class__.my_type == 'host' and
                                 j.alias and pat.search(j.alias))):
                                new_items.append(i)

                if not new_items:
                    for i in items:
                        if pat.search(i.output):
                            new_items.append(i)
                        else:
                            for j in (i.impacts + i.source_problems):
                                if pat.search(j.output):
                                    new_items.append(i)

                items = new_items

            if (t == 'h' or t == 'host') and s.lower() != 'all':
                logger.debug("[WebUI - datamanager] searching for an host %s", s)
                # Case sensitive
                pat = re.compile(s)
                new_items = []
                for i in items:
                    if i.__class__.my_type == 'host' and pat.search(i.get_name()):
                        new_items.append(i)
                    if i.__class__.my_type == 'service' and pat.search(i.host_name):
                        new_items.append(i)

                items = new_items
                logger.debug("[WebUI - datamanager] host:%s, %d matching items", s, len(items))
                # for item in items:
                #     logger.info("[WebUI - datamanager] item %s is %s", item.get_name(), item.__class__)

            if (t == 's' or t == 'service') and s.lower() != 'all':
                logger.debug("[WebUI - datamanager] searching for a service %s", s)
                pat = re.compile(s)
                new_items = []
                for i in items:
                    if i.__class__.my_type == 'service' and pat.search(i.get_name()):
                        new_items.append(i)

                items = new_items
                logger.debug("[WebUI - datamanager] service:%s, %d matching items", s, len(items))
                # for item in items:
                #     logger.info("[WebUI - datamanager] item %s is %s", item.get_name(), item.__class__)

            if (t == 'c' or t == 'contact') and s.lower() != 'all':
                logger.debug("[WebUI - datamanager] searching for a contact %s", s)
                pat = re.compile(s)
                new_items = []
                for i in items:
                    if i.__class__.my_type == 'contact' and pat.search(i.get_name()):
                        new_items.append(i)

                items = new_items

            if (t == 'hg' or t == 'hgroup') and s.lower() != 'all':
                logger.debug("[WebUI - datamanager] searching for items in the hostgroup %s", s)
                new_items = []
                for x in s.split('|'):
                    group = self.get_hostgroup(x)
                    if not group:
                        return []
                    # Items have a item.get_groupnames() method that returns a comma separated string ... strange format!
                    for item in items:
                        #if group.get_name() in item.get_groupnames().split(', '):
                            # logger.info("[WebUI - datamanager] => item %s is a known member!", item.get_name())

                        if group.get_name() in item.get_groupnames().split(', '):
                            new_items.append(item)
                items = new_items

            if (t == 'sg' or t == 'sgroup') and s.lower() != 'all':
                logger.debug("[WebUI - datamanager] searching for items in the servicegroup %s", s)
                group = self.get_servicegroup(s)
                if not group:
                    return []
                # Items have a item.get_groupnames() method that returns a comma+space separated string ... strange format!
                # for item in items:
                #     if group.get_name() in item.get_groupnames().split(','):
                #         logger.debug("[WebUI - datamanager] => item %s is a known member!", item.get_name())
                items = [i for i in items if group.get_name() in i.get_groupnames().split(',')]

            #@mohierf: to be refactored!
            if (t == 'cg' or t == 'cgroup') and s.lower() != 'all':
                # logger.info("[WebUI - datamanager] searching for items related with the contactgroup %s", s)
                group = self.get_contactgroup(s, user)
                if not group:
                    return []
                # Items have a item.get_groupnames() method that returns a comma+space separated string ... strange format!
                #for item in items:
                #    for contact in item.contacts:
                #        if group.get_name() in contact.get_groupnames().split(', '):
                #            logger.info("[WebUI - datamanager] => contact %s is a known member!", contact.get_name())

                contacts = [c for c in self.get_contacts(user=user) if c in group.members]
                items = list(set(itertools.chain(*[self._only_related_to(items, self.rg.contacts.find_by_name(c)) for c in contacts])))

            if t == 'realm':
                r = self.get_realm(s)
                if not r:
                    return []  # :TODO:maethor:150716: raise an error
                items = [i for i in items if i.get_realm() == r]

            if t == 'htag' and s.lower() != 'all':
                items = [i for i in items if s in i.get_host_tags()]

            if t == 'stag' and s.lower() != 'all':
                items = [i for i in items if i.__class__.my_type == 'service' and s in i.get_service_tags()]

            if t == 'ctag' and s.lower() != 'all':
                contacts = [c for c in self.get_contacts(user=user) if s in c.tags]
                items = list(set(itertools.chain(*[self._only_related_to(items, c) for c in contacts])))

            if t == 'type' and s.lower() != 'all':
                filtered_by_type = True
                items = [i for i in items if i.__class__.my_type == s]
                # logger.info("[WebUI - datamanager] type:%s, %d matching items", s, len(items))
                # for item in items:
                #     logger.info("[WebUI - datamanager] item %s is %s", item.get_name(), item.__class__)

            if t == 'bp' or t == 'bi':
                if s.startswith('>='):
                    items = [i for i in items if i.business_impact >= int(s[2:])]
                elif s.startswith('<='):
                    items = [i for i in items if i.business_impact <= int(s[2:])]
                elif s.startswith('>'):
                    items = [i for i in items if i.business_impact > int(s[1:])]
                elif s.startswith('<'):
                    items = [i for i in items if i.business_impact < int(s[1:])]
                else:
                    if s.startswith('='):
                        s = s[1:]
                    items = [i for i in items if i.business_impact == int(s)]

            if t == 'duration':
                seconds_per_unit = {"s": 1, "m": 60, "h": 3600, "d": 86400, "w": 604800}
                times = [(i, time.time() - int(i.last_state_change)) for i in items]
                try:
                    if s.startswith('>='):
                        s = int(s[2:-1]) * seconds_per_unit[s[-1].lower()]
                        items = [i[0] for i in times if i[1] >= s]
                    elif s.startswith('<='):
                        s = int(s[2:-1]) * seconds_per_unit[s[-1].lower()]
                        items = [i[0] for i in times if i[1] <= s]
                    elif s.startswith('>'):
                        s = int(s[1:-1]) * seconds_per_unit[s[-1].lower()]
                        items = [i[0] for i in times if i[1] > s]
                    elif s.startswith('<'):
                        s = int(s[1:-1]) * seconds_per_unit[s[-1].lower()]
                        items = [i[0] for i in times if i[1] < s]
                    else:
                        items = []
                except Exception:
                    items = []

            if t == 'is':
                if s.lower() == 'ack':
                    items = [i for i in items if i.__class__.my_type == 'service' or i.problem_has_been_acknowledged]
                    items = [i for i in items if i.__class__.my_type == 'host' or (i.problem_has_been_acknowledged or i.host.problem_has_been_acknowledged)]
                elif s.lower() == 'downtime':
                    items = [i for i in items if i.__class__.my_type == 'service' or i.in_scheduled_downtime]
                    items = [i for i in items if i.__class__.my_type == 'host' or (i.in_scheduled_downtime or i.host.in_scheduled_downtime)]
                elif s.lower() == 'impact':
                    items = [i for i in items if i.is_impact]
                elif s.lower() == 'probe':
                    items = [i for i in items if i.customs.get('_PROBE', '0') == '1']
                else:
                    # Manage SOFT & HARD state
                    if s.startswith('s'):
                        s = s[1:]
                        if len(s) == 1:
                            items = [i for i in items if i.state_id == int(s) and i.state_type != 'HARD']
                        else:
                            items = [i for i in items if i.state == s.upper() and i.state_type != 'HARD']
                    elif s.startswith('h'):
                        s = s[1:]
                        if len(s) == 1:
                            items = [i for i in items if i.state_id != int(s) and i.state_type == 'HARD']
                        else:
                            items = [i for i in items if i.state != s.upper() and i.state_type == 'HARD']
                    else:
                        if len(s) == 1:
                            items = [i for i in items if i.state_id == int(s)]
                        else:
                            items = [i for i in items if i.state == s.upper()]

            if t == 'isnot':
                if s.lower() == 'ack':
                    items = [i for i in items if i.__class__.my_type == 'service' or not i.problem_has_been_acknowledged]
                    items = [i for i in items if i.__class__.my_type == 'host' or (not i.problem_has_been_acknowledged and not i.host.problem_has_been_acknowledged)]
                elif s.lower() == 'downtime':
                    items = [i for i in items if i.__class__.my_type == 'service' or not i.in_scheduled_downtime]
                    items = [i for i in items if i.__class__.my_type == 'host' or (not i.in_scheduled_downtime and not i.host.in_scheduled_downtime)]
                elif s.lower() == 'impact':
                    items = [i for i in items if not i.is_impact]
                else:
                    # Manage soft & hard state
                    if s.startswith('s'):
                        s = s[1:]
                        if len(s) == 1:
                            items = [i for i in items if i.state_id != int(s) and i.state_type != 'HARD']
                        else:
                            items = [i for i in items if i.state != s.upper() and i.state_type != 'HARD']
                    elif s.startswith('h'):
                        s = s[1:]
                        if len(s) == 1:
                            items = [i for i in items if i.state_id != int(s) and i.state_type == 'HARD']
                        else:
                            items = [i for i in items if i.state != s.upper() and i.state_type == 'HARD']
                    else:
                        if len(s) == 1:
                            items = [i for i in items if i.state_id != int(s)]
                        else:
                            items = [i for i in items if i.state != s.upper()]

            if t == 'tech':
                items = [i for i in items if i.customs.get('_TECH') == s]

            if t == 'perf':
                match = re.compile('(?P<attr>[\w_]+)(?P<operator>>=|>|==|<|<=)(?P<value>[-\d\.]+)').match(s)
                operator_str2function = {'>=':operator.ge, '>':operator.gt, '=':operator.eq, '==':operator.eq, '<':operator.lt, '<=':operator.le}
                oper = operator_str2function[match.group('operator')]
                new_items = []
                if match:
                    for i in items:
                        if i.process_perf_data:
                            perf_datas = PerfDatas(i.perf_data)
                            if match.group('attr') in perf_datas:
                                if oper(float(perf_datas[match.group('attr')].value), float(match.group('value'))):
                                    # new_items.append(i)
                                    _append_based_on_filtered_by_type(new_items, i, filtered_by_type)
                items = new_items

            if t == 'reg':
                new_items = []
                # logger.info("[WebUI-REG] s=%s -> len(items)=%d", s.split(','), len(items))
                # pat = re.compile(s, re.IGNORECASE)
                for i in items:
                    l1 = s.split('|')
                    if i.__class__.my_type == 'service':
                        l2 = i.host.cpe_registration_tags.split(',')
                    elif i.__class__.my_type == 'host':
                        l2 = i.cpe_registration_tags.split(',')
                    else:
                        l2 = []

                    # logger.info("[WebUI-REG] item %s -> regtags: %s", i, l2)
                    found = [x for x in l1 if x in l2]
                    if found:
                        # logger.info("[WebUI-REG] found %s", i)
                        _append_based_on_filtered_by_type(new_items, i, filtered_by_type)

                # logger.info("[WebUI-REG] s=%s -> len(new_items)=%d", s.split(','), len(new_items))
                items = new_items

            if t == 'loc':
                pat = re.compile(s, re.IGNORECASE)
                new_items = []
                for i in items:
                    logger.info("[WebUI-LOC] i={} c={}".format(i, i.customs))

                    if pat.match(i.customs.get('_LOCATION', '')):
                        new_items.append(i)
                items = new_items

            if t == 'his':
                new_items = []
                # logger.info("[WebUI-HIS] his s=%s -> len(items)=%d", s, len(items))
                for i in items:
                    if i.__class__.my_type == 'service':
                        found = len(s) == 1 and i.host.state_id == int(s) or i.host.state == s.upper()
                        if found:
                            _append_based_on_filtered_by_type(new_items, i, filtered_by_type)
                        
                    elif i.__class__.my_type == 'host':
                        found = len(s) == 1 and i.state_id == int(s) or i.state == s.upper()
                        if found:
                            _append_based_on_filtered_by_type(new_items, i, filtered_by_type)

                # logger.info("[WebUI-HIS] s=%s -> len(new_items)=%d", s, len(new_items))
                items = new_items

            # :COMMENT:maethor:150616: Legacy filters, kept for bookmarks compatibility
            if t == 'ack':
                if s.lower() == 'false' or s.lower() == 'no':
                    patterns.append( ("isnot", "ack") )
                if s.lower() == 'true' or s.lower() == 'yes':
                    patterns.append( ("is", "ack") )
            if t == 'downtime':
                if s.lower() == 'false' or s.lower() == 'no':
                    patterns.append( ("isnot", "downtime") )
                if s.lower() == 'true' or s.lower() == 'yes':
                    patterns.append( ("is", "downtime") )
            if t == 'crit':
                patterns.append( ("is", "critical") )

        if sorter is not None:
            items.sort(sorter)

        logger.debug("[WebUI - datamanager] search_hosts_and_services, found %d matching items", len(items))

        logger.debug("[WebUI - datamanager] ----------------------------------------")
        # for item in items:
        #     logger.debug("[WebUI - datamanager] item %s is %s", item.get_name(), item.__class__)
        logger.debug("[WebUI - datamanager] ----------------------------------------")

        return items

    ##
    # Timeperiods
    ##
    def get_timeperiods(self, user=None, name=None):
        """ Get a list of known time periods

            :param user: concerned user
            :param name: only this element
            :returns: List of elements related to the user
        """
        logger.debug("[WebUI - datamanager] get_timeperiods, name: %s, user: %s", name, user)
        items = []
        if self.alignak:
            items = self.fe.timeperiods
        else:
            items = self.rg.timeperiods
        logger.debug("[WebUI - datamanager] got %d timeperiods", len(items))

        if name:
            return items.find_by_name(name)
        else:
            return self._only_related_to(items, user)

    def get_timeperiod(self, name):
        try:
            name = name.decode('utf8', 'ignore')
        except UnicodeEncodeError:
            pass

        return self.get_timeperiods(name=name)

    ##
    # Commands
    ##
    def get_commands(self, user=None, name=None):
        """ Get a list of known commands

            :param user: concerned user
            :param name: only this element
            :returns: List of elements related to the user
        """
        # logger.info("[WebUI - datamanager] get_commands, name: %s, user: %s", name, user)
        items = []
        if self.alignak:
            items = self.fe.commands
        else:
            items = self.rg.commands
        # logger.info("[WebUI - datamanager] got %d commands", len(items))

        if name:
            return items.find_by_name(name)
        else:
            return self._only_related_to(items, user)

    def get_command(self, name):
        try:
            name = name.decode('utf8', 'ignore')
        except UnicodeEncodeError:
            pass

        return self.get_commands(name=name)

    ##
    # Contacts
    ##
    def get_contacts(self, user=None, name=None):
        """ Get a list of known contacts

            :param user: concerned user
            :param name: only this element
            :returns: List of elements related to the user
        """
        logger.debug("[WebUI - datamanager] get_contacts, name: %s", name)
        items = []
        if self.alignak:
            items = self.fe.contacts
        else:
            items = self.rg.contacts
        logger.debug("[WebUI - datamanager] got %d contacts", len(items))

        if name:
            return items.find_by_name(name)
        else:
            return self._only_related_to(items, user)

    def get_contact(self, name=None, user=None):
        try:
            name = name.decode('utf8', 'ignore')
        except UnicodeEncodeError:
            pass
        except AttributeError:
            pass
        logger.debug("[WebUI - datamanager] get_contact, name: %s, user: %s", name, user)

        if self.alignak:
            if not self.fe.is_logged_in():
                return None

            if self.fe.is_logged_in():
                if not name or (name and name == self.fe.logged_in["name"]):
                    logger.debug("[WebUI - datamanager] get_contact, returns logged in contact: %s", self.fe.logged_in["name"])
                    return Contact(self.fe.logged_in)

                return self.get_contacts(user=user, name=name)

        return self.get_contacts(user=user, name=name)

    ##
    # Contacts groups
    ##
    def set_contactgroups_level(self, user):
        # All known contactgroups are level 0 groups ...
        for group in self.get_contactgroups(user=user):
            # logger.info("[WebUI - datamanager] set_contactgroups_level, group: %s", group)
            if not hasattr(group, 'level'):
                self.set_contactgroup_level(group, 0, user)

    def set_contactgroup_level(self, group, level, user):
        # logger.info("[WebUI - datamanager] set_contactgroup_level, group: %s, level: %d", group, level)
        setattr(group, 'level', level)

        for g in sorted(group.get_contactgroup_members()):
            if not g:
                continue
            # logger.info("[WebUI - datamanager] set_contactgroup_level, g: %s", g)
            try:
                child_group = self.get_contactgroup(g, user=user)
                self.set_contactgroup_level(child_group, level + 1, user)
            except AttributeError:
                pass

    def get_contactgroups(self, user=None, name=None, parent=None, members=False):
        """ Get a list of known contacts groups

            :param user: concerned user
            :param name: only this element
            :returns: List of elements related to the user
        """
        # logger.info("[WebUI - datamanager] get_contactgroups, name: %s, members: %s", name, members)
        items = []
        if parent:
            group = self.get_contactgroups(user=user, name=parent)
            if group:
                items = [self.get_contactgroup(g) for g in group.get_contactgroup_members()]
            else:
                return items
        else:
            if self.alignak:
                items = self.fe.contactgroups
            else:
                items = self.rg.contactgroups
        # logger.info("[WebUI - datamanager] got %d contactgroups", len(items))

        if name:
            return items.find_by_name(name)
        else:
            return self._only_related_to(items, user)

    def get_contactgroup(self, name, user=None, members=False):
        """ Get a specific contacts group

            :param name: searched contacts group name
            :param user: concerned user
            :returns: List of contacts groups related to the user
        """
        try:
            name = name.decode('utf8', 'ignore')
        except UnicodeEncodeError:
            pass
        # logger.info("[WebUI - datamanager] get_contactgroup, name: %s", name)

        return self._only_related_to(self.get_contactgroups(user=user, name=name, members=members), user)

    def get_contactgroup_members(self, name, user=None):
        """ Get a list of contacts members of a group

            :param name: searched group name
            :param user: concerned user
            :returns: List of contacts groups related to the user
        """
        try:
            name = name.decode('utf8', 'ignore')
        except UnicodeEncodeError:
            pass

        return self._is_related_to(self.get_contactgroup(user=user, name=name, members=True), user)


    ##
    # Hosts groups
    ##
    def set_hostgroups_level(self, user):
        # All known hostgroups are level 0 groups ...
        # logger.info("[WebUI - datamanager] set_hostgroups_level user=%s...", user)
        for group in self.get_hostgroups(user=user):
            logger.debug("[WebUI - datamanager] set_hostgroups_level, group: %s", group)
            if not hasattr(group, 'level'):
                self.set_hostgroup_level(group, 0, user)
        # logger.info("[WebUI - datamanager] set_hostgroups_level!!!")

    def set_hostgroup_level(self, group, level, user):
        setattr(group, 'level', level)
        # logger.info("[WebUI - datamanager] set_hostgroup_level, group: %s, level: %d ...", group, level)

        for g in sorted(group.get_hostgroup_members()):
            if not g:
                continue
            logger.debug("[WebUI - datamanager] set_hostgroup_level, g: %s", g)
            try:
                child_group = self.get_hostgroup(g, user=user)
                self.set_hostgroup_level(child_group, level + 1, user)
            except AttributeError:
                pass
        # logger.info("[WebUI - datamanager] set_hostgroup_level, group: %s, level: %d !!!", group, level)

    def get_hostgroups(self, user=None, name=None, parent=None):
        """ Get a list of known hosts groups

            :param user: concerned user
            :param name: only this element
            :returns: List of elements related to the user
        """
        # logger.info("[WebUI - datamanager] get_hostgroups, name: %s", name)
        items = []
        if parent:
            group = self.get_hostgroups(user=user, name=parent)
            if group:
                items = [self.get_hostgroup(g) for g in group.get_hostgroup_members()]
            else:
                return items
        else:
            if self.alignak:
                items = self.fe.hostgroups
            else:
                items = self.rg.hostgroups
        # logger.info("[WebUI - datamanager] got %d hostgroups", len(items))

        if name:
            return items.find_by_name(name)
        else:
            return self._only_related_to(items, user)

    def get_hostgroup(self, name, user=None):
        """ Get a specific hosts group

            :param name: searched hosts group name
            :param user: concerned user
            :returns: List of hosts groups related to the user
        """
        try:
            name = name.decode('utf8', 'ignore')
        except UnicodeEncodeError:
            pass

        group = self.get_hostgroups(user=user, name=name)
        return self._is_related_to(self.get_hostgroups(user=user, name=name), user)

    def get_hostgroup_hosts(self, name, user=None):
        """ Get a list of hosts members of a group

            :param name: searched group name
            :param user: concerned user
            :returns: List of hosts groups related to the user
        """
        logger.warning("[WebUI - datamanager] get_hostgroup_hosts: %s", name)
        try:
            name = name.decode('utf8', 'ignore')
        except UnicodeEncodeError:
            pass

        group = self.get_hostgroup(user=user, name=name)
        logger.warning("[WebUI - datamanager] get_hostgroup_hosts, found: %s", group)
        if group:
            for host in group.get_hosts():
                logger.warning("[WebUI - datamanager] -> host: %s, contacts: %s", host.get_name(), host.contacts)
                if user:
                    for contact in host.contacts:
                        if contact.contact_name == user.contact_name:
                            logger.info("[WebUI - relation], user is a contact through an hostgroup")
            return self._is_related_to(group.get_hosts(), user)
        return None

    ##
    # Services groups
    ##
    def set_servicegroups_level(self, user):
        # All known hostgroups are level 0 groups ...
        for group in self.get_servicegroups(user=user):
            if not hasattr(group, 'level'):
                self.set_servicegroup_level(group, 0, user)

    def set_servicegroup_level(self, group, level, user):
        setattr(group, 'level', level)

        for g in sorted(group.get_servicegroup_members()):
            try:
                child_group = self.get_servicegroup(g)
                self.set_servicegroup_level(child_group, level + 1, user)
            except AttributeError:
                pass

    def get_servicegroups(self, user=None, name=None, parent=None, members=False):
        """ Get a list of known services groups

            :param user: concerned user
            :param name: only this element
            :returns: List of elements related to the user
        """
        logger.debug("[WebUI - datamanager] get_servicegroups, name: %s", user)
        items = []
        if parent:
            group = self.get_servicegroups(user=user, name=parent)
            if group:
                items = [self.get_servicegroup(g) for g in group.get_servicegroup_members()]
            else:
                return items
        else:
            if self.alignak:
                items = self.fe.servicegroups
            else:
                items = self.rg.servicegroups
        logger.debug("[WebUI - datamanager] got %d servicegroups", len(items))

        if name:
            return items.find_by_name(name)
        else:
            return self._only_related_to(items, user)

    def get_servicegroup(self, name, user=None, parent=None, members=False):
        """ Get a specific hosts group

            :param name: searched hosts group name
            :param user: concerned user
            :returns: List of hosts groups related to the user
        """
        try:
            name = name.decode('utf8', 'ignore')
        except UnicodeEncodeError:
            pass

        return self._is_related_to(self.get_servicegroups(user=user, name=name, members=members), user)

    def get_servicegroup_members(self, name, user=None):
        """ Get a list of services members of a group

            :param name: searched group name
            :param user: concerned user
            :returns: List of hosts groups related to the user
        """
        try:
            name = name.decode('utf8', 'ignore')
        except UnicodeEncodeError:
            pass

        return self._is_related_to(self.get_servicegroup(user=user, name=name, members=True), user)

    ##
    # Hosts tags
    ##
    def get_host_tags(self):
        ''' Get the hosts tags sorted by names. '''
        # logger.info("[WebUI - datamanager] get_host_tags")
        items = []
        if self.alignak:
            names = self.fe.hosts_tags.keys()
        else:
            names = self.rg.tags.keys()

        names.sort()
        for name in names:
            items.append((name, self.rg.tags[name]))

        # logger.debug("[WebUI - datamanager] got %d hosts tags", len(items))
        return items

    def get_hosts_tagged_with(self, tag, user):
        ''' Get the hosts tagged with a specific tag. '''
        return self.search_hosts_and_services('type:host htag:%s' % tag, user)

    ##
    # Services tags
    ##
    def get_service_tags(self):
        ''' Get the services tags sorted by names. '''
        items = []
        if self.alignak:
            names = self.fe.services_tags.keys()
        else:
            names = self.rg.services_tags.keys()

        names.sort()
        for name in names:
            items.append((name, self.rg.services_tags[name]))

        # logger.debug("[WebUI - datamanager] got %d services tags", len(items))
        return items

    def get_services_tagged_with(self, tag, user):
        ''' Get the services tagged with a specific tag. '''
        return self.search_hosts_and_services('type:service stag:%s' % tag, user)

    ##
    # Realms
    ##
    def get_realms(self):
        items = []
        if self.alignak:
            # Request objects from the backend ...
            # Get only registered (real ...) objects ...
            parameters = {
            }
            if name:
                parameters = {
                    'where': json.dumps({
                        'realm_name': name
                    })
                }

            # logger.info("[WebUI - datamanager] get_realms, backend parameters: %s", parameters)
            resp = self.fe.get_objects('contactgroup', parameters=parameters)
            total = 0
            if '_meta' in resp:
                total = int(resp['_meta']['total'])
                page_number = int(resp['_meta']['page'])
                # logger.info("[WebUI - datamanager] get_realms, total %d realms", total)

            if '_items' in resp:
                for item in resp['_items']:
                    # logger.info("[WebUI - datamanager] get_realms, found realm: %s", item['name'])
                    items.append(Realm(item))
                return self._only_related_to(items, user)

        return self._only_related_to(self.rg.realms, user)

    def get_realm(self, name):
        try:
            name = name.decode('utf8', 'ignore')
        except UnicodeEncodeError:
            pass

        return self._is_related_to(self.get_realms(user=user, name=name), user)

    ##
    # Shinken program and daemons
    ##
    def get_configs(self):
        if self.alignak:
            return None

        return self.rg.configs.values()

    def get_schedulers(self):
        if self.alignak:
            return None

        return self.rg.schedulers

    def get_pollers(self):
        if self.alignak:
            return None

        return self.rg.pollers

    def get_brokers(self):
        if self.alignak:
            return None

        return self.rg.brokers

    def get_receivers(self):
        if self.alignak:
            return None

        return self.rg.receivers

    def get_reactionners(self):
        if self.alignak:
            return None

        return self.rg.reactionners

    ##
    # Shortcuts
    ##
    def get_overall_state(self, user):
        ''' Get the worst state of all business impacting elements. '''
        impacts = self.get_impacts(user, sorter=worse_first)
        if impacts:
            return impacts[0].state_id
        else:
            return 0

    def get_overall_it_state(self, user):
        ''' Get the worst state of IT problems. '''
        hosts = self.get_important_elements(user, type='host', sorter=worse_first)
        services = self.get_important_elements(user, type='service', sorter=worse_first)
        hosts_state = hosts[0].state_id if hosts else 0
        services_state = services[0].state_id if services else 0
        return hosts_state, services_state

    def get_important_elements(self, user, type='all', sorter=worse_first):
        return self.search_hosts_and_services('bi:>2 ack:false type:%s' % type, user=user, sorter=sorter)

    def get_impacts(self, user, search='is:impact bi:>=0 type:all', sorter=worse_first):
        if not "is:impact" in search:
            search = "is:impact "+search
        return self.search_hosts_and_services(search, user=user, get_impacts=True, sorter=sorter)

    def get_problems(self, user, search='isnot:UP isnot:OK isnot:PENDING bi:>=0 type:all', get_acknowledged=False, get_downtimed=False, sorter=worse_first):
        if not "isnot:UP" in search:
            search = "isnot:UP "+search
        if not "isnot:OK" in search:
            search = "isnot:OK "+search
        if not "isnot:PENDING" in search:
            search = "isnot:PENDING "+search
        return self.search_hosts_and_services('%s ack:%s downtime:%s' % (search, str(get_acknowledged), str(get_downtimed)), user=user, sorter=sorter)

    def guess_root_problems(self, user, obj):
        ''' Returns the root problems for a service. '''
        if obj.__class__.my_type != 'service':
            return []

        items = obj.host.services
        r = [s for s in self._only_related_to(items, user) if s.state_id != 0 and s != obj]
        return r

    # Return a tree of {'elt': Host, 'fathers': [{}, {}]}
    def get_business_parents(self, user, obj, levels=3):
        res = {'node': obj, 'fathers': []}
        # if levels == 0:
        #     return res

        for i in obj.parent_dependencies:
            # We want to get the levels deep for all elements, but
            # go as far as we should for bad elements
            if levels != 0 or i.state_id != 0:
                par_elts = self.get_business_parents(user, i, levels=levels - 1)
                res['fathers'].append(par_elts)

        return res
