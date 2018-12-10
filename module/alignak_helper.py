#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Copyright (C) 2009-2012:
#    Gabes Jean, naparuba@gmail.com
#    Gerhard Lausser, Gerhard.Lausser@consol.de
#    Gregory Starck, g.starck@gmail.com
#    Hartmut Goebel, h.goebel@goebel-consult.de
#    Andreas Karfusehr, andreas@karfusehr.de
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
import datetime
import copy
import math
import operator
import re

from collections import OrderedDict

try:
    import json
except ImportError:
    # For old Python version, load
    # simple json (it can be hard json?! It's 2 functions guy!)
    try:
        import simplejson as json
    except ImportError:
        print("Error: you need the json or simplejson module")
        raise

from shinken.misc.sorter import hst_srv_sort
from shinken.misc.perfdata import PerfDatas


# pylint: disable=no-self-use
class AlignakHelper(object):
    def get_event_icon(self, event, disabled=False, label='', use_title=True):
        '''
            Get an Html formatted string to display a monitoring event

            If disabled is True, the font used is greyed

            If label is empty, only an icon is returned
            If label is set as 'state', the icon title is used as text
            Else, the content of label is used as text near the icon.

            If use_title is False, do not include title attribute.

            Returns a span element containing a Font Awesome icon that depicts
           consistently the event and its state
        '''
        cls = event.get('type', 'unknown').lower()
        state = event.get('state', 'n/a').upper()
        state_type = event.get('state_type', 'n/a').upper()
        hard = (state_type == 'HARD')

        # Icons depending upon element and real state ...
        # ; History
        icons = {
            "unknown": {
                "class": "history_Unknown",
                "text": "Unknown event",
                "icon": "question"
            },

            "retention_load": {
                "class": "history_RetentionLoad",
                "text": "Retention load",
                "icon": "save"
            },
            "retention_save": {
                "class": "history_RetentionSave",
                "text": "Retention save",
                "icon": "save"
            },

            "alert": {
                "class": "history_Alert",
                "text": "Monitoring alert",
                "icon": "bolt"
            },

            "notification": {
                "class": "history_Notification",
                "text": "Monitoring notification sent",
                "icon": "paper-plane"
            },

            "check_result": {
                "class": "history_CheckResult",
                "text": "Check result",
                "icon": "bolt"
            },

            "comment": {
                "class": "history_WebuiComment",
                "text": "WebUI comment",
                "icon": "send"
            },
            "timeperiod_transition": {
                "class": "history_TimeperiodTransition",
                "text": "Timeperiod transition",
                "icon": "clock-o"
            },
            "external_command": {
                "class": "history_ExternalCommand",
                "text": "External command",
                "icon": "wrench"
            },

            "event_handler": {
                "class": "history_EventHandler",
                "text": "Monitoring event handler",
                "icon": "bolt"
            },
            "flapping_start": {
                "class": "history_FlappingStart",
                "text": "Monitoring flapping start",
                "icon": "flag"
            },
            "flapping_stop": {
                "class": "history_FlappingStop",
                "text": "Monitoring flapping stop",
                "icon": "flag-o"
            },
            "downtime_start": {
                "class": "history_DowntimeStart",
                "text": "Monitoring downtime start",
                "icon": "ambulance"
            },
            "downtime_cancelled": {
                "class": "history_DowntimeCancelled",
                "text": "Monitoring downtime cancelled",
                "icon": "ambulance"
            },
            "downtime_end": {
                "class": "history_DowntimeEnd",
                "text": "Monitoring downtime stopped",
                "icon": "ambulance"
            },
            "acknowledge_start": {
                "class": "history_AckStart",
                "text": "Monitoring acknowledge start",
                "icon": "check"
            },
            "acknowledge_cancelled": {
                "class": "history_AckCancelled",
                "text": "Monitoring acknowledge cancelled",
                "icon": "check"
            },
            "acknowledge_end": {
                "class": "history_AckEnd",
                "text": "Monitoring acknowledge expired",
                "icon": "check"
            },
        }

        back = '''<i class="fa fa-circle fa-stack-2x font-%s"></i>''' \
               % (state.lower() if not disabled else 'greyed')

        icon_color = 'fa-inverse'
        icon_style = ""
        if not hard:
            icon_style = 'style="opacity: 0.5"'

        try:
            icon = icons[cls]['icon']
            title = icons[cls]['text']
        except KeyError:
            cls = 'unknown'
            icon = icons[cls]['icon']
            title = icons[cls]['text']

        front = '''<i class="fa fa-%s fa-stack-1x %s"></i>''' % (icon, icon_color)

        if use_title:
            icon_text = '''<span class="fa-stack" %s title="%s">%s%s</span>''' % (icon_style, title, back, front)
        else:
            icon_text = '''<span class="fa-stack" %s>%s%s</span>''' % (icon_style, back, front)

        if label == '':
            return icon_text

        color = state.lower() if not disabled else 'greyed'
        if label == 'title':
            label = title
        return '''
          <span class="font-%s">
             %s&nbsp;<span class="num">%s</span>
          </span>
          ''' % (color, icon_text, label)


alignak_helper = AlignakHelper()
