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


from shinken.misc.datamanager import DataManager
from shinken.misc.sorter import last_state_change_earlier


class WebUIDataManager(DataManager):

    def __init__(self, rg=None):
        super(WebUIDataManager, self).__init__()
        self.rg = rg

    # :TODO:maethor:150717: replace by a "related_to" filter
    def only_related_to(self, lst, user):
        # if the user is an admin, show all
        if user is None or user.is_admin:
            return lst

        # Ok the user is a simple user, we should filter
        r = set()
        for item in lst:
            # May be the user is a direct contact
            if hasattr(item, 'contacts') and user in item.contacts:
                r.add(item)
                continue
            # TODO: add a notified_contact pass

            # May be it's a contact of a linked elements
            # source problems or impacts)
            found = False
            if hasattr(item, 'source_problems'):
                for s in item.source_problems:
                    if user in s.contacts:
                        r.add(item)
                        found = True
            # Ok skip this object now
            if found:
                continue

            # May be it's a contact of a sub element ...
            found = False
            if item.__class__.my_type == 'hostgroup':
                for h in item.get_hosts():
                    if user in h.contacts:
                        r.add(item)
                        found = True
            # Ok skip this object now
            if found:
                continue

            # May be it's a contact of a sub element ...
            found = False
            if item.__class__.my_type == 'servicegroup':
                for s in item.get_services():
                    if user in s.contacts:
                        r.add(item)
                        found = True
            # Ok skip this object now
            if found:
                continue

            # Now impacts related maybe?
            if hasattr(item, 'impacts'):
                for imp in item.impacts:
                    if user in imp.contacts:
                        r.add(item)

        return list(r)

    ##
    # Hosts
    ##
    def get_hosts(self, user=None, get_impacts=True):
        """
        Get a list of all hosts

        :user: concerned user
        :get_impacts: should impact hosts be included in the list?
        :returns: list of all hosts

        """
        items = super(WebUIDataManager, self).get_hosts()
        if not get_impacts:
            items = [i for i in items if not i.is_impact]
        return self.only_related_to(items, user)

    def get_host(self, hname):
        hname = hname.decode('utf8', 'ignore')
        return self.rg.hosts.find_by_name(hname)

    # Get percentage of all Hosts
    # problem=False, returns % of hosts not in problems
    # problem=True, returns % of hosts in problems
    def get_percentage_hosts_state(self, user=None, problem=False):
        all_hosts = self.get_hosts(user)
        if len(all_hosts) == 0:
            return 0

        problems = []
        problems.extend([h for h in all_hosts
                         if h.state not in ['UP', 'PENDING']
                         and not h.is_impact])

        if problem:
            return int((len(problems) * 100) / float(len(all_hosts)))
        else:
            return int(100 - (len(problems) * 100) / float(len(all_hosts)))

    ##
    # Services
    ##
    def get_services(self, user=None, get_impacts=True):
        items = super(WebUIDataManager, self).get_services()
        if not get_impacts:
            items = [i for i in items if not i.is_impact]
        return self.only_related_to(items, user)

    def get_service(self, hname, sdesc):
        hname = hname.decode('utf8', 'ignore')
        sdesc = sdesc.decode('utf8', 'ignore')
        return self.rg.services.find_srv_by_name_and_hostname(hname, sdesc)

    def get_percentage_service_state(self, user=None, problem=False):
        all_services = self.get_services(user)
        if len(all_services) == 0:
            return 0

        problems = []
        problems.extend([s for s in all_services
                         if s.state not in ['OK', 'PENDING']
                         and not s.is_impact])

        if problem:
            return int((len(problems) * 100) / float(len(all_services)))
        else:
            return int(100 - (len(problems) * 100) / float(len(all_services)))

    ##
    # Hosts and services
    ##
    # :TODO:maethor:150718: Merge with search_hosts_and_services
    def get_all_hosts_and_services(self, user=None, get_impacts=True):
        """
        Get a list of all hosts and services

        :user: concerned user
        :get_impacts: should impact hosts/services be included in the list ?
        :returns: list of all hosts and services

        """
        all = []
        all.extend(self.get_hosts(user, get_impacts))
        all.extend(self.get_services(user, get_impacts))
        return all

    def search_hosts_and_services(self, search, user=None, get_impacts=True):
        """@todo: Docstring for search_hosts_and_services.

        :search: @todo
        :user: @todo
        :get_impacts: @todo
        :returns: @todo

        """
        items = self.get_all_hosts_and_services(user=user, get_impacts=get_impacts)

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
                items = [i for i in items if group in i.get_servicegroups()]

            if (t == 'cg' or t == 'cgroup') and s != 'all':
                group = self.get_contactgroup(s)
                if not group:
                    return []  # :TODO:maethor:150716: raise an error
                contacts = [c for c in self.get_contacts() if c in group.members]
                items = list(set(itertools.chain(*[self.only_related_to(items, c) for c in contacts])))

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
                contacts = [c for c in self.get_contacts() if s in c.tags]
                items = list(set(itertools.chain(*[self.only_related_to(items, c) for c in contacts])))

            if t == 'type':
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

            if t == 'is':
                if s.lower() == 'ack':
                    items = [i for i in items if i.__class__.my_type == 'service' or i.problem_has_been_acknowledged]
                    items = [i for i in items if i.__class__.my_type == 'host' or (i.problem_has_been_acknowledged or i.host.problem_has_been_acknowledged)]
                elif s.lower() == 'downtime':
                    items = [i for i in items if i.__class__.my_type == 'service' or i.in_scheduled_downtime]
                    items = [i for i in items if i.__class__.my_type == 'host' or (i.in_scheduled_downtime or i.host.in_scheduled_downtime)]
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
    def get_contacts(self, user=None):
        items = self.rg.contacts
        return self.only_related_to(items, user)

    def get_contact(self, name):
        name = name.decode('utf8', 'ignore')
        return self.rg.contacts.find_by_name(name)

    ##
    # Contacts groups
    ##
    def get_contactgroups(self, user=None):
        items = self.rg.contactgroups
        return self.only_related_to(items, user)

    def get_contactgroup(self, name):
        name = name.decode('utf8', 'ignore')
        return self.rg.contactgroups.find_by_name(name)

    ##
    # Hosts groups
    ##
    def set_hostgroups_level(self, user=None):
        # All known hostgroups are level 0 groups ...
        for group in self.get_hostgroups(user=user):
            if not hasattr(group, 'level'):
                self.set_hostgroup_level(group, 0, user)

    def set_hostgroup_level(self, group, level, user=None):
        setattr(group, 'level', level)

        # Search hostgroups referenced in another group
        if group.has('hostgroup_members'):
            for g in sorted(group.get_hostgroup_members()):
                try:
                    child_group = self.get_hostgroup(g)
                    self.set_hostgroup_level(child_group, level + 1, user)
                except AttributeError:
                    pass

    def get_hostgroups(self, user=None, parent=None):
        if parent:
            group = self.rg.hostgroups.find_by_name(parent)
            if group.has('hostgroup_members'):
                items = [self.get_hostgroup(g) for g in group.get_hostgroup_members()]
            else:
                return None
        else:
            items = self.rg.hostgroups

        return self.only_related_to(items, user)

    def get_hostgroup(self, name):
        return self.rg.hostgroups.find_by_name(name)

    ##
    # Services groups
    ##
    def set_servicegroups_level(self, user=None):
        # All known hostgroups are level 0 groups ...
        for group in self.get_servicegroups(user=user):
            self.set_servicegroup_level(group, 0, user)

    def set_servicegroup_level(self, group, level, user=None):
        setattr(group, 'level', level)

        # Search servicegroups referenced in another group
        if group.has('servicegroup_members'):
            for g in sorted(group.get_servicegroup_members()):
                child_group = self.get_servicegroup(g)
                self.set_servicegroup_level(child_group, level + 1, user)

    def get_servicegroups(self, user=None, parent=None):
        if parent:
            group = self.rg.servicegroups.find_by_name(parent)
            if group.has('servicegroup_members'):
                items = [self.get_servicegroup(g) for g in group.get_servicegroup_members()]
            else:
                return None
        else:
            items = self.rg.servicegroups

        return self.only_related_to(items, user)

    def get_servicegroup(self, name):
        return self.rg.servicegroups.find_by_name(name)

    ##
    # Hosts tags
    ##
    # Get the hosts tags sorted by names, and zero size in the end
    def get_host_tags_sorted(self):
        r = []
        names = self.rg.tags.keys()
        names.sort()
        for n in names:
            r.append((n, self.rg.tags[n]))
        return r

    # Get the hosts tagged with a specific tag
    def get_hosts_tagged_with(self, tag, user=None):
        return self.search_hosts_and_services('type:host htag:%s' % tag, user)

    ##
    # Services tags
    ##
    # Get the services tags sorted by names, and zero size in the end
    def get_service_tags_sorted(self):
        r = []
        names = self.rg.services_tags.keys()
        names.sort()
        for n in names:
            r.append((n, self.rg.services_tags[n]))
        return r

    # Get the services tagged with a specific tag
    def get_services_tagged_with(self, tag, user=None):
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

    # For all business impacting elements, and give the worse state
    # if warning or critical
    def get_overall_state(self, user=None):
        h_states = [h.state_id for h in self.get_hosts(user) if h.business_impact > 2 and h.is_impact and h.state_id in [1, 2]]
        s_states = [s.state_id for s in self.get_services(user) if s.business_impact > 2 and s.is_impact and s.state_id in [1, 2]]
        if len(h_states) == 0:
            h_state = 0
        else:
            h_state = max(h_states)
        if len(s_states) == 0:
            s_state = 0
        else:
            s_state = max(s_states)

        return max(h_state, s_state)

    # For all business impacting elements, and give the worse state
    # if warning or critical
    def get_overall_state_problems_count(self, user=None):
        h_states = [h.state_id for h in self.get_hosts(user) if h.business_impact > 2 and h.is_impact and h.state_id in [1, 2]]
        s_states = [s.state_id for s in self.get_services(user) if s.business_impact > 2 and s.is_impact and s.state_id in [1, 2]]

        return len(h_states) + len(s_states)

    # Same but for pure IT problems
    def get_overall_it_state(self, user=None, get_acknowledged=False, id=False):
        '''
        Get the worst state of IT problems for the current user if specified.
        If get_acknowledged is True, count problems even if acknowledged ...
        If id is True, state id are returned else state texts are returned
        '''
        state = {'host':
                 {0: 'UP',
                  2: 'DOWN',
                  1: 'UNREACHABLE',
                  3: 'UNKNOWN'},
                 'service':
                 {0: 'OK',
                  2: 'CRITICAL',
                  1: 'WARNING',
                  3: 'UNKNOWN'}
                 }

        if not get_acknowledged:
            h_states = [h.state_id for h in self.get_hosts(user) if h.state_id in [1, 2] and not h.problem_has_been_acknowledged]
            s_states = [s.state_id for s in self.get_services(user) if s.state_id in [1, 2] and not s.problem_has_been_acknowledged]
        else:
            h_states = [h.state_id for h in self.get_hosts(user) if h.state_id in [1, 2]]
            s_states = [s.state_id for s in self.get_services(user) if s.state_id in [1, 2]]

        if len(h_states) == 0:
            h_state = state['host'].get(0, 'UNKNOWN') if not id else 0
        else:
            h_state = state['host'].get(max(h_states), 'UNKNOWN') if not id else max(h_states)

        if len(s_states) == 0:
            s_state = state['service'].get(0, 'UNKNOWN') if not id else 0
        else:
            s_state = state['service'].get(max(s_states), 'UNKNOWN') if not id else max(s_states)

        return h_state, s_state

    # Get the number of all problems, even the ack ones
    def get_overall_it_problems_count(self, user=None, type='all', get_acknowledged=False):
        '''
        Get the number of IT problems for the current user if specified.
        If get_acknowledged is True, count problems even if acknowledged ...

        If type is 'host', only count hosts problems
        If type is 'service', only count services problems
        '''

        if not get_acknowledged:
            h_states = [h for h in self.get_hosts(user) if h.state not in ['UP', 'PENDING'] and not h.is_impact and not h.problem_has_been_acknowledged]
            s_states = [s for s in self.get_services(user) if s.state not in ['OK', 'PENDING'] and not s.is_impact and not s.problem_has_been_acknowledged and not s.host.problem_has_been_acknowledged]
        else:
            h_states = [h for h in self.get_hosts(user) if h.state not in ['UP', 'PENDING'] and not h.is_impact]
            s_states = [s for s in self.get_services(user) if s.state not in ['OK', 'PENDING'] and not s.is_impact]

        if type == 'all':
            return len(h_states) + len(s_states)
        elif type == 'host':
            return len(h_states)
        elif type == 'service':
            return len(s_states)
        else:
            return -1

    # :TODO:maethor:150718:  Legacy methods, kept for backward compatibility. To remove.
    def get_important_elements(self, user=None):
        return self.search_hosts_and_services('bi:>2', user)

    def get_all_problems(self, user=None, to_sort=True, get_acknowledged=False):
        return self.search_hosts_and_services('isnot:UP isnot:OK isnot:PENDING ack:%s' % str(get_acknowledged), user)

    def get_problems_time_sorted(self, user=None):
        return self.get_all_problems(user=user, to_sort=None).sort(last_state_change_earlier)

datamgr = WebUIDataManager()
