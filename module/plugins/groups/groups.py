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


def show_hostgroup(name):
    app.bottle.redirect("/all?search=type:host hg:" + name)


def show_hostgroups():
    user = app.check_user_authentication()

    # Set hostgroups level ...
    app.set_hostgroups_level(user)

    return {
        'app': app, 'user': user,
        'hostgroups': sorted(app.get_hostgroups(), key=lambda hostgroup: hostgroup.hostgroup_name)
        }


def show_servicegroup(name):
    app.bottle.redirect("/all?search=type:service hg:" + name)


def show_servicegroups():
    user = app.check_user_authentication()

    # Set servicegroups level ...
    app.set_servicegroups_level(user)

    return {
        'app': app, 'user': user,
        'servicegroups': sorted(app.get_servicegroups(), key=lambda servicegroup: servicegroup.servicegroup_name)
        }

pages = {
    show_hostgroup: {'routes': ['/hosts-group/:name'], 'view': 'hosts-group', 'static': True},
    show_hostgroups: {'routes': ['/hosts-groups'], 'view': 'hosts-groups-overview', 'static': True},
    show_servicegroup: {'routes': ['/services-group/:name'], 'view': 'services-group', 'static': True},
    show_servicegroups: {'routes': ['/services-groups'], 'view': 'services-groups-overview', 'static': True},
}
