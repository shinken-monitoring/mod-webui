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


# Will be populated by the UI with it's own value
app = None


def form_submit_check(name):
    t = 'host'
    if '/' in name:
        t = 'service'

    return {'name': name, 'obj_type': t}


def form_ack_add(name):
    user = app.request.environ['USER']
    elt = app.datamgr.get_element(name, user) or app.redirect404()
    return {'elt': elt, 'name': name}


def form_ack_remove(name):
    user = app.request.environ['USER']
    elt = app.datamgr.get_element(name, user) or app.redirect404()
    return {'elt': elt, 'name': name}


def form_downtime_add(name):
    user = app.request.environ['USER']
    elt = app.datamgr.get_element(name, user) or app.redirect404()
    return {'elt': elt, 'name': name, 'default_downtime_hours': app.default_downtime_hours}


def form_downtime_delete_all(name):
    user = app.request.environ['USER']
    elt = app.datamgr.get_element(name, user) or app.redirect404()
    return {'elt': elt, 'name': name}


pages = {
    form_submit_check: {
        'name': 'SubmitCheck', 'route': '/forms/submit_check/<name:path>',
        'view': 'form_submit_check'
    },

    form_downtime_add: {
        'name': 'DowntimeAdd', 'route': '/forms/downtime/add/<name:path>',
        'view': 'form_downtime_add'
    },
    form_downtime_delete_all: {
        'name': 'DowntimeDeleteAll', 'route': '/forms/downtime/delete_all/<name:path>',
        'view': 'form_downtime_delete_all'
    },

    form_ack_add: {
        'name': 'AckAdd', 'route': '/forms/acknowledge/add/<name:path>',
        'view': 'form_ack_add'
    },
    form_ack_remove: {
        'name': 'AckDelete', 'route': '/forms/acknowledge/remove/<name:path>',
        'view': 'form_ack_remove'
    }
}
