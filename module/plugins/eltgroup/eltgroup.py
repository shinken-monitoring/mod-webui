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
import time

from shinken.util import safe_print
from shinken.misc.filter  import only_related_to

# Global value that will be changed by the main app
app = None


def show_impacts():
    # First we look for the user sid
    # so we bail out if it's a false one
    user = app.get_user_auth()

    if not user:
        app.bottle.redirect("/user/login")
        #return {'app': app, 'impacts': {}, 'valid_user': False, 'user': user}

    all_imp_impacts = only_related_to(app.datamgr.get_important_elements(),user)
    all_imp_impacts.sort(hst_srv_sort)

    impacts = {}

    imp_id = 0
    for imp in all_imp_impacts:
        #safe_print("FIND A BAD SERVICE IN IMPACTS", imp.get_dbg_name())
        imp_id += 1
        impacts[imp_id] = imp

    return {'app': app, 'impacts': impacts, 'valid_user': True, 'user': user}


pages = {show_impacts: {'routes': ['/eltgroup'], 'view': 'eltgroupoverview', 'static': True}}
