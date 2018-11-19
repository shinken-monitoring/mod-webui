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

# import user
from ui_user import User

# Will be populated by the UI with it's own value
app = None


# Contact page
def show_contact(name):
    user = app.request.environ['USER']
    contact = app.datamgr.get_contact(name=name, user=user) or app.redirect404()

    return {'contact': User.from_contact(contact)}


# All contacts
def show_contacts():
    user = app.request.environ['USER']
    _ = user.is_administrator() or app.redirect403()

    return {'contacts': sorted(app.datamgr.get_contacts(user=user), key=lambda c: c.contact_name)}


pages = {
    show_contact: {
        'name': 'Contact', 'route': '/contact/:name', 'view': 'contact',
        'static': True
    },
    show_contacts: {
        'name': 'Contacts', 'route': '/contacts', 'view': 'contacts',
        'static': True
    }
}
