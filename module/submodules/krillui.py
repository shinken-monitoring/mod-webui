#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ai ts=4 sts=4 et sw=4 nu

import time
import urllib

from shinken.log import logger

from .metamodule import MetaModule

class KrillUIMetaModule(MetaModule):

    _functions = ['get_data', 'set_data']
    _custom_log = ""
    
    def __init__(self, modules, app):
        if len(modules) == 1:
            self.module = modules[0]
            self.app = app
        
    def get_data(self, cpe_host):
        return self.module.get_data(cpe_host)

    def set_data(self, cpe_host, data):
        return self.module.set_data(cpe_host, data)