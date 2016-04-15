#!/usr/bin/python
#!/usr/bin/python

# -*- coding: utf-8 -*-

# Copyright (C) 2009-2014:
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

import json
import time
import traceback

from shinken.log import logger

### Will be populated by the UI with it's own value
app = None

def create_ticket(name):
    """
    Create a new ticket
    """
    if not app.helpdesk_module.is_available():
        app.redirect404()

    logger.info("[WebUI-helpdesk] request to create a ticket for %s", name)

    result = { 'status': 405, 'message': "Ticket creation failed", 'ticket': None}

    app.response.content_type = 'application/json'
    callback = app.request.query.get('callback', None)
    response_text = app.request.query.get('response_text', 'Ticket creation succeeded')

    parameters = {}
    parameters['name']          = app.request.query.get('name', name)
    parameters['itemtype']      = app.request.query.get('itemtype', 'Computer')
    parameters['item']          = app.request.query.get('item', '')
    parameters['entity']        = app.request.query.get('entity', '')

    parameters['type']          = app.request.query.get('ticket_type', '')
    parameters['category']      = app.request.query.get('ticket_category', '')
    parameters['title']         = app.request.query.get('ticket_title', '')
    parameters['content']       = app.request.query.get('ticket_content', '')
    logger.info("[WebUI-helpdesk] request to create a ticket with %s", parameters)

    try:
        # Request for ticket creation
        response = app.helpdesk_module.set_ui_ticket(parameters)
        logger.info("[WebUI-helpdesk] ticket creation result: %s", response)
        # ticket = None
        # if app.create_ticket:
            # ticket = app.create_ticket(parameters)
        if response:
            result = { 'status': 200, 'message': response_text, 'ticket': response}

        if callback:
            return '''%s(%s)''' % (callback, json.dumps(response['id']))
        else:
            return json.dumps(result)
    except Exception as e:
        logger.info("[WebUI-helpdesk] ticket creation failed, exception: %s", traceback.format_exc())
        return json.dumps(result)

def create_ticket_followup(name):
    """
    Add a follow-up to an existing ticket
    """
    if not app.helpdesk_module.is_available():
        app.redirect404()

    ticket = int(app.request.query.get('ticket', '0'))
    logger.info("[WebUI-helpdesk] request to create a ticket follow-up for %s, ticket #%d", ticket)

    result = { 'status': 405, 'message': "Ticket creation failed", 'ticket': ticket}
    if ticket <= 0:
        logger.info("[WebUI-helpdesk] ticket follow-up creation failed, no ticket ID!")
        return json.dumps(result)

    app.response.content_type = 'application/json'
    callback = app.request.query.get('callback', None)
    response_text = app.request.query.get('response_text', 'Ticket follow-up creation succeeded')

    parameters = {}
    parameters['ticket']        = ticket
    parameters['status']        = app.request.query.get('status', '1')
    parameters['content']       = app.request.query.get('content', 'No data ...')
    logger.info("[WebUI-helpdesk] request to create a ticket follow-up with %s", parameters)

    try:
        # Request for ticket creation
        response = app.helpdesk_module.set_ui_ticket_followup(parameters)
        logger.info("[WebUI-helpdesk] ticket follow-up creation result: %s", response)
        if response:
            result = { 'status': 200, 'message': response_text, 'ticket': response}

        if callback:
            return '''%s(%s)''' % (callback, json.dumps(result['id']))
        else:
            return json.dumps(result)
    except Exception as e:
        logger.info("[WebUI-helpdesk] ticket follow-up creation failed, exception: %s", traceback.format_exc())
        return json.dumps(result)

def add_ticket(name):
    """
    Display ticket add popup
    """
    if not app.helpdesk_module.is_available():
        app.redirect404()

    user = app.request.environ['USER']
    elt = app.datamgr.get_element(name, user) or app.redirect404()
    logger.info("[WebUI-helpdesk] adding a ticket for %s from %s", name, user)

    try:
        itemtype = elt.customs['_ITEMTYPE']
        items_id = elt.customs['_ITEMSID']
        entities_id = elt.customs['_ENTITIESID']

        # helpdesk_configuration = app.helpdesk_module.get_ui_helpdesk_configuration()
        session = app.helpdesk_module.get_ui_session()
        logger.info("[WebUI-helpdesk] session: %s", session)
        types = app.helpdesk_module.get_ui_types()
        logger.info("[WebUI-helpdesk] types: %s", types)
        categories = app.helpdesk_module.get_ui_categories()
        logger.info("[WebUI-helpdesk] categories: %s", categories)
        templates = app.helpdesk_module.get_ui_templates()
        logger.info("[WebUI-helpdesk] templates: %s", templates)

        return {'elt': elt, 'name': name, 'itemtype': itemtype, 'items_id': items_id, 'entities_id': entities_id, 'types': types, 'categories': categories, 'templates': templates}
    except Exception as e:
        logger.info("[WebUI-helpdesk] ticket creation is not possible for %s, exception: %s", name, traceback.format_exc())
        return {'name': None}

def add_ticket_followup(name):
    """
    Display ticket follow-up add popup
    """
    if not app.helpdesk_module.is_available():
        app.redirect404()

    ticket = int(app.request.query.get('ticket', '0'))
    status = int(app.request.query.get('status', '0'))

    result = { 'status': 405, 'message': "Ticket creation failed", 'ticket': ticket}
    if ticket <= 0:
        logger.info("[WebUI-helpdesk] ticket follow-up creation failed, no ticket ID!")
        return {'name': None, 'ticket': 0}


    user = app.request.environ['USER']
    elt = app.datamgr.get_element(name, user) or app.redirect404()
    logger.info("[WebUI-helpdesk] adding a ticket follow-up to #%d for %s from %s", ticket, name, user)

    try:
        # helpdesk_configuration = app.helpdesk_module.get_ui_helpdesk_configuration()
        session = app.helpdesk_module.get_ui_session()
        logger.info("[WebUI-helpdesk] session: %s", session)

        return {'elt': elt, 'name': name, 'ticket': ticket, 'status': status}
    except Exception as e:
        logger.info("[WebUI-helpdesk] ticket creation is not possible for %s, exception: %s", name, traceback.format_exc())
        return {'name': None}

def get_ticket(id):
    if not app.helpdesk_module.is_available():
        app.redirect404()

    user = app.request.environ['USER']
    elt = app.datamgr.get_element(name, user) or app.redirect404()
    logger.info("[WebUI-helpdesk] requesting tickets for %s", name)

    tickets = app.helpdesk_module.get_ui_tickets(name)
    return {'elt': elt, 'name': name, 'app': app, 'tickets': tickets}

def get_element_tickets(name):
    if not app.helpdesk_module.is_available():
        app.redirect404()

    user = app.request.environ['USER']
    elt = app.datamgr.get_element(name, user) or app.redirect404()
    logger.info("[WebUI-helpdesk] requesting tickets for %s", name)

    tickets = app.helpdesk_module.get_ui_tickets(name, list_only=False)
    return {
        'app': app,
        'elt': elt,
        'name': name,
        'tickets': tickets,
        'ticket_page_uri': app.helpdesk_module.get_external_ui_link(ticket_page=True)
    }

def get_widget_tickets():
    """
    Create a new ticket
    """
    if not app.helpdesk_module.is_available():
        return """
            <center>
                <h3>No Helpdesk module is installed.</h3>
            </center>
        """

    user = app.request.environ['USER']
    user.is_administrator() or app.redirect403()

    wid = app.request.query.get('wid', 'widget_helpdesk_' + str(int(time.time())))
    collapsed = (app.request.query.get('collapsed', 'False') == 'True')

    # We want to limit the number of elements, The user will be able to increase it
    nb_elements = max(0, int(app.request.query.get('nb_elements', '10')))

    # Apply search filter if exists ...
    search = app.request.query.get('search', 'all')
    tickets_status = {
        'all': 'All',
        'old': 'Old',
        'notold': 'Not Old',
        'notclosed': 'Not closed',
        'process': 'Processing',
        '1': 'New',
        '2': 'Assigned',
        '3': 'Planned',
        '4': 'Waiting',
        '5': 'Solved',
        '6': 'Closed',
        '7': 'Accepted',
        '8': 'Observed',
        '9': 'Evaluation',
        '10': 'Approval',
        '11': 'Test',
        '12': 'Qualification'
    }

    logger.info("[WebUI-helpdesk] requesting tickets with status %s", search)

    # Get tickets
    tickets = app.helpdesk_module.get_ui_tickets(status=search, count=nb_elements, list_only=True, session=user.get_session())

    options = {
        'search': {
            'value': search,
            'type': 'select',
            'values': tickets_status,
            'label': 'Filter by status'
        },
        'nb_elements': {
            'value': nb_elements,
            'type': 'int',
            'label': 'Max number of tickets to show'
        },
    }

    title = 'Helpdesk tickets'
    if search and search in tickets_status:
        title = 'Helpdesk tickets (%s)' % tickets_status[search]

    return {
        'wid': wid,
        'collapsed': collapsed,
        'options': options,
        'base_url': '/widget/helpdesk', 'title': title,
        'app': app,
        'elt': None,
        'tickets': tickets,
        'ticket_page_uri': app.helpdesk_module.get_external_ui_link(ticket_page=True)
    }

widget_desc = '''
<h4>Helpdesk</h4>
Show a list of selected helpdesk tickets.
'''

pages = {
    create_ticket:{
        'name': 'TicketCreate',
        'route': '/helpdesk/ticket/create/:name'
    },
    create_ticket_followup:{
        'name': 'TicketFollowUpCreate',
        'route': '/helpdesk/ticket_followup/create/:name'
    },
    add_ticket:{
        'name': 'TicketAdd',
        'route': '/helpdesk/ticket/add/:name',
        'view': 'add_ticket'
    },
    add_ticket_followup:{
        'name': 'TicketFollowUpAdd',
        'route': '/helpdesk/ticket_followup/add/:name',
        'view': 'add_ticket_followup'
    },
    get_element_tickets:{
        'name': 'TicketList',
        'route': '/helpdesk/tickets/:name',
        'view': 'helpdesk'
    },
    get_widget_tickets: {
        'name': 'wid_Helpdesk',
        'route': '/widget/helpdesk',
        'view': 'helpdesk_widget',
        'static': True,
        'widget': ['dashboard'],
        'widget_desc': widget_desc,
        'widget_name': 'helpdesk',
        'widget_picture': '/static/helpdesk/img/widget_helpdesk.png'
    }
}
