#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ai ts=4 sts=4 et sw=4 nu

import traceback

from shinken.log import logger

from .metamodule import MetaModule

class HelpdeskMetaModule(MetaModule):

    # Only those functions are enough for an helpdesk module ...
    _functions = ['get_ui_helpdesk_configuration']
    _custom_log = "You should configure the module 'glpi-helpdesk' in webui2.cfg file to get helpdesk information."

    def __init__(self, modules, app):
        ''' Because it wouldn't make sense to use many submodules in this
            MetaModule, we only use the first one in the list of modules.
        '''
        self.app = app
        self.module = None
        if modules:
            if len(modules) > 1:
                logger.warning('[WebUI] Too much helpdesk modules declared (%s > 1). Using %s.' % (len(modules), modules[0]))
            self.module = modules[0]

    def is_available(self):
        return self.module is not None

    def get_external_ui_link(self, ticket_page=False, default=None):
        if self.is_available():
            return self.module.get_external_ui_link(ticket_page) or default
        return default

    def get_ui_session(self, default=None):
        if self.is_available():
            return self.module.get_ui_session() or default
        return default

    def get_ui_ticket(self, id, default=None):
        if self.is_available():
            return self.module.get_ui_ticket(id) or default
        return default

    def get_ui_tickets(self, name=None, status=None, count=50, list_only=True, session=None, default=None):
        if self.is_available():
            return self.module.get_ui_tickets(name, status, count, list_only, session) or default
        return default

    def get_ui_helpdesk_configuration(self, default=None):
        if self.is_available():
            return self.module.get_ui_helpdesk_configuration() or default
        return default

    def get_ui_types(self, default=None):
        if self.is_available():
            hd_configuration = self.module.get_ui_helpdesk_configuration()
            if 'types' in hd_configuration:
                return hd_configuration['types'] or default
        return default

    def get_ui_categories(self, default=None):
        if self.is_available():
            hd_configuration = self.module.get_ui_helpdesk_configuration()
            if 'categories' in hd_configuration:
                return hd_configuration['categories'] or default
        return default

    def get_ui_templates(self, default=None):
        if self.is_available():
            hd_configuration = self.module.get_ui_helpdesk_configuration()
            if 'templates' in hd_configuration:
                return hd_configuration['templates'] or default
        return default

    def set_ui_ticket(self, parameters, default=None):
        """
        Request to create a new ticket
        """
        if self.is_available():
            return self.module.set_ui_ticket(parameters) or default
        return default

    def set_ui_ticket_followup(self, parameters, default=None):
        """
        Request to create a new follow-up for a ticket
        """
        if self.is_available():
            return self.module.set_ui_ticket_followup(parameters) or default
        return default
