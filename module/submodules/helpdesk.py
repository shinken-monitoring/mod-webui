#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ai ts=4 sts=4 et sw=4 nu

import traceback

from shinken.log import logger

from submodules.metamodule import MetaModule

class HelpdeskMetaModule(MetaModule):

    _functions = ['get_ui_tickets', 'get_ui_helpdesk_configuration']
    _custom_log = "You should configure the module 'glpi-helpdesk' in webui.cfg file to get helpdesk information."

    def get_ui_tickets(self, name):
        ''' Aggregates the `get_ui_tickets` output of all the submodules. '''
        records = []
        for mod in self.modules:
            try:
                records.extend(mod.get_ui_tickets(name))
            except Exception, exp:
                print exp.__dict__
                logger.warning("[WebUI] The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                logger.debug("[WebUI] Exception type: %s", type(exp))
                logger.debug("Back trace of this kill: %s" % (traceback.format_exc()))
                self.app.modules_manager.set_to_restart(mod)
        return records

    def get_ui_helpdesk_configuration(self, all=False):
        ''' If all is True, this methods returns a list of the
            `get_ui_helpdesk_configuration` outputs of all the submodules.
            Else, it returns the output of the first module in the list.
        '''
        configs = []
        for mod in self.modules:
            try:
                configs.append(mod.get_helpdesk_configuration())
            except Exception, exp:
                print exp.__dict__
                logger.warning("[WebUI] The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                logger.debug("[WebUI] Exception type: %s", type(exp))
                logger.debug("Back trace of this kill: %s" % (traceback.format_exc()))
                self.app.modules_manager.set_to_restart(mod)
        if all:
            return configs
        else:
            return configs[0]
