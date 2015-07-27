#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ai ts=4 sts=4 et sw=4 nu

import traceback

from shinken.log import logger

from submodules.metamodule import MetaModule

class AuthMetaModule(MetaModule):

    _functions = ['check_auth']

    def check_auth(self, user, password):
        ''' Check user/password. If there is submodules, this methods call them
            one by one until one of them returns True. If no submodule can
            check user/password, then we return False.
            If not, the method calls a default check_auth method. '''
        if self.modules:
            for mod in self.modules:
                try:
                    if mod.check_auth(user, password):
                        logger.info("[WebUI] User '%s' is authenticated by %s", user, mod.get_name())
                        return True
                except Exception, exp:
                    print exp.__dict__
                    logger.warning("[WebUI] The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                    logger.debug("[WebUI] Exception type: %s", type(exp))
                    logger.debug("Back trace of this kill: %s" % (traceback.format_exc()))
                    self.app.modules_manager.set_to_restart(mod)
        else:
            return self.check_cfg_password_auth(user, password)

    def is_available(self):
        ''' Always returns True because this MetaModule have a default behavior. '''
        return True

    def check_cfg_password_auth(self, user, password):
        ''' Default behavior. Function imported from auth-cfg-password module. '''

        c = self.app.datamgr.get_contact(user)
        if not c:
            return False
        p = None
        if isinstance(c, dict):
            p = c.get('password', None)
        else:
            p = c.password
        return p == password
