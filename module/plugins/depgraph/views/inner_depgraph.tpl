<div class="depgraph_container_inner">
   %if not elt:
      <center>
         <h3>No element to graph.</h3>
      </center>
   %else:
      %helper = app.helper

      <!-- We need to sync load eltdeps.js and not in a asyncronous mode -->
      <script src='/static/depgraph/js/eltdeps.js'></script>
      <script type="text/javascript">
         loadjscssfile('/static/depgraph/css/eltdeps_widget.css', 'css');
         loadjscssfile('/static/depgraph/css/eltdeps.css', 'css');
         loadjscssfile('/static/depgraph/js/jit-yc.js', 'js');
         loadjscssfile('/static/depgraph/js/excanvas.js', 'js');

         $(document).ready(function (){
            init_graph('{{elt.get_full_name()}}', {{!app.helper.create_json_dep_graph(elt, levels=4)}}, $('#inner_depgraph').width(), 800,'{{app.helper.get_html_id(elt)}}');
         });
      </script>

      <div id="{{graphId}}">
         <!-- <div class="depgraph-log" id="log-{{app.helper.get_html_id(elt)}}">Loading element informations...</div> -->
         
         <div class="depgraph-graph" id="infovis-{{app.helper.get_html_id(elt)}}"> </div>
         
         <div class="depgraph-details" id="inner-details-{{app.helper.get_html_id(elt)}}"></div>
      </div>
   %end
</div>
