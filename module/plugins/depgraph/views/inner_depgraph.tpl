%helper = app.helper
%datamgr = app.datamgr
%import time

%# If got no Element, bailout
%if not elt:
Invalid element
%else:


%# We need to sync load eltdeps.js and not in a asyncronous mode
<script src='/static/depgraph/js/eltdeps.js'></script>

<script type="text/javascript">
  loadjscssfile('/static/depgraph/css/eltdeps_widget.css', 'css');
  loadjscssfile('/static/depgraph/css/eltdeps.css', 'css');
  loadjscssfile('/static/depgraph/js/jit-yc.js', 'js');
  loadjscssfile('/static/depgraph/js/excanvas.js', 'js');

  // Get container dimensions
  var container = $('#inner_depgraph');
  console.log('Container size: ', '{{elt.get_full_name()}}', '{{helper.get_html_id(elt)}}', container.innerWidth(), container.innerHeight());
  var width = container.innerWidth() - 5;
  var height = container.innerHeight() - 5;
  // Height is not significative ... because container is fluid ... set fixed height !
  var height = 800;

  $(document).ready(init_graph('{{elt.get_full_name()}}', {{!helper.create_json_dep_graph(elt, levels=4)}}, width, height,'{{helper.get_html_id(elt)}}'));

</script>



<div id="inner-details-{{helper.get_html_id(elt)}}"></div>
<div id="infovis-{{helper.get_html_id(elt)}}"> </div>

<div id="log">Loading element informations...</div>


%#End of the Host Exist or not case
%end



