<!-- HTML map container -->
<div class="depgraph_container">
   %if not elt:
      <center>
         <h3>No element to graph.</h3>
      </center>
   %else:

      %rebase("layout", title='Dependencies graph of ' + elt.get_full_name(), refresh=False, js=['depgraph/js/eltdeps.js', 'depgraph/js/jit-yc.js', 'depgraph/js/excanvas.js'],  css=['depgraph/css/eltdeps.css', 'depgraph/css/eltdeps_widget.css'])

      <script type="text/javascript">
         var graph = {{!app.helper.create_json_dep_graph(elt, levels=4)}};
         /* 
          Function to loop over important elements, on a time base. Need to call the page with
          ?loop=1 and if need &loop_time=10 (10s loop time is the basic)
          The loop is random, and it will add more size for large business impact elements.
         */
         function Loop_over_elements(){
            var important_elements = [];
            console.log('Start to loop over');
            $.each(graph, function(idx, elt){
               console.log(elt);
               d = elt.data.business_impact;
               if (d > 2) {
                  var i = 0;
                  for (i=2; i<d; i++) {
                     important_elements.push(elt.name);
                  }
               }
            });
            
            //console.log(important_elements);
            var elu = important_elements[Math.floor(Math.random() * important_elements.length)];
            //console.log("Elu" + elu);
            change_rgraph_root(elu);
         }
         $(document).ready(function (){
            init_graph('{{elt.get_full_name()}}', graph, $('#{{graphId}}').width(), 800, '{{graphId}}');
            
            <!-- {{loop_time}} -->
            %if loop:
            setInterval(Loop_over_elements, {{loop_time*1000}})
            %end
         });
      </script>

      <div id="{{graphId}}">
         <div class="depgraph-log" id="log-{{graphId}}">Loading element informations...</div>
         
         <div class="depgraph-graph" id="infovis-{{graphId}}"> </div>
         
         <div class="depgraph-details" id="inner-details-{{graphId}}"></div>
      </div>
   %end
</div>


