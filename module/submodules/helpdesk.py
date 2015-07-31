#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ai ts=4 sts=4 et sw=4 nu

import traceback

from shinken.log import logger

from .metamodule import MetaModule

class HelpdeskMetaModule(MetaModule):

    # Only those functions are enough for an helpdesk module ...
    _functions = ['get_ui_session',
                  'get_ui_tickets', 
                  'get_ui_helpdesk_configuration']
    _custom_log = "You should configure the module 'glpi-helpdesk' in webui.cfg file to get helpdesk information."

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

    def get_ui_session(self, default=None):
        if self.is_available():
            return self.module.get_ui_session() or default
        return default
        
    def get_ui_tickets(self, name, default=None):
        if self.is_available():
            return self.module.get_ui_tickets(name) or default
        return default

    def get_ui_helpdesk_configuration(self, default=None):
        if self.is_available():
            return self.module.get_ui_helpdesk_configuration() or default
        return default

    def get_ui_types(self, default=None):
        if self.is_available():
            return self.module.get_ui_types() or default
        return default
        
    def get_ui_categories(self, default=None):
        if self.is_available():
            return self.module.get_ui_categories() or default
        return default
        
    def get_ui_templates(self, default=None):
        if self.is_available():
            return self.module.get_ui_templates() or default
        return default
