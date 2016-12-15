#!/usr/bin/python

# -*- coding: utf-8 -*-

# Copyright (C) 2009-2014:
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


app = None


def notification_toggle():
    wid = app.request.query.get('wid', 'widget_notification_toggle')
    collapsed = (app.request.query.get('collapsed', 'False') == 'True')

    user = app.request.environ['USER']

    return {
        'title': 'Notification Toggle',
        'wid': wid,
        'collapsed': collapsed,
        'options': {},
        'base_url': '/widget/notification_toggle',
        'is_enabled': app.datamgr.get_configs()[0].notifications_enabled,
        'user': user,
    }

notification_toggle_widget_desc = '''<h4>Notification Toggle</h4>
Display a notification toggle switch & the current state of notifications.
'''

pages = {
    notification_toggle: {
        'name': 'Notification Toggle',
        'route': '/widget/notification_toggle',
        'view': 'widget_notification_toggle',
        'static': True,
        'widget': ['dashboard'],
        'widget_desc': notification_toggle_widget_desc,
        'widget_name': 'notification_toggle',
        'widget_picture': '/static/notifications/img/widget_notification_toggle.png',  # noqa
    }
}
