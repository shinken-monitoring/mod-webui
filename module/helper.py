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
import copy
import math
import operator
import re

try:
    import json
except ImportError:
    # For old Python version, load
    # simple json (it can be hard json?! It's 2 functions guy!)
    try:
        import simplejson as json
    except ImportError:
        print "Error: you need the json or simplejson module"
        raise

from shinken.util import safe_print
from shinken.misc.perfdata import PerfDatas
from shinken.misc.sorter import hst_srv_sort
from shinken.log import logger
from perfdata_guess import get_perfometer_table_values
from shinken.macroresolver import MacroResolver


class Helper(object):
    def __init__(self):
        pass

    def gogo(self):
        return 'HELLO'

    def act_inactive(self, b):
        if b:
            return 'Active'
        else:
            return 'Inactive'

    def yes_no(self, b):
        if b:
            return 'Yes'
        else:
            return 'No'

    def print_float(self, f):
        return '%.2f' % f

    def ena_disa(self, b):
        if b:
            return 'Enabled'
        else:
            return 'Disabled'

    # For a unix time return something like
    # Tue Aug 16 13:56:08 2011
    def print_date(self, t, format='%Y-%m-%d %H:%M:%S'):
        if t == 0 or t == None:
            return 'N/A'
            
        if format:
            return time.strftime(format, time.localtime(t))
        else:
            return time.asctime(time.localtime(t))

    # For a time, print something like
    # 10m 37s  (just duration = True)
    # N/A if got bogus number (like 1970 or None)
    # 1h 30m 22s ago (if t < now)
    # Now (if t == now)
    # in 1h 30m 22s
    # Or in 1h 30m (no sec, if we ask only_x_elements=2, 0 means all)
    def print_duration(self, t, just_duration=False, x_elts=0):
        if t == 0 or t == None:
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

        seconds = long(round(seconds))
        minutes, seconds = divmod(seconds, 60)
        hours, minutes = divmod(minutes, 60)
        days, hours = divmod(hours, 24)
        weeks, days = divmod(days, 7)
        months, weeks = divmod(weeks, 4)
        years, months = divmod(months, 12)

        minutes = long(minutes)
        hours = long(hours)
        days = long(days)
        weeks = long(weeks)
        months = long(months)
        years = long(years)

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
        else:
            return ' '.join(duration) + ' ago'


    # Need to create a X level higher and lower to the element
    def create_json_dep_graph(self, elt, levels=3):
        t0 = time.time()
        # First we need ALL elements
        all_elts = self.get_all_linked_elts(elt, levels=levels)

        dicts = []
        for i in all_elts:
            ds = self.get_dep_graph_struct(i)
            for d in ds:
                dicts.append(d)
        j = json.dumps(dicts)
        return j

    def get_all_nodes_from_aggregation_node(self, tree):
        res = [{'path' : tree['path'], 'services': tree['services'], 'state': tree['state'], 'full_path': tree['full_path']}]
        for s in tree['sons']:
            r = self.get_all_nodes_from_aggregation_node(s)
            for n in r:
                res.append(n)
        return res
            
        

    def create_dep_graph_aggregation_node(self, elt):
        # {'path' : '/', 'sons' : [], 'services':[], 'state':'unknown', 'full_path':'/'}
        hname = elt.get_name()
        tree = self.get_host_service_aggregation_tree(elt)
        all_nodes = self.get_all_nodes_from_aggregation_node(tree)

        res = []
        for n in all_nodes:
            d = {'id': self.strip_html_id(hname+n['full_path']), 'name': n['full_path'],
                 'data': {'$type': 'custom',
                          'business_impact': 2,#elt.business_impact,
                          'img_src': '/static/images/icons/state_%s.png' % n['state'],
                          },
                 'adjacencies': []
                 }
            # Set the right info panel
            d['data']['infos'] = ''#r''' %s ''' % self.strip_html_id(n['full_path'])
            d['data']['elt_type'] = 'service'
            d['data']['is_problem'] = False
            d['data']['state_id'] = 1
            d['data']['circle'] = 'none'

            # by default the father linkis the host
            father =  elt.get_dbg_name()
            # But if the aggregation is a level1+ it must be the level-1 one
            agg_parts = [s for s in self.get_aggregation_paths(n['full_path']) if s]

            # Root, no block for it
            if len(agg_parts) == 0:
                continue
            # For 1, it'smeans first agg level, so our father is the host
            # but it's already set. For >1, the father is the agg level before
            if len(agg_parts) > 1:
                pre_path = '/'+'/'.join(agg_parts[:-1])
                father = self.strip_html_id(elt.get_dbg_name()+pre_path)
                

            pd = {'nodeTo': father,
                  'data': {"$type": "line", "$direction": [self.strip_html_id(d['id']), elt.get_dbg_name()]
                           }
                  }
            if n['state'].lower() in ['warning', 'critical']:
                pd['data']["$color"] = 'Tomato'
            else:
                pd['data']["$color"] = 'PaleGreen'
            d['adjacencies'].append(pd)
            
            res.append(d)

        return res
    

    def get_dep_graph_struct(self, elt):
        t = elt.__class__.my_type

        # We set the values for webui/plugins/depgraph/htdocs/js/eltdeps.js
        # so a node with important data for rendering
        # type = custom, business_impact and img_src.
        d = {'id': elt.get_dbg_name(), 'name': elt.get_dbg_name(),
             'data': {'$type': 'custom',
                       'business_impact': elt.business_impact,
                       'img_src': self.get_icon_state(elt),
                       },
             'adjacencies': []
             }
        res = [d]

        # if we got an host, compute the aggregation part
        if t == 'host':
            nodes = self.create_dep_graph_aggregation_node(elt)
            for n in nodes:
                res.append(n)

        
        # Set the right info panel
        d['data']['infos']  = helper.get_fa_icon_state(elt)
        d['data']['infos'] += self.get_link(elt, short=False)
        if elt.business_impact > 2:
            d['data']['infos'] += "(" + self.get_business_impact_text(elt.business_impact) + ")"
        d['data']['infos'] += """ is <span class="font-%s"><strong>%s</strong></span>""" % (elt.state.lower(), elt.state)
        d['data']['infos'] += " since %s" % self.print_duration(elt.last_state_change, just_duration=True, x_elts=2)

        d['data']['elt_type'] = elt.__class__.my_type
        d['data']['is_problem'] = elt.is_problem
        d['data']['state_id'] = elt.state_id

        if elt.state in ['OK', 'UP', 'PENDING']:
            d['data']['circle'] = 'none'
        elif elt.state in ['DOWN', 'CRITICAL']:
            d['data']['circle'] = 'red'
        elif elt.state in ['WARNING', 'UNREACHABLE']:
            d['data']['circle'] = 'orange'
        else:
            d['data']['circle'] = 'none'
        
        
        # Now put in adj our parents
        for p in elt.parent_dependencies:
            # The link service-> host can be squize by aggregations if set
            if t == 'service' and elt.aggregation and p == elt.host:
                agg_name = '/'.join(self.get_aggregation_paths(elt.aggregation))
                agg_id = self.strip_html_id(p.get_dbg_name()+agg_name)
                pd = {'nodeTo': agg_id,
                      'data': {"$type": "line", "$direction": [elt.get_dbg_name(), agg_id]
                               }
                      }
            else: # Ok a basic link with the element and elt so
                pd = {'nodeTo': p.get_dbg_name(),
                      'data': {"$type": "line", "$direction": [elt.get_dbg_name(), p.get_dbg_name()]
                               }
                      }

            # Naive way of looking at impact
            if elt.state_id != 0 and p.state_id != 0:
                pd['data']["$color"] = 'Tomato'
            # If OK, show host->service as a green link
            elif elt.__class__.my_type != p.__class__.my_type:
                pd['data']["$color"] = 'PaleGreen'
            d['adjacencies'].append(pd)

        # The sons case is now useful, it will be done by our sons
        # that will link us
        return res


    # Return all linked elements of this elt, and 2 level
    # higher and lower :)
    def get_all_linked_elts(self, elt, levels=3):
        if levels == 0:
            return set()

        my = set()
        for i in elt.child_dependencies:
            my.add(i)
            child_elts = self.get_all_linked_elts(i, levels=levels - 1)
            for c in child_elts:
                my.add(c)
        for i in elt.parent_dependencies:
            my.add(i)
            par_elts = self.get_all_linked_elts(i, levels=levels - 1)
            for c in par_elts:
                my.add(c)

        #safe_print("get_all_linked_elts::Give elements", my)
        return my


    def get_synthesis(self, elts):
        h = dict()
        hosts = [i for i in elts if i.__class__.my_type == 'host']
        h['elts'] = hosts
        h['nb_elts'] = len(hosts)
        if hosts:
            h['bi'] = max(h.business_impact for h in hosts)
        else:
            h['bi'] = 0
        for state in 'up', 'down', 'unreachable', 'pending':
            h[state] = [i for i in hosts if i.state == state.upper()]
        h['unknown'] = list(set(h['elts']) - set(h['up']) - set(h['down']) - set(h['unreachable']) - set(h['pending']))
        h['ack'] = [i for i in hosts if i.problem_has_been_acknowledged]
        h['downtime'] = [i for i in hosts if i.in_scheduled_downtime]
        for state in 'up', 'down', 'unreachable', 'pending', 'unknown', 'ack', 'downtime':
            h['nb_' + state] = len(h[state])
            if hosts:
                h['pct_' + state] = round(100.0 * h['nb_' + state] / h['nb_elts'], 2)
            else:
                h['pct_' + state] = 0

        s = dict()
        services = [i for i in elts if i.__class__.my_type == 'service']
        s['elts'] = services
        s['nb_elts'] = len(services)
        if services:
            s['bi'] = max(s.business_impact for s in services)
        else:
            s['bi'] = 0
        for state in 'ok', 'critical', 'warning', 'pending', 'unknown':
            s[state] = [i for i in services if i.state == state.upper()]
        s['ack'] = [i for i in services if i.problem_has_been_acknowledged]
        s['downtime'] = [i for i in services if i.in_scheduled_downtime]
        for state in 'ok', 'critical', 'warning', 'unknown', 'pending', 'ack', 'downtime':
            s['nb_' + state] = len(s[state])
            if services:
                s['pct_' + state] = round(100.0 * s['nb_' + state] / s['nb_elts'], 2)
            else:
                s['pct_' + state] = 0

        return {'hosts': h, 'services': s}


    # Return a button with text, image, id and class (if need)
###
###
## To be removed ... html code will be more clean !
###
###
    def get_button(self, text, img=None, id=None, cls=None):
        #s = '<div class="buttons">\n'
        s = '<div class="btn">\n'
        if cls and not id:
            s += '<div class="%s">\n' % cls
        elif id and not cls:
            s += '<div id="%s">\n' % id
        elif id and cls:
            s += '<div class="%s" id="%s">\n' % (cls, id)
        else:
            s += '<div>\n'
        if img:
            s += '<img src="%s" alt=""/>\n' % img
        s += "%s" % text
        s += ''' </div>
            </div>\n'''

        return s

    # For and host, return the services sorted by business
    # impact, then state, then desc
    def get_host_services_sorted(self, host):
        t = copy.copy(host.services)
        t.sort(hst_srv_sort)
        return t


    # Mockup helper
    # User: Frescha
    # Date: 08.01.2012
    def print_business_tree(self, tree, level=0):
        #safe_print("Should print tree", tree)
        node = tree['node']
        name = node.get_full_name()
        fathers = tree['fathers']
        fathers = sorted(fathers, key=lambda dict: dict['node'].get_full_name())
        s = ''
        # Do not print the node if it's the root one, we already know its state!
        if level != 0:
            s += "%s is %s since %s\n" % (self.get_link(node), node.state, self.print_duration(node.last_state_change, just_duration=True))

        # If we got no parents, no need to print the expand icon
        if len(fathers) > 0:
            # We look if the below tree is goodor not
            tree_is_good = (node.state_id == 0)

            # If the tree is good, we will use an expand image
            # and hide the tree
            if tree_is_good:
                display = 'none'
                img = 'expand.png'
            else:  # we will already show the tree, and use a reduce image
                display = 'block'
                img = 'reduce.png'

            # If we are the root, we already got this
            if level != 0:
                s += """<a id="togglelink-%s" href="javascript:toggleBusinessElt('%s')"><img id="business-parents-img-%s" src="/static/images/%s" alt="toggle"> </a> \n""" % (name, name, name, img)

            s += """<ul id="business-parents-%s" class="treeview" style="display: %s; ">""" % (name, display)

            for n in fathers:
                sub_node = n['node']
                sub_s = self.print_business_rules(n, level=level+1)
                s += '<li class="%s">%s</li>' % (self.get_small_icon_state(sub_node), sub_s)
            s += "</ul>"
        #safe_print("Returning s:", s)
        return s

    # Get the small state for host/service icons
    # and satellites ones
    def get_small_icon_state(self, obj):
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

    # Give a business impact as text and stars if need
    # If text=True, returns text+stars, else returns stars only ...
    def get_business_impact_text(self, business_impact, text=False):
        txts = {0: 'None', 1: 'Low', 2: 'Normal',
                3: 'Important', 4: 'Very important', 5: 'Business critical'}
        nb_stars = max(0, business_impact - 2)
        stars = '<i class="fa fa-star text-primary"></i>' * nb_stars

        if text:
            res = "%s %s" % (txts.get(business_impact, 'Unknown'), stars)
        else:
            res = stars
        return res

    # Give an enabled/disabled state based on glyphicons with optional title and message
    def get_on_off(self, status=False, title=None, message=''):
        if not title:
            if status:
                title = 'Enabled'
            else:
                title = 'Disabled'

        if status:
            return '''<i title="%s" class="glyphicon glyphicon-ok font-green">%s</i>''' % (title, message)
        else:
            return '''<i title="%s" class="glyphicon glyphicon-remove font-red">%s</i>''' % (title, message)

    # Return the impacts as a business sorted list
    def get_impacts_sorted(self, obj):
        t = copy.copy(obj.impacts)
        t.sort(hst_srv_sort)
        return t

    def get_link(self, obj, short=False):
        if obj.__class__.my_type == 'service':
            if short:
                name = obj.get_name()
            else:
                name = obj.get_full_name()

            return '<a href="/service/%s"> %s </a>' % (obj.get_full_name(), name)

        # if not service, host
        return '<a href="/host/%s"> %s </a>' % (obj.get_full_name(), obj.get_full_name())


    # Give only the /service/blabla or /host blabla string, like for buttons inclusion
    def get_link_dest(self, obj):
        return "/%s/%s" % (obj.__class__.my_type, obj.get_full_name())

    # For an host, give it's own link, for a services, give the link of its host
    def get_host_link(self, obj):
        if obj.__class__.my_type == 'service':
            return self.get_link(obj.host)
        return self.get_link(obj)

    # For an object, return the path of the icons
    def get_icon_state(self, obj):
        ico = self.get_small_icon_state(obj)
        if getattr(obj, 'icon_set', '') != '':
            return '/static/images/sets/%s/state_%s.png' % (obj.icon_set, ico)
        else:
            return '/static/images/icons/state_%s.png' % ico

    def get_urls(self, obj, url, default_title="Url", default_icon="globe", popover=False):
        '''
        Returns formatted HTML for an element URL
        
        url string may contain a list of urls separated by |
        
        Each url may be formatted as:
            - url,,description
            - title::description,,url
            - title,,icon::description,,url
            
        description is optional
            
        If title is not specified, default_title is used as title
        If icon is not specified, default_icon is used as icon
        
        If popover is true, a bootstrap popover is built, else a standard link ...
        '''
        logger.debug("[WebUI] get_urls: %s / %s / %s / %d", url, default_title, default_icon, popover)
        
        result = []
        for item in url.split('|'):
            try:
                (title, url) = item.split('::')
            except:
                title = "%s,,%s" %(default_title, default_icon)
                url = item
            
            try:
                (title, icon) = title.split(',,')
            except:
                icon = default_icon
            
            
            try:
                (description, real_url) = url.split(',,')
            except:
                description = 'No description provided'
                real_url = url
            
            # Replace MACROS in url and description
            if hasattr(obj, 'get_data_for_checks'):
                url = MacroResolver().resolve_simple_macros_in_string(real_url, obj.get_data_for_checks())
                description = MacroResolver().resolve_simple_macros_in_string(description, obj.get_data_for_checks())
            
            logger.debug("[WebUI] get_urls, found: %s / %s / %s / %s", title, icon, url, description)
            
            if popover:
                if url != '':
                    result.append('''<a href="%s" target="_blank" role="button" data-toggle="popover medium" data-html="true" data-content="%s" data-trigger="hover focus" data-placement="bottom"><i class="fa fa-%s"></i>&nbsp;%s</a>''' % (url, description, icon, title))
                else:
                    result.append('''<span data-toggle="popover medium" data-html="true" data-content="%s" data-trigger="hover focus" data-placement="bottom"><i class="fa fa-%s"></i>&nbsp;%s</span>''' % (description, icon, title))
            else:
                if url != '':
                    result.append('''<a href="%s" target="_blank" title="%s"><i class="fa fa-%s"></i>&nbsp;%s</a>''' % (url, description, icon, title))
                else:
                    result.append('''<span title="%s"><i class="fa fa-%s"></i>&nbsp;%s</span>''' % (description, icon, title))

        return result
                    
    def get_element_actions_url(self, obj, default_title="Url", default_icon="globe", popover=False):
        '''
        Return list of element action urls
        '''
        
        if obj is not None:
            return self.get_urls(obj, obj.action_url, default_title=default_title, default_icon=default_icon, popover=popover)

        return None

    def get_element_notes_url(self, obj, default_title="Url", default_icon="globe", popover=False):
        '''
        Return list of element notes urls
        '''
        
        if obj is not None and obj.notes:
            notes = []
            i=0
            for item in obj.notes.split('|'):
                if not obj.notes_url:
                    notes.append("%s,," % (item))
                else:
                    notes_url = obj.notes_url.split('|')
                    if len(notes_url) > i:
                        notes.append("%s,,%s" % (item, notes_url[i]))
                    else:
                        notes.append("%s,," % (item))
                i=i+1
                logger.debug("[WebUI] get_element_notes_url, note: %s", notes)
                
            return self.get_urls(obj, '|'.join(notes), default_title=default_title, default_icon=default_icon, popover=popover)

        return []

    def get_fa_icon_state(self, obj=None, cls='host', state='UP', disabled=False, label='', useTitle=True):
        '''
            Get an Html formatted string to display host/service state
            
            If obj is specified, obj class and state are used.
            If obj is None, cls and state parameters are used.
            
            If disabled is True, the font used is greyed
            
            If label is empty, only an icon is returned
            If label is set as 'state', the icon title is used as text
            Else, the content of label is used as text near the icon.
            
            If useTitle is False, do not include title attribute.
            
            Returns a span element containing a Font Awesome icon that depicts 
           consistently the host/service current state (see issue #147)
        '''
        state = obj.state.upper() if obj is not None else state.upper()
        flapping = (obj and obj.is_flapping) or state=='FLAPPING'
        ack = (obj and obj.problem_has_been_acknowledged) or state=='ACK'
        downtime = (obj and obj.in_scheduled_downtime) or state=='DOWNTIME'
        
        # Icons depending upon element and real state ...
        icons = { 'host': 
                    {   'UP': 'server',
                        'DOWN': 'server',
                        'UNREACHABLE': 'server',
                        'ACK': 'check', 
                        'DOWNTIME': 'ambulance',
                        'FLAPPING': 'spinner fa-spin',
                        'PENDING': 'server',
                        'UNKNOWN': 'server' },
                  'service': 
                    {   'OK': 'arrow-up',
                        'CRITICAL': 'arrow-down',
                        'WARNING': 'exclamation',
                        'ACK': 'check', 
                        'DOWNTIME': 'ambulance',
                        'FLAPPING': 'spinner fa-spin',
                        'PENDING': 'spinner fa-circle-o-notch',
                        'UNKNOWN': 'question' }
                }

        cls = obj.__class__.my_type if obj is not None else cls

        back = '''<i class="fa fa-%s fa-stack-2x font-%s"></i>''' % (icons[cls]['FLAPPING'] if flapping else 'circle', state.lower() if not disabled else 'greyed')
        title = "%s is %s" % (cls, state)
        if flapping:
            icon_color = 'font-' + state.lower() if not disabled else 'font-greyed'
            title += " and is flapping"
        else:
            icon_color = 'fa-inverse'
        if downtime:
            icon = icons[cls]['DOWNTIME']
            title += " and in scheduled downtime"
            icon_style = 'style="opacity: 0.5"'
        elif ack:
            icon = icons[cls]['ACK']
            title += " and acknowledged"
            icon_style = 'style="opacity: 0.5"'
        else:
            icon = icons[cls].get(state, 'UNKNOWN')
            icon_style = ""
        front = '''<i class="fa fa-%s fa-stack-1x %s"></i>''' % (icon, icon_color)
        
        if useTitle:
            icon_text = '''<span class="fa-stack" %s title="%s">%s%s</span>''' % (icon_style, title, back, front)
        else:
            icon_text = '''<span class="fa-stack" %s">%s%s</span>''' % (icon_style, back, front)

        if label=='':
            return icon_text
        else:
            color = state.lower() if not disabled else 'greyed'
            if label=='title':
                label=title
            return '''
              <span class="font-%s">
                 %s
                 <span class="num">%s</span>
              </span> 
              ''' % (color,
                     icon_text,
                     label)
        

    def get_fa_icon_state_and_label(self, obj=None, cls='host', state='UP', label="", disabled=False, useTitle=True):
        color = state.lower() if not disabled else 'greyed'
        return '''
          <span class="font-%s">
             %s
             <span class="num">%s</span>
          </span> 
          ''' % (color,
                 self.get_fa_icon_state(obj=obj, cls=cls, state=state, disabled=disabled, useTitle=useTitle),
                 label)


    # :TODO:maethor:150609: Rewrite this function
    # Get
    def get_navi(self, total, pos, step=30):
        step = float(step)
        nb_pages = math.ceil(total / step) if step <> 0 else 0
        current_page = int(pos / step) if step <> 0 else 0

        step = int(step)

        res = []

        nb_max_items = 2
        
        if current_page >= nb_max_items:
            # Name, start, end, is_current
            res.append((u'«', 0, step, False))
            res.append(('...', None, None, False))

        #print "Range,", current_page - 1, current_page + 1
        for i in xrange(current_page - (nb_max_items / 2), current_page + 1 + (nb_max_items / 2)):
            if i < 0:
                continue
            #print "Doing PAGE", i
            is_current = (i == current_page)
            start = int(i * step)
            # Maybe we are generating a page too high, bail out
            if start > total:
                continue

            end = int((i+1) * step)
            res.append(('%d' % (i+1), start, end, is_current))

        if current_page < nb_pages - nb_max_items:
            start = int((nb_pages - (nb_max_items - 1)) * step)
            end = int(total)
            # end = int(nb_pages * step)
            res.append(('...', None, None, False))
            res.append((u'»', start, end, False))

        return res

    # Get a perfometer part for html printing
    def get_perfometer(self, elt, metric=None):
        if elt.perf_data:
            r = get_perfometer_table_values(elt, metric=metric)
            if r is None:
                return ''

            #lnk = r['lnk']
            metrics = r['metrics']
            title = r['title']
            s = ''
            if r['lnk'] != '#':
                s += '<a href="%s">' % lnk
            if metrics:
                # metrics[0][0] is the color associated to the current state
                # metrics[0][1] is a percentage:
                #   - real percentage between min and max (if defined)
                #   - else 100
                logger.debug("[WebUI] get_perfometer: %s, %s / %s", elt.get_name(), metrics[0][0], metrics[0][1])
                s += '''<div class="progress" style="min-width:100px;">
                            <div title="%s" class="ellipsis progress-bar progress-bar-%s" role="progressbar" aria-valuenow="%s" aria-valuemin="0" aria-valuemax="100" style="min-width: 50px; width:%s%%"> 
                            %s
                            </div>
                        </div>''' % (title, metrics[0][0], metrics[0][1], metrics[0][1], title)
            if r['lnk'] != '#':
                s += '</a>'
                
            return s
            
        return ''

    # TODO: Will look at the string s, and return a clean output without
    # danger for the browser
    def strip_html_output(self, s):
        return s

    # We want the html id of an host or a service. It's basically
    # the full_name with / changed as -- (because in html, / is not valid :) )
    def get_html_id(self, elt):
        return self.strip_html_id(elt.get_full_name())

    def strip_html_id(self, s):
        return s.replace('/', '--').replace(' ', '_').replace('.', '_').replace(':', '_')

    # Make an HTML element identifier
    def make_html_id(self, s):
        return re.sub('[^A-Za-z0-9]', '', s)

    # URI with spaces are BAD, must change them with %20
    def get_uri_name(self, elt):
        return elt.get_full_name().replace(' ', '%20')

    def get_aggregation_paths(self, p):
        p = p.strip()
        if p and not p.startswith('/'):
            p = '/'+p
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
        order = ['critical', 'warning', 'unknown', 'ok', 'pending']
        for o in order:
            if o in states:
                tree['state'] = o
                return
                
        # Should be never call or we got a major problem...
        tree['state'] = 'unknown'
        
    def assume_and_get_path_in_tree(self, tree, paths):
        #print "Tree on start of", paths, tree
        current_full_path = ''
        for p in paths:
            # Don't care about void path, like for root
            if not p:
                continue
            current_full_path += '/'+p
            found = False
            for s in tree['sons']:
                # Maybe we find the good son, if so go on this level
                if p == s['path']:
                    tree = s
                    found = True
                    break
            # Did we find our son? If no, create it and jump into it
            if not found:
                s = {'path' : p, 'sons' : [], 'services':[], 'state':'unknown', 'full_path':current_full_path}
                tree['sons'].append(s)
                tree = s
        return tree

    def get_host_service_aggregation_tree(self, h, app=None):
        tree = {'path' : '/', 'sons' : [], 'services':[], 'state':'unknown', 'full_path':'/'}
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
            # If our state is OK, hide our sons
            if state == 'ok' and (not expanded or len(sons) >= max_sons):
                display = 'none'
                img = 'expand.png'
                icon = 'plus'
                list_state = 'collapsed'

            s += """<a class="toggle-list" data-state="%s" data-target="ag-%s"> <span class="alert-small alert-%s"> <i class="fa fa-%s"></i> %s&nbsp;</span> </a>""" % (list_state, _id, state, icon, path)

        s += """<ul name="ag-%s" class="list-group" style="display: %s;">""" % (_id, display)
        # If we got no parents, no need to print the expand icon
        if len(sons) > 0:
            for son in sons:
                sub_s = self.print_aggregation_tree(son, html_id, expanded=expanded)
                s += '<li class="list-group-item">%s</li>' % sub_s


        s += '<li class="list-group-item">'
        if path == '/' and len(services) > 0:
            s += """<span class="alert-small"> Others </span>"""
            
        if len(services):
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
 
    def print_business_rules(self, tree, level=0, source_problems=[]):
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
            s += """ since <span title="%s">%s""" % (time.strftime("%d %b %Y %H:%M:%S", time.localtime(node.last_state_change)), self.print_duration(node.last_state_change, just_duration=True, x_elts=2))
            
        # If we got no parents, no need to print the expand icon
        if len(fathers) > 0:
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
                s += '''<a class="pull-right toggle-list" data-state="%s" data-target="bp-%s"> <i class="fa fa-%s"></i> </a>''' % (list_state, self.make_html_id(name), icon)

            s += """<ul class="list-group" name="bp-%s" style="display: %s;">""" % (self.make_html_id(name), display)

            for n in fathers:
                sub_node = n['node']
                sub_s = self.print_business_rules(n, level=level+1, source_problems=source_problems)
                s += '<li class="list-group-item %s">%s</li>' % (self.get_small_icon_state(sub_node), sub_s)
            s += "</ul>"

        return s
   
    def get_timeperiod_html(self, tp):
        if len(tp.dateranges) == 0:
            return ''
            
        # Build a definition list ...
        content = '''<dl>'''
        for dr in sorted(tp.dateranges, key=operator.methodcaller("get_start_and_end_time")):
            (dr_start, dr_end) = dr.get_start_and_end_time()
            dr_start = time.strftime("%d %b %Y", time.localtime(dr_start))
            dr_end = time.strftime("%d %b %Y", time.localtime(dr_end))
            if dr_start==dr_end:
                content += '''<dd>%s:</dd>''' % (dr_start)
            else:
                content += '''<dd>From: %s, to: %s</dd>''' % (dr_start, dr_end)
                
            if len(dr.timeranges) > 0:
                content += '''<dt>'''
                idx=1
                for timerange in dr.timeranges:
                    content += '''&nbsp;%s-%s''' % ("%02d:%02d" % (timerange.hstart, timerange.mstart), "%02d:%02d" % (timerange.hend, timerange.mend))
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

    def state_to_class(self, state):
        '''Convert a Shinken state to a bootstrap3 class'''
        classes = {"OK": 'success', "UP": 'success',
                  "DOWN": 'danger', "CRITICAL": 'danger',
                  "WARNING": 'warning',
                  "UNKNOWN": 'info'}
        if state in classes:
            return classes[state]
        else:
            return 'default'
helper = Helper()
