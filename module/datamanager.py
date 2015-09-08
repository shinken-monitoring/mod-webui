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
import itertools
import time


from shinken.misc.datamanager import DataManager


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

    def __init__(self, rg=None):
        super(WebUIDataManager, self).__init__()
        self.rg = rg

    @staticmethod
    def _is_related_to(item, contact):
        """ Is the item (host, service, group…) related to the contact?

            In other words, can the user see this item in the WebUI?
            .. todo:: should be a method of Item or Contact…
                      but the shinken model is incomplete,
                      so we have to do it here.

            :returns: True or False
        """
        # if the user is an admin, show all
        if contact is None or contact.is_admin:
            return True

        # May be the user is a direct contact
        if hasattr(item, 'contacts') and contact in item.contacts:
            return True
        # TODO: add a notified_contact pass

        # is it me ?
        if item.__class__.my_type == 'contact':
            return item.contact_name == contact.contact_name

        if item.__class__.my_type == 'contactgroup':
            return contact in item.members

        # May be it's a contact of a linked items
        # source problems or impacts)
        if hasattr(item, 'source_problems'):
            for s in item.source_problems:
                if contact in s.contacts:
                    return True

        if item.__class__.my_type == 'hostgroup':
            for h in item.get_hosts():
                if contact in h.contacts:
                    return True

        # May be it's a contact of a sub item ...
        if item.__class__.my_type == 'servicegroup':
            for s in item.get_services():
                if contact in s.contacts:
                    return True

        # Now impacts related maybe?
        if hasattr(item, 'impacts'):
            for imp in item.impacts:
                if contact in imp.contacts:
                    return True

        return False

    @staticmethod
    def _only_related_to(lst, contact):
        """ This function is just a wrapper to _is_related_to.

            Kept for backward compatibility reasons.

            :returns: List of elements related to the contact
        """
        return [l for l in lst if WebUIDataManager._is_related_to(l, contact)]

    ##
    # Hosts
    ##
    def get_hosts(self, user, get_impacts=True):
        """ Get a list of all hosts.

            :param user: concerned user
            :param get_impacts: should impact hosts be included in the list?
            :returns: list of all hosts
        """
        items = super(WebUIDataManager, self).get_hosts()
        if not get_impacts:
            items = [i for i in items if not i.is_impact]
        return self._only_related_to(items, user)

    def get_host(self, hname, user):
        """ Get a host by its hostname. """
        hname = hname.decode('utf8', 'ignore')
        host = self.rg.hosts.find_by_name(hname)
        if host and self._is_related_to(host, user):
            return host
        else:
            return None

    def get_percentage_hosts_state(self, user, problem=False):
        """ Get percentage of hosts not in (or in) problems.

            :param problem: False to return the % of hosts not in problems,
                            True to return the % of hosts in problems.
                            False by default
        """
        all_hosts = self.get_hosts(user)
        if not all_hosts:
            return 0

        problems = [h for h in all_hosts
                    if h.state not in ['UP', 'PENDING']
                    and not h.is_impact]

        if problem:
            return int((len(problems) * 100) / float(len(all_hosts)))
        else:
            return int(100 - (len(problems) * 100) / float(len(all_hosts)))

    ##
    # Services
    ##
    def get_services(self, user, get_impacts=True):
        """ Get a list of all services.

            :param user: concerned user
            :param get_impacts: should impact services be included in the list?
            :returns: list of all services
        """
        items = super(WebUIDataManager, self).get_services()
        if not get_impacts:
            items = [i for i in items if not i.is_impact]
        return self._only_related_to(items, user)

    def get_service(self, hname, sdesc, user):
        """ Get a service by its hostname and service description. """
        hname = hname.decode('utf8', 'ignore')
        sdesc = sdesc.decode('utf8', 'ignore')
        service = self.rg.services.find_srv_by_name_and_hostname(hname, sdesc)
        if service and self._is_related_to(service, user):
            return service
        else:
            return None

    def get_percentage_service_state(self, user, problem=False):
        """ Get percentage of services not in (or in) problems.

            :param problem: False to return the % of services not in problems,
                            True to return the % of services in problems.
                            False by default
        """
        all_services = self.get_services(user)
        if not all_services:
            return 0

        problems = [s for s in all_services
                    if s.state not in ['OK', 'PENDING']
                    and not s.is_impact]

        if problem:
            return int((len(problems) * 100) / float(len(all_services)))
        else:
            return int(100 - (len(problems) * 100) / float(len(all_services)))

    ##
    # Elements
    ##
    def get_element(self, name, user):
        """ Get an element by its name.
            :name: Must be "host" or "host/service"
        """
        if '/' in name:
            return self.get_service(name.split('/')[0], name.split('/')[1], user)
        else:
            return self.get_host(name, user)

    def search_hosts_and_services(self, search, user, get_impacts=True, sorter=None):
        """ Search hosts and services.

            This method is the heart of the datamanager. All other methods should be based on this one.

            :search: Search string
            :user: concerned user
            :get_impacts: should impacts be included in the list?
            :sorter: function to sort the items. default=None (means no sorting)
            :returns: list of hosts and services
        """
        items = []
        items.extend(self.get_hosts(user, get_impacts))
        items.extend(self.get_services(user, get_impacts))

        search = [s for s in search.split(' ')]

        for s in search:
            s = s.strip()
            if not s:
                continue

            elts = s.split(':', 1)
            t = 'hst_srv'
            if len(elts) > 1:
                t = elts[0]
                s = elts[1]

            s = s.lower()
            t = t.lower()

            if t == 'hst_srv':
                pat = re.compile(s, re.IGNORECASE)
                new_items = []
                for i in items:
                    if pat.search(i.get_full_name()):
                        new_items.append(i)
                    else:
                        for j in (i.impacts + i.source_problems):
                            if pat.search(j.get_full_name()):
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

            if (t == 'hg' or t == 'hgroup') and s != 'all':
                group = self.get_hostgroup(s)
                if not group:
                    return []  # :TODO:maethor:150716: raise an error
                items = [i for i in items if group in i.get_hostgroups()]

            if (t == 'sg' or t == 'sgroup') and s != 'all':
                group = self.get_servicegroup(s)
                if not group:
                    return []  # :TODO:maethor:150716: raise an error
                items = [i for i in items if group in i.servicegroups]

            if (t == 'cg' or t == 'cgroup') and s != 'all':
                group = self.get_contactgroup(s, user)
                if not group:
                    return []  # :TODO:maethor:150716: raise an error
                contacts = [c for c in self.get_contacts(user) if c in group.members]
                items = list(set(itertools.chain(*[self._only_related_to(items, c) for c in contacts])))

            if t == 'realm':
                r = self.get_realm(s)
                if not r:
                    return []  # :TODO:maethor:150716: raise an error
                items = [i for i in items if i.get_realm() == r]

            if t == 'htag' and s != 'all':
                items = [i for i in items if s in i.get_host_tags()]

            if t == 'stag' and s != 'all':
                items = [i for i in items if i.__class__.my_type == 'service' and s in i.get_service_tags()]

            if t == 'ctag' and s != 'all':
                contacts = [c for c in self.get_contacts(user) if s in c.tags]
                items = list(set(itertools.chain(*[self._only_related_to(items, c) for c in contacts])))

            if t == 'type' and s != 'all':
                items = [i for i in items if i.__class__.my_type == s]

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
                    if len(s) == 1:
                        items = [i for i in items if i.state_id != int(s)]
                    else:
                        items = [i for i in items if i.state != s.upper()]

            # :COMMENT:maethor:150616: Legacy filters, kept for bookmarks compatibility
            if t == 'ack':
                if s == 'false' or s == 'no':
                    search.append("isnot:ack")
                if s == 'true' or s == 'yes':
                    search.append("is:ack")
            if t == 'downtime':
                if s == 'false' or s == 'no':
                    search.append("isnot:downtime")
                if s == 'true' or s == 'yes':
                    search.append("is:downtime")
            if t == 'crit':
                search.append("is:critical")

        if sorter is not None:
            items.sort(sorter)

        return items

    ##
    # Timeperiods
    ##
    def get_timeperiods(self):
        return self.rg.timeperiods

    def get_timeperiod(self, name):
        return self.rg.timeperiods.find_by_name(name)

    ##
    # Commands
    ##
    def get_commands(self):
        return self.rg.commands

    def get_command(self, name):
        name = name.decode('utf8', 'ignore')
        return self.rg.commands.find_by_name(name)

    ##
    # Contacts
    ##
    def get_contacts(self, user):
        items = self.rg.contacts
        return self._only_related_to(items, user)

    def get_contact(self, name, user=None):
        name = name.decode('utf8', 'ignore')
        item = self.rg.contacts.find_by_name(name)
        if self._is_related_to(item, user):
            return item
        return None

    ##
    # Contacts groups
    ##
    def get_contactgroups(self, user):
        """ Get a list of known contacts groups 

            :param user: concerned user
            :returns: List of contacts groups related to the user
        """
        items = self.rg.contactgroups
        return self._only_related_to(items, user)

    def get_contactgroup(self, name, user):
        """ Get a specific contacts group

            :param name: searched contacts group name
            :param user: concerned user
            :returns: List of contacts groups related to the user
        """
        name = name.decode('utf8', 'ignore')
        item = self.rg.contactgroups.find_by_name(name)
        if self._is_related_to(item, user):
            return item
        return None
        
    def get_contactgroup_contacts(self, name, user):
        """ Get the contacts in a contacts group

            :param name: searched contacts group name
            :param user: concerned user
            :returns: List of contacts in the group only related to the user
        """
        name = name.decode('utf8', 'ignore')
        item = self.rg.contactgroups.find_by_name(name)
        if self._is_related_to(item, user):
            contacts = [c for c in self.get_contacts(user) if c in item.members]
            return contacts
        return None


    ##
    # Hosts groups
    ##
    def set_hostgroups_level(self, user):
        # All known hostgroups are level 0 groups ...
        for group in self.get_hostgroups(user=user):
            if not hasattr(group, 'level'):
                self.set_hostgroup_level(group, 0, user)

    def set_hostgroup_level(self, group, level, user):
        setattr(group, 'level', level)

        for g in sorted(group.get_hostgroup_members()):
            try:
                child_group = self.get_hostgroup(g)
                self.set_hostgroup_level(child_group, level + 1, user)
            except AttributeError:
                pass

    def get_hostgroups(self, user, parent=None):
        if parent:
            group = self.rg.hostgroups.find_by_name(parent)
            items = [self.get_hostgroup(g) for g in group.get_hostgroup_members()]
        else:
            items = self.rg.hostgroups

        return self._only_related_to(items, user)

    def get_hostgroup(self, name):
        return self.rg.hostgroups.find_by_name(name)

    ##
    # Services groups
    ##
    def set_servicegroups_level(self, user):
        # All known hostgroups are level 0 groups ...
        for group in self.get_servicegroups(user=user):
            self.set_servicegroup_level(group, 0, user)

    def set_servicegroup_level(self, group, level, user):
        setattr(group, 'level', level)

        for g in sorted(group.get_servicegroup_members()):
            child_group = self.get_servicegroup(g)
            self.set_servicegroup_level(child_group, level + 1, user)

    def get_servicegroups(self, user, parent=None):
        if parent:
            group = self.rg.servicegroups.find_by_name(parent)
            items = [self.get_servicegroup(g) for g in group.get_servicegroup_members()]
        else:
            items = self.rg.servicegroups

        return self._only_related_to(items, user)

    def get_servicegroup(self, name):
        return self.rg.servicegroups.find_by_name(name)

    ##
    # Hosts tags
    ##
    def get_host_tags(self):
        ''' Get the hosts tags sorted by names. '''
        r = []
        names = self.rg.tags.keys()
        names.sort()
        for name in names:
            r.append((name, self.rg.tags[name]))
        return r
        
        # return sorted(self.rg.tags)

    def get_hosts_tagged_with(self, tag, user):
        ''' Get the hosts tagged with a specific tag. '''
        return self.search_hosts_and_services('type:host htag:%s' % tag, user)

    ##
    # Services tags
    ##
    def get_service_tags(self):
        ''' Get the services tags sorted by names. '''
        r = []
        names = self.rg.services_tags.keys()
        names.sort()
        for name in names:
            r.append((name, self.rg.services_tags[name]))
        return r
        
        # return sorted(self.rg.services_tags)

    def get_services_tagged_with(self, tag, user):
        ''' Get the services tagged with a specific tag. '''
        return self.search_hosts_and_services('type:service stag:%s' % tag, user)

    ##
    # Realms
    ##
    def get_realms(self):
        return self.rg.realms

    def get_realm(self, r):
        if r in self.rg.realms:
            return r
        return None

    ##
    # Shinken program
    ##
    def get_configs(self):
        return self.rg.configs.values()

    def get_schedulers(self):
        return self.rg.schedulers

    def get_pollers(self):
        return self.rg.pollers

    def get_brokers(self):
        return self.rg.brokers

    def get_receivers(self):
        return self.rg.receivers

    def get_reactionners(self):
        return self.rg.reactionners

    ##
    # Shortcuts
    ##
    def get_overall_state(self, user):
        ''' Get the worst state of all business impacting elements. '''
        impacts = self.get_important_impacts(user, sorter=worse_first)
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

    def get_impacts(self, user, bi='>=0', type='all', sorter=worse_first):
        return self.search_hosts_and_services('is:impact bi:%s type:%s' % (bi, type), user=user, get_impacts=True, sorter=sorter)

    def get_important_impacts(self, user, type='all', sorter=worse_first):
        return self.get_impacts(user=user, type=type, bi='>2', sorter=sorter)

    def get_problems(self, user, get_acknowledged=False, get_downtimed=False, bi='>=0', type='all', sorter=worse_first):
        return self.search_hosts_and_services('isnot:UP isnot:OK isnot:PENDING ack:%s downtime:%s bi:%s type:%s' % (str(get_acknowledged), str(get_downtimed), bi, type), user=user, sorter=sorter)

    def get_important_problems(self, user, type='all', sorter=worse_first):
        return self.get_problems(user, bi=">2", type=type, sorter=sorter)


datamgr = WebUIDataManager()
