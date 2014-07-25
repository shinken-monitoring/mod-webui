%import json

<script>
	all_perfs = {{json.dumps(all_perfs)}}
	all_disks = all_perfs['all_disks'];
	all_states = {{! json.dumps(all_states)}};
	all_services = {{! json.dumps(all_perfs['all_services'])}};

  var customView = '{{view_name}}';
  var imgSrc = '/static/'+customView+'/img/';
	loadjscssfile('/static/'+customView+'/js/'+customView+'.js', 'js');
	loadjscssfile('/static/'+customView+'/css/'+customView+'.css', 'css');
</script>

<div id='{{view_name}}'>
	<canvas name='host_canvas' width='1024' height='600' 
		data-global-state="{{all_states['global']}}" 
		data-name='{{elt.get_name()}}' 
		data-host-state-image="host_{{all_states['global'].lower()}}.png"
		data-host-network-state="{{all_states['network'].lower()}}"
		data-host-network-image="network_{{all_states['network'].lower()}}.png"
		data-host-network-address="{{elt.address}}"
		data-host-printer-state="{{all_states['printer'].lower()}}"
		data-host-printer-image="printer_{{all_states['printer'].lower()}}.png"
		data-host-printer-pages="{{all_perfs['printed_pages']}}"
		>
	</canvas>

	<div class="cpu_container">
		<canvas class='donut_canvas' name='donut_CPU' id="donutLinuxCPU" data-value={{all_perfs['cpu']}} data-state="{{all_states['cpu']}}" width="100" height="100"></canvas>
		<span class="donut_value">{{all_perfs['cpu']}}%</span>
		<span class="donut_label">CPU</span>
	</div>

	<div class="cylinderContainer">
		<div name="cylinder_mem">
			<canvas class='cylinder_canvas' data-value={{all_perfs['memory']}} data-state="{{all_states['memory']}}" width="30" height="100"></canvas>
			<span>Memory</span>
			<span>{{all_perfs['memory']}}%</span>
		</div>
		
		<div name="cylinder_paged" >
			<canvas class='cylinder_canvas' data-value={{all_perfs['paged']}} data-state="{{all_states['paged']}}" width="30" height="100"></canvas>
			<span>Paged</span>
			<span>{{all_perfs['paged']}}%</span>
		</div>
	</div>
</div>


<script>
	$('document').ready(function() {
		register_all_donuts();
		register_all_cylinders();
/*
    // Get container dimensions
    var container = $('#{{view_name}}').parent();
    console.log (container);
    console.log('Container size: ', container.innerWidth(), container.innerHeight());
    
    $('#{{view_name}}')
      .css('width', container.innerWidth() - 20)
      .css('height', container.innerHeight() - 20);
    
    var container = $('#{{view_name}}');
    console.log('Container size: ', container.innerWidth(), container.innerHeight());
    $('#{{view_name}} canvas[name="host_canvas"]')
      .css('width', container.innerWidth() - 4)
      .css('height', container.innerHeight() - 4);
*/
	});
</script>
