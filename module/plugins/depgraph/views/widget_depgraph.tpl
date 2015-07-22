

%print 'Elt value?', elt
%import time

%# If got no Element, bailout
%if not elt:
%rebase("widget", title='Invalid element name')

Invalid element

%else:

%helper = app.helper
%datamgr = app.datamgr


<script type="text/javascript">
  var depgraph_width = 400;
  var depgraph_height = 400;
  var depgraph_injectInto = 'infovis-'+'{{helper.get_html_id(elt)}}';
</script>


%rebase("widget", title='Dependencies graph of ' + elt.get_full_name(),  js=['depgraph/js/jit-yc.js', 'depgraph/js/excanvas.js', 'depgraph/js/eltdeps.js'],  css=['depgraph/css/eltdeps.css', 'depgraph/css/eltdeps_widget.css'])


<script src=/static/depgraph/js/eltdeps.js></script>
<script type="text/javascript">
  
  // Get container dimensions
  var container = $(window);
  //console.log('Container size: ', container.innerWidth(), container.innerHeight());
  // Widget width is around 1/3 of window width ... and small margins !
  var width = (container.innerWidth() / 3) - 50;
  var height = container.innerHeight() - 5;
  // Height is not significative ... because container is fluid ... set fixed height !
  var height = 400;
 
  $(document).ready(init_graph('{{elt.get_full_name()}}', {{!helper.create_json_dep_graph(elt, levels=4)}}, width, height, '{{helper.get_html_id(elt)}}'));
 
 
</script>


<div id="right-container" class="" style="display: none">
  <div id="inner-details-{{helper.get_html_id(elt)}}">
  </div>
</div>

<div id="infovis-{{helper.get_html_id(elt)}}"> </div>

<div id="log">Loading element informations...</div>
  
<div class="clear"></div>
</div>

%#End of the Host Exist or not case
%end



