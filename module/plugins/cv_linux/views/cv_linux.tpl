%import json

<script>
	all_perfs = {{json.dumps(all_perfs)}}
	all_disks = all_perfs['all_disks'];
	all_states = {{! json.dumps(all_states)}};
	all_services = {{! json.dumps(all_perfs['all_services'])}};

	loadjscssfile('/static/cv_linux/js/host_canvas.js', 'js');
	loadjscssfile('/static/cv_linux/css/host_canvas.css', 'css');
</script>

<div id='cv_linux'>
	<canvas name='host_canvas' width='800' height='480' 
		data-global-state="{{all_states['global']}}" 
		data-name='{{elt.get_name()}}' 
		data-host-state-image="host_{{all_states['global'].lower()}}.png"
		data-host-network-state="{{all_states['network'].lower()}}"
		data-host-network-image="network_{{all_states['network'].lower()}}.png"
		data-host-network-address='{{elt.address}}' 
		data-host-printer-state="{{all_states['printer'].lower()}}"
		data-host-printer-image="printer_{{all_states['printer'].lower()}}.png"
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
			
		<div name="cylinder_swap" >
			<canvas class='cylinder_canvas' data-value={{all_perfs['swap']}} data-state="{{all_states['swap']}}" width="30" height="100"></canvas>
			<span>Swap</span>
			<span>{{all_perfs['swap']}}%</span>
		</div>
	</div>
</div>


<script>
	$('document').ready(function() {
		register_all_donuts();
		register_all_cylinders();
	});
</script>
