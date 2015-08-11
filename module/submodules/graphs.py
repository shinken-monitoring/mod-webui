#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ai ts=4 sts=4 et sw=4 nu

import time
import urllib

from shinken.log import logger

from .metamodule import MetaModule

class GraphsMetaModule(MetaModule):

    _functions = ['get_graph_uris']
    _custom_log = "You should configure the module 'graphite' in your broker and the module 'ui-graphite' in webui.cfg file to be able to display graphs."

    def get_graph_uris(self, elt, graphstart=None, graphend=None, duration=None, source='detail'):
        ''' Aggregate the get_graph_uris of all the submodules. 
            The source parameter defines the source of the calling: 
            Are we displaying graphs for the element detail page (detail), 
            or a widget in the dashboard (dashboard) ?
            
            If duration is not None, we consider it as a number of seconds to graph and 
            we call the module get_relative_graphs_uri
            
            If get_relative_graphs_uri is not a module function we compute graphstart and 
            graphend and we call we call the module get_graphs_uri
            
            If graphstart and graphend are not None, we call the module get_graphs_uri
        '''
        uris = []
        for mod in self.modules:
            if not duration:
                uris.extend(mod.get_graph_uris(elt, graphstart, graphend, source))
            else:
                f = getattr(mod, 'get_relative_graph_uris', None)
                if f and callable(f):
                    uris.extend(f(elt, duration, source))
                else:
                    graphend = time.time()
                    graphstart = graphend - duration
                    uris.extend(mod.get_graph_uris(elt, graphstart, graphend, source))
                
            logger.debug("[WebUI] Got graphs: %s", uris)

        for uri in uris:
            uri['img_src'] = '/graph?url=' + urllib.quote(uri['img_src'])

        return uris
