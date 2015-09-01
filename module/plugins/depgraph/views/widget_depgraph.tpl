
<!-- HTML map container -->
<div class="depgraph_container_widget">
   %if not elt:
      <center>
         <h3>No element to graph.</h3>
      </center>
   %else:
      %helper = app.helper

      %rebase("widget", title='Dependencies graph for ' + elt.get_full_name(),  js=['depgraph/js/jit-yc.js', 'depgraph/js/excanvas.js'],  css=['depgraph/css/eltdeps.css', 'depgraph/css/eltdeps_widget.css'])

      <script src="/static/depgraph/js/eltdeps.js" />
      <script type="text/javascript">
         $(document).ready(function (){
            init_graph('{{elt.get_full_name()}}', {{!app.helper.create_json_dep_graph(elt, levels=4)}}, $('#{{graphId}}').width(), 300, '{{app.helper.get_html_id(elt)}}');
         });
      </script>

      <div id="{{graphId}}">
         <div class="depgraph-log" id="log-{{app.helper.get_html_id(elt)}}">Loading element informations...</div>
         
         <div class="depgraph-graph" id="infovis-{{app.helper.get_html_id(elt)}}"> </div>
         
         <div class="depgraph-details" id="inner-details-{{app.helper.get_html_id(elt)}}"></div>
      </div>
   %end
</div>
