#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ai ts=4 sts=4 et sw=4 nu

from shinken.log import logger

from submodules.metamodule import MetaModule

class GraphsMetaModule(MetaModule):

    _functions = ['get_graph_uris']
    _custom_log = "You should configure the module 'graphite' in your broker and the module 'ui-graphite' in webui.cfg file to be able to display graphs."

    def get_graph_uris(self, elt, graphstart, graphend, source='detail'):
        ''' Aggregate the get_graph_uris of all the submodules. '''
        uris = []
        for mod in self.modules:
            uris.extend(mod.get_graph_uris(elt, graphstart, graphend, source))
            logger.debug("[WebUI] Got graphs: %s", uris)
        return uris
