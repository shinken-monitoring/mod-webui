
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
            
            // Loading indicator ...
            $("#{{graphId}} .alert").hide();
         });
      </script>


      <div id="{{graphId}}" class="gMap">
         <div class="alert alert-info">
            <a href="#" class="alert-link">Creating dependency graph ...</a>
         </div>
         <div id="inner-details-{{app.helper.get_html_id(elt)}}">
         </div>
      </div>
      
      <div id="infovis-{{app.helper.get_html_id(elt)}}"> </div>

      <div id="log">Loading element informations...</div>

      %#End of the Host Exist or not case
   %end
</div>
