#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ai ts=4 sts=4 et sw=4 nu

from shinken.log import logger

class MetaModule(object):

    """ Base class for "MetaModules".
    
        A MetaModule is a list of Webui modules that manage the same task.
        For instance, AuthMetaModule would be a list of auth modules.
        
        A MetaModule can be used like any module in the list because it
        provides the same API. In some way, we can say that a MetaModule
        "aggregates" all of it's submodules.
        For instance, AuthMetaModule.check_auth() would call the check_auth()
        methods of all it's "submodules" until one return True.

        Finally, a MetaModule can provide a default behaviour for some methods.
        For instance, if there is no auth module in the WebUI, AuthMetaModule
        is still working, because it provides it's own check_auth().

        If you want to understand it better, please look at the examples. 
    """

    _functions = []
    _custom_log = ""

    def __init__(self, modules, app):
        self.modules = modules
        self.app = app
        if not modules:
            logger.info("[WebUI] No module for %s. %s" % (self.__class__.__name__, self._custom_log))

    def is_available(self):
        ''' Is the MetaModule available? Checks if the MetaModule have at least one module. '''
        return bool(self.modules)

    @classmethod
    def find_modules(cls, modules):
        ''' Filter the modules and returns only the modules that contains the
            methods listed in `_functions`. '''
        logger.debug("[WebUI] searching module containing %s…" % ', '.join(cls._functions))
        mods = []
        for mod in modules:
            found = True
            for name in cls._functions:
                f = getattr(mod, name, None)
                if not f or not callable(f):
                    found = False
                    continue
            if found:
                logger.info("[WebUI] Module found: %s", mod.get_name())
                mods.append(mod)
        return mods
        
