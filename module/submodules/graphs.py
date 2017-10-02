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

            If duration is not None, we return the graph from now minus duration until now.
            But we also round "now" to the minute, to allow the cache to work and reduce
            network load.
            
            Else we use graphstart and graphend to call the module get_graphs_uri
        '''
        uris = []
        for mod in self.modules:
            if not duration:
                uris.extend(mod.get_graph_uris(elt, graphstart, graphend, source))
            else:
                graphend = (int(time.time()) / 60) * 60
                graphstart = graphend - duration
                uris.extend(mod.get_graph_uris(elt, graphstart, graphend, source))
                
            logger.debug("[WebUI] Got graphs: %s", uris)

        for uri in uris:
            uri['img_src'] = '/graph?url=' + urllib.quote(uri['img_src'])

        return uris
