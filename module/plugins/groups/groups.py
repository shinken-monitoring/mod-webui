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

# Will be populated by the UI with it's own value
app = None


def show_contactgroups():
    user = app.request.environ['USER']
    cgroups = sorted(app.datamgr.get_contactgroups(user), key=lambda cg: cg.contactgroup_name)

    return {
        'contactgroups': cgroups,
        'user': user
        }


def show_hostgroup(name):
    app.bottle.redirect("/all?search=type:host hg:" + name)


def show_hostgroups():
    user = app.request.environ['USER']

    # Set hostgroups level ...
    # @mohierf: should be done only once for initialization ... to be delegated to datamanager!
    app.datamgr.set_hostgroups_level(user)

    level = int(app.request.GET.get('level', 0))
    parent = app.request.GET.get('parent', None)

    return {
        'level': level,
        'hostgroups': sorted(app.datamgr.get_hostgroups(parent=parent, user=user), key=lambda hostgroup: hostgroup.hostgroup_name)
        }


def show_hostgroups_dashboard():
    user = app.request.environ['USER']

    # Set hostgroups level ...
    app.datamgr.set_hostgroups_level(user)

    level = int(app.request.GET.get('level', 0))
    parent = app.request.GET.get('parent', None)

    return {
        'level': level,
        'hostgroups': sorted(app.datamgr.get_hostgroups(parent=parent, user=user), key=lambda hostgroup: hostgroup.hostgroup_name)
        }


def show_servicegroup(name):
    app.bottle.redirect("/all?search=type:service sg:" + name)


def show_servicegroups():
    user = app.request.environ['USER']

    # Set servicegroups level ...
    # @mohierf: should be done only once for initialization ... to be delegated to datamanager!
    app.datamgr.set_servicegroups_level(user)

    level = int(app.request.GET.get('level', 0))
    parent = app.request.GET.get('parent', None)

    return {
        'level': level,
        'servicegroups': sorted(app.datamgr.get_servicegroups(parent=parent, user=user), key=lambda servicegroup: servicegroup.servicegroup_name)
        }

pages = {
    show_contactgroups: {
        'name': 'ContactsGroups', 'route': '/contacts-groups', 'view': 'contacts-groups-overview', 'static': True
    },
    show_hostgroup: {
        'name': 'HostsGroup', 'route': '/hosts-group/:name', 'view': 'hosts-group', 'static': True
    },
    show_hostgroups: {
        'name': 'HostsGroups', 'route': '/hosts-groups', 'view': 'hosts-groups-overview', 'static': True
    },
    show_hostgroups_dashboard: {
        'name': 'HostsGroupsDashboard', 'route': '/hosts-groups-dashboard', 'view': 'hosts-groups-dashboard', 'static': True
    },
    show_servicegroup: {
        'name': 'ServicesGroup', 'route': '/services-group/:name', 'view': 'services-group', 'static': True
    },
    show_servicegroups: {
        'name': 'ServicesGroups', 'route': '/services-groups', 'view': 'services-groups-overview', 'static': True
    }
}
