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

def show_htag(name):
    app.bottle.redirect("/all?search=type:host htag:" + name)


def show_stag(name):
    app.bottle.redirect("/all?search=type:service stag:" + name)


def show_htags():
    user = app.request.environ['USER']

    fake_htags = []
    for tag in app.datamgr.get_host_tags():
        hosts = app.datamgr.get_hosts_tagged_with(tag[0], user)
        if len(hosts) > 0:
            fake_htags.append({'name': tag[0], 'hosts': hosts})

    return {'htags': fake_htags}


def show_stags():
    user = app.request.environ['USER']

    fake_stags = []
    for tag in app.datamgr.get_service_tags():
        services = app.datamgr.get_services_tagged_with(tag[0], user)
        if len(services) > 0:
            fake_stags.append({'name': tag[0], 'services': services})

    return {'stags': fake_stags}


pages = {
    show_htag: {
        'name': 'HostsTag', 'route': '/hosts-tag/:name', 'view': 'hosts-tag', 'static': True
    },
    show_stag: {
        'name': 'ServicesTag', 'route': '/services-tag/:name', 'view': 'services-tag', 'static': True
    },
    show_htags: {
        'name': 'HostsTags', 'route': '/hosts-tags', 'view': 'hosts-tags-overview', 'static': True
    },
    show_stags: {
        'name': 'ServicesTags', 'route': '/services-tags', 'view': 'services-tags-overview', 'static': True
    }
}
