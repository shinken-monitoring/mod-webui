%graphs = dict()
%if not defined('service_description'):
%graphs[helper.get_uri_name(elt).replace("%20", "_")] = app.graphs_module.get_graph_uris(elt, graphstart=graphstart, graphend=graphend)
%else:
%for s in elt.services:
%if re.match(r'^%s$' % service_description, s.service_description):
%graphs[helper.get_uri_name(s).replace("%20", "_")] = app.graphs_module.get_graph_uris(s, graphstart=graphstart, graphend=graphend)
%end
%end
%end

%for n in graphs:
%for g in graphs[n]:
%import re
%source=int(re.findall(r'source%3D([0-9]+)', g['img_src'])[0])
%if not defined('condition') or condition(source):
<!--<p class="text-center">-->
<p>
  <img title={{ n }} src="{{g['img_src']}}&filename=graph-{{ n }}.png" class="img-thumbnail">
</p>
%end
%end
%end
