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


### Will be populated by the UI with it's own value
app = None


def form_submit_check(name):
    t = 'host'
    if '/' in name:
        t = 'service'

    return {'name': name, 'obj_type': t}


def form_change_var(name):
    variable = app.request.GET.get('variable', '')
    value = app.request.GET.get('value', '')
    
    user = app.request.environ['USER']
    elt = app.datamgr.get_element(name, user) or app.redirect404()

    return {'elt': elt, 'name': name, 'variable': variable, 'value': value}

def form_var(name):
    user = app.request.environ['USER']
    elt = app.datamgr.get_element(name, user) or app.redirect404()
    return {'elt': elt, 'name': name}

def form_ack_add(name):
    user = app.request.environ['USER']
    elt = app.datamgr.get_element(name, user) or app.redirect404()
    return {'elt': elt, 'name': name}

def form_ack_remove(name):
    user = app.request.environ['USER']
    elt = app.datamgr.get_element(name, user) or app.redirect404()
    return {'elt': elt, 'name': name}

def form_comment_add(name):
    user = app.request.environ['USER']
    app.datamgr.get_element(name, user) or app.redirect404()
    return {'name': name}

def form_comment_delete(name):
    user = app.request.environ['USER']
    app.datamgr.get_element(name, user) or app.redirect404()
    comment = app.request.GET.get('comment', '-1')
    return {'name': name, 'comment': comment}

def form_comment_delete_all(name):
    user = app.request.environ['USER']
    app.datamgr.get_element(name, user) or app.redirect404()
    return {'name': name}

def form_downtime_add(name):
    user = app.request.environ['USER']
    elt = app.datamgr.get_element(name, user) or app.redirect404()
    return {'elt': elt, 'name': name}

def form_downtime_delete(name):
    user = app.request.environ['USER']
    elt = app.datamgr.get_element(name, user) or app.redirect404()
    downtime = app.request.GET.get('downtime', '-1')
    return {'elt': elt, 'name': name, 'downtime': downtime}

def form_downtime_delete_all(name):
    user = app.request.environ['USER']
    app.datamgr.get_element(name, user) or app.redirect404()
    return {'name': name}


pages = {
        form_submit_check:          {'routes': ['/forms/submit_check/<name:path>'],             'view': 'form_submit_check'},
        
        form_change_var:            {'routes': ['/forms/change_var/<name:path>'],               'view': 'form_change_var'},
        
        form_comment_add:           {'routes': ['/forms/comment/add/<name:path>'],              'view': 'form_comment_add'},
        form_comment_delete:        {'routes': ['/forms/comment/delete/<name:path>'],           'view': 'form_comment_delete'},
        form_comment_delete_all:    {'routes': ['/forms/comment/delete_all/<name:path>'],       'view': 'form_comment_delete_all'},
        
        form_downtime_add:          {'routes': ['/forms/downtime/add/<name:path>'],             'view': 'form_downtime_add'},
        form_downtime_delete:       {'routes': ['/forms/downtime/delete/<name:path>'],          'view': 'form_downtime_delete'},
        form_downtime_delete_all:   {'routes': ['/forms/downtime/delete_all/<name:path>'],      'view': 'form_downtime_delete_all'},
        
        form_ack_add:               {'routes': ['/forms/acknowledge/add/<name:path>'],          'view': 'form_ack_add'},
        form_ack_remove:            {'routes': ['/forms/acknowledge/remove/<name:path>'],       'view': 'form_ack_remove'},
        }
