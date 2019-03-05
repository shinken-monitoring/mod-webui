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
from shinken.macroresolver import MacroResolver
from shinken.log import logger


# pylint: disable=no-self-use
class Helper(object):
    def __init__(self):
        pass

    def print_date(self, t, format='%Y-%m-%d %H:%M:%S'):
        """
        For a unix time return something like
        Tue Aug 16 13:56:08 2011

        :param t:
        :param format:
        :return:
        """
        if t == 0 or t is None:
            return 'N/A'

        if format:
            return time.strftime(format, time.localtime(t))

        return time.asctime(time.localtime(t))

    def print_duration(self, t, just_duration=False, x_elts=0):
        """
        For a time, print something like
        10m 37s  (just duration = True)
        N/A if got bogus number (like 1970 or None)
        1h 30m 22s ago (if t < now)
        Now (if t == now)
        in 1h 30m 22s
        Or in 1h 30m (no sec, if we ask only_x_elements=2, 0 means all)

        :param t:
        :param just_duration:
        :param x_elts:
        :return:
        """
        if t == 0 or t is None:
            return 'N/A'

        # Get the difference between now and the time of the user
        seconds = int(time.time()) - int(t)

        # If it's now, say it :)
        if seconds == 0:
            return 'Now'

        in_future = False

        # Remember if it's in the future or not
        if seconds < 0:
            in_future = True

        # Now manage all case like in the past
        seconds = abs(seconds)

        seconds = int(round(seconds))
        minutes, seconds = divmod(seconds, 60)
        hours, minutes = divmod(minutes, 60)
        days, hours = divmod(hours, 24)
        weeks, days = divmod(days, 7)
        months, weeks = divmod(weeks, 4)
        years, months = divmod(months, 12)

        minutes = int(minutes)
        hours = int(hours)
        days = int(days)
        weeks = int(weeks)
        months = int(months)
        years = int(years)

        duration = []
        if years > 0:
            duration.append('%dy' % years)
        else:
            if months > 0:
                duration.append('%dM' % months)
            if weeks > 0:
                duration.append('%dw' % weeks)
            if days > 0:
                duration.append('%dd' % days)
            if hours > 0:
                duration.append('%dh' % hours)
            if minutes > 0:
                duration.append('%dm' % minutes)
            if seconds > 0:
                duration.append('%ds' % seconds)

        # Now filter the number of printed elements if ask
        if x_elts >= 1:
            duration = duration[:x_elts]

        # Maybe the user just want the duration
        if just_duration:
            return ' '.join(duration)

        # Now manage the future or not print
        if in_future:
            return 'in ' + ' '.join(duration)

        return ' '.join(duration) + ' ago'

    def print_duration_and_date(self, t, just_duration=False, x_elts=2):
        """
        Prints the duration with the date as title

        :param t:
        :param just_duration:
        :param x_elts:
        :return:
        """
        return "<span title='%s'>%s</span>" \
               % (self.print_date(t, format="%d %b %Y %H:%M:%S"), self.print_duration(t, just_duration, x_elts=x_elts))

    def sort_elements(self, elements):
        e_list = copy.copy(elements)
        e_list.sort(hst_srv_sort)
        return e_list

    def group_by_daterange(self, l, key):
        today = datetime.datetime.now().date()

        groups = OrderedDict([('In the future', []), ('Today', []), ('Yesterday', []), ('This month', [])])

        for e in l:
            d = datetime.datetime.fromtimestamp(key(e)).date()
            if d > today:
                groups['In the future'].append(e)
            elif d == today:
                groups['Today'].append(e)
            elif d.year == today.year and d.month == today.month and d.day == today.day - 1:
                groups['Yesterday'].append(e)
            elif d.year == today.year and d.month == today.month:
                groups['This month'].append(e)
            elif d.year == today.year:
                month = d.strftime("%B")
                if month not in groups:
                    groups[month] = []
                groups[month].append(e)
            else:
                if d.year not in groups:
                    groups[d.year] = []
                groups[d.year].append(e)

        return groups

    def get_small_icon_state(self, obj):
        """
        Get the small state for host/service icons and satellites ones

        :param obj:
        :return:
        """
        if obj.__class__.my_type in ['service', 'host']:
            if obj.state == 'PENDING':
                return 'unknown'
            if obj.state == 'OK':
                return 'ok'
            if obj.state == 'UP':
                return 'up'
            # Outch, not a good state...
            if obj.problem_has_been_acknowledged:
                return 'ack'
            if obj.in_scheduled_downtime:
                return 'downtime'
            if obj.is_flapping:
                return 'flapping'
            # Ok, no excuse, it's a true error...
            return obj.state.lower()
        # Maybe it's a satellite
        if obj.__class__.my_type in ['scheduler', 'poller',
                                     'reactionner', 'broker',
                                     'receiver']:
            if not obj.alive:
                return 'critical'
            if not obj.reachable:
                return 'warning'
            return 'ok'
        return 'unknown'

    def get_business_impact_text(self, business_impact, text=False):
        """
        Give a business impact as text and stars if need
        If text=True, returns text+stars, else returns stars only ...
        :param business_impact:
        :param text:
        :return:
        """
        txts = {0: 'None', 1: 'Low', 2: 'Normal',
                3: 'Important', 4: 'Very important', 5: 'Business critical'}
        nb_stars = max(0, business_impact - 2)
        stars = '<small style="vertical-align: middle;"><i class="fas fa-star"></i></small>' * nb_stars

        if text:
            res = "%s %s" % (txts.get(business_impact, 'Unknown'), stars)
        else:
            res = stars
        return res

    def get_on_off(self, status=False, title=None, message=''):
        """
        Give an enabled/disabled state based on font-awesome with optional title and message

        :param status:
        :param title:
        :param message:
        :return:
        """
        if not title:
            if status:
                title = 'Enabled'
            else:
                title = 'Disabled'

        if status:
            return '''<i title="%s" class="fas fa-check font-green">%s</i>''' % (title, message)

        return '''<i title="%s" class="fas fa-times font-red">%s</i>''' % (title, message)

    def get_link(self, obj, short=False):
        if obj.__class__.my_type == 'service':
            if short:
                name = obj.get_name()
            else:
                name = obj.get_full_name()

            return '<a href="/service/%s"> %s </a>' % (obj.get_full_name(), name)

        # if not service, host
        return '<a href="/host/%s"> %s </a>' % (obj.get_full_name(), obj.get_full_name())

    def get_link_dest(self, obj):
        """
        Give only the /service/blabla or /host blabla string, like for buttons inclusion

        :param obj:
        :return:
        """
        return "/%s/%s" % (obj.__class__.my_type, obj.get_full_name())

    def get_fa_icon_state(self, obj=None, cls='host', state='UP', disabled=False, label='', use_title=True):
        '''
            Get an Html formatted string to display host/service state

            If obj is specified, obj class and state are used.
            If obj is None, cls and state parameters are used.

            If disabled is True, the font used is greyed

            If label is empty, only an icon is returned
            If label is set as 'state', the icon title is used as text
            Else, the content of label is used as text near the icon.

            If use_title is False, do not include title attribute.

            Returns a span element containing a Font Awesome icon that depicts
           consistently the host/service current state (see issue #147)
        '''
        state = obj.state.upper() if obj is not None else state.upper()
        flapping = (obj and obj.is_flapping) or state == 'FLAPPING'
        ack = (obj and obj.problem_has_been_acknowledged) or state == 'ACK'
        downtime = (obj and obj.in_scheduled_downtime) or state == 'DOWNTIME'
        hard = (not obj or obj.state_type == 'HARD')

        # Icons depending upon element and real state ...
        icons = {
            'host': {
                'UP': 'server',
                'DOWN': 'server',
                'UNREACHABLE': 'server',
                'ACK': 'check',
                'DOWNTIME': 'clock',
                'FLAPPING': 'cog fa-spin',
                'PENDING': 'server',
                'UNKNOWN': 'server'
            },
            'service': {
                'OK': 'arrow-up',
                'CRITICAL': 'arrow-down',
                'WARNING': 'exclamation',
                'UNREACHABLE': 'question',
                'ACK': 'check',
                'DOWNTIME': 'clock',
                'FLAPPING': 'cog fa-spin',
                'PENDING': 'spinner fa-circle-notch',
                'UNKNOWN': 'question'
            }
        }

        cls = obj.__class__.my_type if obj is not None else cls

        back = '''<i class="fas fa-%s fa-stack-2x font-%s"></i>''' \
               % (icons[cls]['FLAPPING'] if flapping else 'circle',
                  state.lower() if not disabled else 'greyed')
        if flapping:
            back += '''<i class="fas fa-circle fa-stack-1x font-%s"></i>''' \
                    % (state.lower() if not disabled else 'greyed')

        title = "%s is %s" % (cls, state)

        if flapping:
            icon_color = 'fa-inverse' if not disabled else 'font-greyed'
            title += " and is flapping"
        else:
            icon_color = 'fa-inverse'

        if downtime or ack or not hard:
            icon_style = 'style="opacity: 0.5"'
        else:
            icon_style = ""

        if state == 'DOWNTIME':
            icon = icons[cls]['DOWNTIME']
            title += " and in scheduled downtime"
        elif state == 'ACK':
            icon = icons[cls]['ACK']
            title += " and acknowledged"
        else:
            icon = icons[cls].get(state, 'UNKNOWN')

        if obj and not (obj.active_checks_enabled or obj.passive_checks_enabled):
            icon_color = 'bg-lightgrey'

        front = '''<i class="fas fa-%s fa-stack-1x %s"></i>''' % (icon, icon_color)

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

    def get_fa_icon_state_and_label(self, obj=None, cls='host', state='UP', label="", disabled=False, use_title=True):
        color = state.lower() if not disabled else 'greyed'
        return '''
          <span class="font-%s">
             %s&nbsp;<span class="num">%s</span>
          </span>
          ''' % (color,
                 self.get_fa_icon_state(obj=obj, cls=cls, state=state, disabled=disabled, use_title=use_title),
                 label)

    # :TODO:maethor:150609: Rewrite this function
    def get_navi(self, total, pos, step=30):
        """
        Get the pages navigation HTML widget

        :param total:
        :param pos:
        :param step:
        :return:
        """
        step = float(step)
        nb_pages = math.ceil(total / step) if step != 0 else 0
        current_page = int(pos / step) if step != 0 else 0

        step = int(step)

        res = []

        nb_max_items = 2

        if current_page >= nb_max_items:
            # Name, start, end, is_current
            res.append((u'«', 0, step, False))
            res.append(('...', None, None, False))

        # pylint: disable=undefined-variable
        # Because xrange...
        for i in xrange(current_page - (nb_max_items / 2), current_page + 1 + (nb_max_items / 2)):
            if i < 0:
                continue
            is_current = (i == current_page)
            start = int(i * step)
            # Maybe we are generating a page too high, bail out
            if start > total:
                continue

            end = int((i + 1) * step)
            res.append(('%d' % (i + 1), start, end, is_current))

        if current_page < nb_pages - nb_max_items:
            start = int((nb_pages - (nb_max_items - 1)) * step)
            end = int(total)
            # end = int(nb_pages * step)
            res.append(('...', None, None, False))
            res.append((u'»', start, end, False))

        return res

    def get_html_color(self, state):
        colors = {
            'CRITICAL': "#d9534f",
            'DOWN': "#d9534f",
            'WARNING': "#f0ad4e",
            'OK': "#5cb85c",
            'UP': "#5cb85c",
            'PENDING': '#49AFCD',
            'UNKNOWN': '#49AFCD'
        }

        if state in colors:
            return colors[state]

        return colors['UNKNOWN']

    def get_perfdata_pie(self, p):
        if p.max is not None:
            color = self.get_html_color('OK')
            used_value = p.value - (p.min or 0)
            unused_value = p.max - (p.min or 0) - used_value
            if p.warning or p.critical:
                if p.warning <= p.critical:
                    if p.value >= p.warning:
                        color = self.get_html_color('WARNING')
                    if p.value >= p.critical:
                        color = self.get_html_color('CRITICAL')
                else:
                    # inverted thresholds : OK > WARNING > CRITICAL
                    if p.value <= p.warning:
                        color = self.get_html_color('WARNING')
                    if p.value <= p.critical:
                        color = self.get_html_color('CRITICAL')
                    used_value, unused_value = unused_value, used_value

            used_value = p.value - (p.min or 0)
            unused_value = p.max - (p.min or 0) - used_value
            if unused_value + used_value:
                used_pct = (float(used_value) / float(unused_value + used_value)) * 100
            else:
                used_pct = None

            title = "%s %s%s" % (p.name, p.value, p.uom)
            if p.uom != '%' and isinstance(used_pct, float):
                title += " ({:.2f}%)".format(used_pct)

            return '<span class="sparkline piechart" title="%s" role="img" sparkType="pie" ' \
                   'sparkBorderWidth="0" sparkSliceColors="[%s,#f5f5f5]" values="%s,%s"></span>' \
                   % (title, color, used_value, unused_value)
        return ""

    def get_perfdata_pies(self, elt):
        return " ".join([self.get_perfdata_pie(p) for p in PerfDatas(elt.perf_data)])

    def get_perfdata_table(self, elt):
        perfdatas = PerfDatas(elt.perf_data)
        display_min = any(p.min for p in perfdatas)
        display_max = any(p.max is not None for p in perfdatas)
        display_warning = any(p.warning is not None for p in perfdatas)
        display_critical = any(p.critical is not None for p in perfdatas)

        s = '<table class="table table-condensed table-w-condensed">'
        s += '<tr><th></th><th>Label</th><th>Value</th>'
        if display_min:
            s += '<th>Min</th>'
        if display_max:
            s += '<th>Max</th>'
        if display_warning:
            s += '<th>Warning</th>'
        if display_critical:
            s += '<th>Critical</th>'
        s += '</tr>'

        for p in perfdatas:
            s += '<tr><td>%s</td><td>%s</td><td>%s %s</td>' % (self.get_perfdata_pie(p), p.name, p.value, p.uom)
            if display_min:
                if p.min is not None:
                    s += '<td>%s %s</td>' % (p.min, p.uom)
                else:
                    s += '<td></td>'
            if display_max:
                if p.max is not None:
                    s += '<td>%s %s</td>' % (p.max, p.uom)
                else:
                    s += '<td></td>'
            if display_warning:
                if p.warning is not None:
                    s += '<td>%s %s</td>' % (p.warning, p.uom)
                else:
                    s += '<td></td>'
            if display_critical:
                if p.critical is not None:
                    s += '<td>%s %s</td>' % (p.critical, p.uom)
                else:
                    s += '<td></td>'
            s += '</tr>'
        s += '</table>'

        return s

    def get_html_id(self, elt):
        """
        We want the html id of an host or a service. It's basically
        the full_name with / changed as -- (because in html, / is not valid :) )

        :param elt:
        :return:
        """
        return self.strip_html_id(elt.get_full_name())

    def strip_html_id(self, s):
        return s.replace('/', '--').replace(' ', '_').replace('.', '_').replace(':', '_')

    def make_html_id(self, s):
        """
        Make an HTML element identifier

        :param s:
        :return:
        """
        return re.sub('[^A-Za-z0-9]', '', s)

    def get_uri_name(self, elt):
        """
        URI with spaces are BAD, must change them with %20

        :param elt:
        :return:
        """
        return elt.get_full_name().replace(' ', '%20')

    def get_aggregation_paths(self, p):
        p = p.strip()
        if p and not p.startswith('/'):
            p = '/' + p
        if p.endswith('/'):
            p = p[-1]
        return [s.strip() for s in p.split('/')]

    def compute_aggregation_tree_worse_state(self, tree):
        # First ask to our sons to compute their states
        for s in tree['sons']:
            self.compute_aggregation_tree_worse_state(s)
        # Ok now we can look at worse between our services
        # and our sons
        # get a list of all states
        states = [s['state'] for s in tree['sons']]
        for s in tree['services']:
            states.append(s.state.lower())

        # ok now look at what is worse here
        order = ['critical', 'warning', 'unknown', 'unreachable', 'ok', 'pending']
        for o in order:
            if o in states:
                tree['state'] = o
                return

        # Should be never call or we got a major problem...
        tree['state'] = 'unknown'

    def assume_and_get_path_in_tree(self, tree, paths):
        current_full_path = ''
        for p in paths:
            # Don't care about void path, like for root
            if not p:
                continue
            current_full_path += '/' + p
            found = False
            for s in tree['sons']:
                # Maybe we find the good son, if so go on this level
                if p == s['path']:
                    tree = s
                    found = True
                    break
            # Did we find our son? If no, create it and jump into it
            if not found:
                s = {'path': p, 'sons': [], 'services': [], 'state': 'unknown', 'full_path': current_full_path}
                tree['sons'].append(s)
                tree = s
        return tree

    def get_host_service_aggregation_tree(self, h, app=None):
        tree = {'path': '/', 'sons': [], 'services': [], 'state': 'unknown', 'full_path': '/'}
        for s in h.services:
            p = s.aggregation
            paths = self.get_aggregation_paths(p)
            leaf = self.assume_and_get_path_in_tree(tree, paths)
            leaf['services'].append(s)

        self.compute_aggregation_tree_worse_state(tree)

        return tree

    def print_aggregation_tree(self, tree, html_id, expanded=False, max_sons=5):
        path = tree['path']
        full_path = tree['full_path']
        sons = tree['sons']
        services = tree['services']
        state = tree['state']
        _id = '%s-%s' % (html_id, self.strip_html_id(full_path))
        s = ''

        display = 'block'
        img = 'reduce.png'
        icon = 'minus'
        list_state = 'expanded'

        if path != '/':
            # # If our state is OK, hide our sons
            # if state == 'ok' and (not expanded or len(sons) >= max_sons):
            #     display = 'none'
            #     img = 'expand.png'
            #     icon = 'plus'
            #     list_state = 'collapsed'

            s += """<a class="toggle-list" data-state="%s" data-target="ag-%s">
            <span class="alert-small alert-%s"> <i class="fas fa-%s"></i> %s&nbsp;</span> </a>""" \
                 % (list_state, _id, state, icon, path)

        s += """<ul name="ag-%s" class="list-group" style="display: %s;">""" % (_id, display)
        # If we got no parents, no need to print the expand icon
        if sons:
            for son in sons:
                sub_s = self.print_aggregation_tree(son, html_id, expanded=expanded)
                s += '<li class="list-group-item">%s</li>' % sub_s

        s += '<li class="list-group-item">'
        if path == '/' and services:
            s += """<span class="alert-small"> Others </span>"""

        if services:
            s += '<ul class="list-group">'
            # Sort our services before print them
            services.sort(hst_srv_sort)
            for svc in services:
                s += '<li class="list-group-item">'
                s += helper.get_fa_icon_state(svc)
                s += self.get_link(svc, short=True)
                if svc.business_impact > 2:
                    s += "(" + self.get_business_impact_text(svc.business_impact) + ")"
                s += """ is <span class="font-%s"><strong>%s</strong></span>""" % (svc.state.lower(), svc.state)
                s += " since %s" % self.print_duration(svc.last_state_change, just_duration=True, x_elts=2)
                s += "</li>"
            s += "</ul></li>"
        else:
            s += "</li>"

        s += "</ul>"

        return s

    def print_business_rules(self, tree, level=0, source_problems=None):
        if source_problems is None:
            source_problems = []
        node = tree['node']
        name = node.get_full_name()
        fathers = tree['fathers']
        fathers = sorted(fathers, key=lambda dict: dict['node'].get_full_name())
        s = ''

        # Maybe we are the root problem of this, and so we are printing it
        root_str = ''
        if node in source_problems:
            root_str = ' <span class="alert-small alert-critical"> Root problem</span>'

        # Do not print the node if it's the root one, we already know its state!
        if level != 0:
            s += helper.get_fa_icon_state(node)
            s += self.get_link(node, short=True)
            if node.business_impact > 2:
                s += "(" + self.get_business_impact_text(node.business_impact) + ")"
            s += """ is <span class="font-%s"><strong>%s</strong></span>""" % (node.state.lower(), node.state)
            s += """ since <span title="%s">%s""" \
                 % (time.strftime("%d %b %Y %H:%M:%S", time.localtime(node.last_state_change)),
                    self.print_duration(node.last_state_change, just_duration=True, x_elts=2))

        # If we got no parents, no need to print the expand icon
        if fathers:
            # We look if the below tree is good or not
            tree_is_good = (node.state_id == 0)

            # If the tree is good, we will use an expand image
            # and hide the tree
            if tree_is_good:
                display = 'none'
                list_state = 'collapsed'
                icon = 'plus'
            else:  # we will already show the tree, and use a reduce image
                display = 'block'
                list_state = 'expanded'
                icon = 'minus'

            # If we are the root, we already got this
            if level != 0:
                s += '<a class="pull-right toggle-list" data-state="%s" data-target="bp-%s">' \
                     '<i class="fas fa-%s"></i></a>' % (list_state, self.make_html_id(name), icon)

            s += """<ul class="list-group" name="bp-%s" style="display: %s;">""" % (self.make_html_id(name), display)

            for n in fathers:
                sub_node = n['node']
                sub_s = self.print_business_rules(n, level=level + 1, source_problems=source_problems)
                s += '<li class="list-group-item %s">%s</li>' % (self.get_small_icon_state(sub_node), sub_s)
            s += "</ul>"

        return s

    def get_timeperiod_html(self, tp):
        if not tp.dateranges:
            return ''

        # Build a definition list ...
        content = '''<dl>'''
        for dr in sorted(tp.dateranges, key=operator.methodcaller("get_start_and_end_time")):
            (dr_start, dr_end) = dr.get_start_and_end_time()
            dr_start = time.strftime("%d %b %Y", time.localtime(dr_start))
            dr_end = time.strftime("%d %b %Y", time.localtime(dr_end))
            if dr_start == dr_end:
                content += '''<dd>%s:</dd>''' % (dr_start)
            else:
                content += '''<dd>From: %s, to: %s</dd>''' % (dr_start, dr_end)

            if dr.timeranges:
                content += '''<dt>'''
                idx = 1
                for timerange in dr.timeranges:
                    content += '''&nbsp;%s-%s''' % ("%02d:%02d" % (timerange.hstart, timerange.mstart),
                                                    "%02d:%02d" % (timerange.hend, timerange.mend))
                    idx += 1
                content += '''</dt>'''
        content += '''</dl>'''

        # Build a definition list ...
        if tp.exclude:
            content += '''<dl> Excluded: '''
            for excl in tp.exclude:
                content += self.get_timeperiod_html(excl)
            content += '''</dl>'''

        return content

    def get_contact_avatar(self, contact, size=24, with_name=True, with_link=True):
        if contact == '(Nagios Process)':
            name = "Nagios Process"
            title = name
            s = '<i class="fas fa-server"></i>'
        elif contact == 'Alignak':
            name = "Alignak"
            title = name
            s = '<i class="fas fa-server"></i>'
        else:
            # pylint: disable=undefined-variable
            name = contact
            title = name
            if not isinstance(contact, (unicode, str)):
                # It is a UI contact
                name = contact.get_username()
                title = contact.get_name()

            s = '<img src="/avatar/%s?s=%s" class="img-circle">' % (name, size)

        if with_name:
            s += '&nbsp;'
            s += title

        if with_link and contact not in ['(Nagios Process)', 'Alignak']:
            s = '<a href="/contact/%s">%s</a>' % (name, s)

        s = '<span class="user-avatar" title="%s">%s</span>' % (title, s)

        return s

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

    def render_url(self, obj, items, css=''):
        """Returns formatted HTML for an element URL

        """
        result = []
        for (icon, title, url) in items:
            if not url:
                # Nothing to do here!
                continue

            # Replace MACROS in url, title and description
            if hasattr(obj, 'get_data_for_checks'):
                if url:
                    url = MacroResolver().resolve_simple_macros_in_string(
                        url, obj.get_data_for_checks())
                if title:
                    title = MacroResolver().resolve_simple_macros_in_string(
                        title, obj.get_data_for_checks())

            link = 'href="%s" target="_blank" ' % url
            if not url:
                link = 'href="#" '

            if icon:
                icon = '<i class="fas fa-%s"></i>' % icon
            else:
                icon = ''

            if not title:
                result.append('<a %s>%s&nbsp;%s</a>' % (link, icon, url))
            else:
                result.append('<a %s %s>%s&nbsp;%s</a>' % (link, css, icon, title))

        return result

    def get_element_urls(self, obj, property, title=None, icon=None, css=''):
        """"Return list of element notes urls

        The notes_url or actions_url fields are containing a simple url or a string in which
        individual url are separated with a | character.

        Each url must contain an URI string and may also contain an icon and a title:

        action_url URL1,ICON1,ALT1|URL2,ICON2,ALT2|URL3,ICON3,ALT3

        As documented in Shinken:
        * URLx are the url you want to use
        * ICONx are the images you want to display the link as. It can be either a local
         file, relative to the folder webui/plugins/eltdetail/htdocs/ or an url.
        * ALTx are the alternative texts you want to display when the ICONx file is missing,
         or not set.

        The UI do not use any icon file but the font-awesome icons font. As such, ICONx information
        is the name of an icon in the font awesome icons list.

        The ALTx information is the text label used for the hyperlink or button on the page.

        """
        if not obj or not hasattr(obj, property):
            return []

        # We build a list of: title, icon, description, url
        notes = []

        # Several notes are defined in the notes attribute with | character
        for item in getattr(obj, property).split('|'):
            # An element is: url[,icon][,title] - icon and title are optional
            try:
                (url, icon, title) = item.split(',')
            except ValueError:
                try:
                    (url, icon) = item.split(',')
                except ValueError:
                    url = item

            notes.append((icon, title, url))

        return self.render_url(obj, notes, css=css)

    def get_element_notes(self, obj, title=None, icon=None, css=''):
        """"See the comment of get_element_urls"""
        return self.get_element_urls(obj, 'notes',
                                     title=title, icon=icon, css=css)

    def get_element_notes_url(self, obj, title=None, icon=None, css=''):
        """"See the comment of get_element_urls"""
        return self.get_element_urls(obj, 'notes_url',
                                     title=title, icon=icon, css=css)

    def get_element_actions_url(self, obj, title=None, icon=None, css=''):
        """"See the comment of get_element_urls"""
        return self.get_element_urls(obj, 'action_url',
                                     title=title, icon=icon, css=css)


helper = Helper()
