#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ai ts=4 sts=4 et sw=4 nu

import traceback

from shinken.log import logger

from submodules.metamodule import MetaModule

class LogsMetaModule(MetaModule):

    _functions = ['get_ui_logs', 'get_ui_availability']
    _custom_log = "You should configure the module 'mongo-logs' in your broker and the module 'ui-mongo-logs' in webui.cfg file to be able to display logs and availability."


    def get_ui_logs(self, name, logs_type=None):
        ''' Aggregate the get_ui_logs output of all the submodules. '''
        records = []
        if self.modules:
            for mod in self.modules:
                try:
                    records.extend(mod.get_ui_logs(name, logs_type))
                except Exception, exp:
                    print exp.__dict__
                    logger.warning("[WebUI] The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                    logger.debug("[WebUI] Exception type: %s", type(exp))
                    logger.debug("Back trace of this kill: %s" % (traceback.format_exc()))
                    self.app.modules_manager.set_to_restart(mod)
        return records

    def get_ui_availability(self, name, range_start=None, range_end=None):
        ''' Aggregate the get_ui_availability output of all the submodules. '''
        records = []
        if self.modules:
            for mod in self.modules:
                try:
                    records.extend(mod.get_ui_availability(name, range_start, range_end))
                except Exception, exp:
                    print exp.__dict__
                    logger.warning("[WebUI] The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                    logger.debug("[WebUI] Exception type: %s", type(exp))
                    logger.debug("Back trace of this kill: %s" % (traceback.format_exc()))
                    self.app.modules_manager.set_to_restart(mod)
        return records
