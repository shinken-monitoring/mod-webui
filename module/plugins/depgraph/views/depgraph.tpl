

%print 'Elt value?', elt
%import time

%# If got no Element, bailout
%if not elt:
%rebase("layout", title='Invalid element name')

Invalid element

%else:

%helper = app.helper
%datamgr = app.datamgr

%# No default refresh for this page
%rebase("layout", title='Dependencies graph of ' + elt.get_full_name(),  refresh=False)


<script src='/static/depgraph/js/eltdeps.js'></script>


<script type="text/javascript">
  loadjscssfile('/static/depgraph/css/eltdeps_widget.css', 'css');
  loadjscssfile('/static/depgraph/css/eltdeps.css', 'css');
  loadjscssfile('/static/depgraph/js/jit-yc.js', 'js');
  loadjscssfile('/static/depgraph/js/excanvas.js', 'js');


  var graph = {{!helper.create_json_dep_graph(elt, levels=4)}};

  // Get container dimensions
  var container = $(window);
  // console.log('Container size: ', container.innerWidth(), container.innerHeight());
  // Graph size is almost window size ... and small margins !
  var width = container.innerWidth() - 40;
  var height = container.innerHeight() - 100;
 
  $(document).ready(init_graph('{{elt.get_full_name()}}', graph, width, height,'{{helper.get_html_id(elt)}}'));


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
        if(d > 2){
            var i = 0;
            for (i=2; i<d; i++){
		 important_elements.push(elt.name);
	   }
        }
    });
    //console.log(important_elements);
    var elu = important_elements[Math.floor(Math.random() * important_elements.length)];
    //console.log("Elu" + elu);
    change_rgraph_root(elu);

  }
<!-- {{loop_time}} -->
%if loop:
  $(document).ready(
     setInterval(Loop_over_elements, {{loop_time*1000}})
  );
%end

</script>

<div id="right-container" class="border">
<div id="inner-details-{{helper.get_html_id(elt)}}"></div>
</div>
<div id="infovis-{{helper.get_html_id(elt)}}"> </div>

<div id="log">Loading element informations...</div>


<div class="clear"></div>


%#End of the Host Exist or not case
%end



