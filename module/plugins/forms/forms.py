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
    user = app.checkauth()

    t = 'host'
    if '/' in name:
        t = 'service'

    return {'app': app, 'user': user, 'name': name, 'obj_type': t}


def form_var(name):
    user = app.checkauth()

    h = app.datamgr.get_host(name)
            
    return {'app': app, 'elt': h, 'user': user, 'name': name}

def form_ack(name):
    user = app.checkauth()

    return {'app': app, 'user': user, 'name': name}

def form_comment(name):
    user = app.checkauth()

    return {'app': app, 'user': user, 'name': name}

def form_comment_delete(name):
    user = app.checkauth()

    return {'app': app, 'user': user, 'name': name}
    
def form_downtime(name):
    user = app.checkauth()

    return {'app': app, 'user': user, 'name': name}

def form_downtime_delete(name):
    user = app.checkauth()

    return {'app': app, 'user': user, 'name': name}


pages = {
        form_submit_check: {'routes': ['/forms/submit_check/:name#.+#'], 'view': 'form_submit_check'},
        form_var: {'routes': ['/forms/custom_var/:name#.+#'], 'view': 'form_custom_var'},
        form_ack: {'routes': ['/forms/acknowledge/:name#.+#'], 'view': 'form_ack'},
        form_comment: {'routes': ['/forms/comment/:name#.+#'], 'view': 'form_comment'},
        form_downtime: {'routes': ['/forms/downtime/:name#.+#'], 'view': 'form_downtime'},
        form_comment_delete: {'routes': ['/forms/comment_delete/:name#.+#'], 'view': 'form_comment_delete'},
        form_downtime_delete: {'routes': ['/forms/downtime_delete/:name#.+#'], 'view': 'form_downtime_delete'},
        }
