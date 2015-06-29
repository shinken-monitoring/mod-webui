%import json

<script>
   var customView = '{{view_name}}';
   
   loadjscssfile('/static/'+customView+'/css/'+customView+'.css', 'css');
   
   var debug = true;
   all_perfs = {{! json.dumps(all_perfs)}}
   if (debug) console.debug('all_perfs', all_perfs);
   all_states = {{! json.dumps(all_states)}};
   if (debug) console.debug('all_states', all_states);

   var imgSrc = '/static/'+customView+'/img/';
   
   // Get container dimensions
   var container = $('#{{view_name}}').parent();
   if (debug) console.debug('Container size: ', container.innerWidth(), container.innerHeight());

   $('#{{view_name}}')
      .css('width', container.innerWidth() - 40)
      .css('height', container.innerHeight() - 40);

   $('#{{view_name}} [name="host_container"]')
      .prepend('<canvas name="host_canvas" width="'+(container.innerWidth() - 24)+'" height="'+(container.innerHeight() - 24)+'" data-global-state="'+all_states['global']+'" data-host-state="'+all_states['host']+'" data-name="'+'{{elt.get_name()}}'+'"> </canvas>')

</script>

<div id='{{view_name}}'>
   <script>
      var host_canvas = $('#'+customView+' canvas[name="host_canvas"]');
      var ctx = host_canvas[0].getContext('2d');
      // Purple : '#c1bad9', '#a79fcb'
      // Green  : '#A6CE8D', '#81BA6B'
      // Blue   : '#DEF3F5', '#89C3C6'
      // Red    : '#dc4950', '#e05e65'
      // Orange : '#F1B16E', '#EC9054'
      var main_colors = {'UNKNOWN' : '#c1bad9', 'OK' : '#A6CE8D', 'UP' : '#A6CE8D', 'WARNING' : '#F1B16E', 'CRITICAL' : '#dc4950', 'DOWN' : '#dc4950'};
      var huge_colors = {'UNKNOWN' : '#a79fcb', 'OK' : '#81BA6B', 'UP' : '#81BA6B', 'WARNING' : '#EC9054', 'CRITICAL' : '#e05e65', 'DOWN' : '#e05e65'};

      var global_state = host_canvas.data('global-state');
      var main_color = main_colors[global_state];
      var huge_color = huge_colors[global_state];
      var line_color = huge_color;

      // Inner circle
      draw_arc(ctx, 80, 80, 32, 0, 2*Math.PI, true, main_color, 40, 0.5);
      draw_arc(ctx, 80, 80, 33, 0, 2*Math.PI, true, huge_color, 2, 0.5);

      // Middle one
      draw_arc(ctx, 80, 80, 45, 0, 2*Math.PI, true, main_color, 2, 0.3);
      draw_arc(ctx, 80, 80, 46, 0, 2*Math.PI, true, main_color, 2, 0.3);
      // The left part of the middle
      draw_arc(ctx, 80, 80, 44, 0.7*Math.PI, 1.1*Math.PI, false, huge_color, 4, 0.5);
      //Top rigth part of the middle
      draw_arc(ctx, 80, 80, 44, 1.5*Math.PI, 2*Math.PI, false, huge_color, 4, 0.5);


      // Before last one
      // Middle one
      draw_arc(ctx, 80, 80, 60, Math.PI, 0.4*Math.PI, false, main_color, 2, 0.5);
      draw_arc(ctx, 80, 80, 61, Math.PI, 0.4*Math.PI, false, main_color, 2, 0.5);
      // The left part of the before last 
      draw_arc(ctx, 80, 80, 59, Math.PI, 1.7*Math.PI, false, huge_color, 5);
      //Top rigth art of the middle
      draw_arc(ctx, 80, 80, 59, 0, 0.4*Math.PI, false, huge_color, 5);
   
      // Now the lines from the left part to down, in 3 parts
      draw_line(ctx, 20, 80, 20, 100, line_color, 1, 0.5);
      draw_line(ctx, 20, 100, 50, 140, line_color, 1, 0.5);
      draw_line(ctx, 50, 140, 50, 200, line_color, 1, 0.5);
      
      var linePos = 200;
   </script>
   
   <div name="host_container">
      <h1> {{elt.get_name()}}</h1>
      <img src="/static/{{view_name}}/img/host_{{all_states['host'].lower()}}.png"> </img>
   </div>

   %if 'cpu' in all_states and 'cpu' in all_perfs:
   <div class="well well-sm" name="cpu_container">
      %for cpu in all_perfs['cpu']:
      <div class="donut" >
         <div style="width:100px; height: 100px;" id="cpu-{{app.helper.make_html_id(cpu)}}"></div>
         <div class="name">{{cpu}}</div>
         <div class="value">{{all_perfs['cpu'][cpu]}}</div>
      </div>
      <script>
         function labelFormatter(label, series) {
            return "<div style='font-size:8pt; text-align:center; padding:2px; color:black;'>" + label + "<br/>" + Math.round(series.percent) + "%</div>";
         }
            
         var data = [];

         %if '%' in cpu:
         data[1] = { label: "{{cpu}}", data: {{all_perfs['cpu'][cpu]}}, color: main_colors['{{all_states['cpu']}}'] };
         data[0] = { label: "", data: 100-{{all_perfs['cpu'][cpu]}}, color: '#cccccc' };
         %else:
         data[1] = { label: "{{cpu}}", data: {{all_perfs['cpu'][cpu]}}, color: main_colors['{{all_states['cpu']}}'] };
         data[0] = { label: "", data: 100-{{all_perfs['cpu'][cpu]}}, color: '#cccccc' };
         %end

         $.plot($('#cpu-{{app.helper.make_html_id(cpu)}}'), data, {
            series: {
               pie: { 
                  show: true,
                  radius: 1,
                  innerRadius: 0.7,
                  label: {
                     show: false,
                     radius: 3/4,
                     //formatter: labelFormatter,
                     
                  }
               }
            },
            legend: {
               show: false
            }
         });
      </script>
      %end
   </div>
   <script>
      // Draw a line that go to the CPU
      draw_line(ctx, 140, 81, 200, 81, line_color, 1, 0.5);
      draw_line(ctx, 200, 81, 300, 130, line_color, 1, 0.5);
   </script>
   %end

   %if 'memory' in all_states and 'memory' in all_perfs:
   <div class="well well-sm" name="memory_container">
      <div class="barchart" style="width:250px; height: 120px;" id="memory-barchart"></div>
   </div>
   <script>
      // Draw a line that go to the memory
      draw_line(ctx, 140, 81, 185, 81, line_color, 1, 0.5);
      draw_line(ctx, 185, 81, 300, 270, line_color, 1, 0.5);
      
      // Draw a bar chart ...
      $.plot($('#memory-barchart'), [
         %i=0
         %for mem in all_perfs['memory']:
            {
               data: [ [{{i}}, {{all_perfs['memory'][mem]}}] ],
               label: '{{mem}}',
               color: main_colors['{{all_states['memory']}}'],
               valueLabels: {
                  show: true,
                  yoffset: 0, yoffsetMin: 0,
                  labelFormatter: function(v) {
                     return (+v).toFixed(0);
                  },
                  //valign: 'top', align: 'center', font: "8pt 'Arial'", fontcolor: '#666'
               },
               bars: { 
                  show: true, align: "center", lineWidth: 2, barWidth: 0.5
               }
            },
           %i=i+1
         %end
         ],
         {
            grid: {
               show: true, margin: 0, borderWidth: 0, clickable: true, hoverable: true
            },
            legend: {
               show: false
            },
            yaxis: {
               show: true, min: 0, max: 100
            },
            xaxis: {
               show: true,
               position: "bottom",
               tickSize: 1,
               tickFormatter: function(val, axis) {
                  %i=0
                  %for mem in all_perfs['memory']:
                     if (val == {{i}}) return '{{mem}}';
                    %i=i+1
                  %end
               }
            }
         }
      );
   </script>
   %end

   %if 'disks' in all_states:
   <div class="well well-sm" name="disks_container">
      <div class="barchart" style="width:250px; height: 120px;" id="disks-barchart"></div>
   </div>
   <script>
      // Draw a line that go to the memory
      draw_line(ctx, 140, 81, 170, 81, line_color, 1, 0.5);
      draw_line(ctx, 170, 81, 300, 410, line_color, 1, 0.5);

      // Draw a bar chart ...
      $.plot($('#disks-barchart'), [
         %i=0
         %for disk in all_perfs['disks']:
            {
               data: [ [{{i}}, {{all_perfs['disks'][disk]}}] ],
               label: '{{disk}}',
               color: main_colors['{{all_states['disks']}}'],
               valueLabels: {
                  show: true,
                  yoffset: 0, yoffsetMin: 0,
                  labelFormatter: function(v) {
                     return (+v).toFixed(0);
                  },
                  //valign: 'top', align: 'center', font: "8pt 'Arial'", fontcolor: '#666'
               },
               bars: { 
                  show: true, align: "center", lineWidth: 2, barWidth: 0.5
               }
            },
           %i=i+1
         %end
         ],
         {
            grid: {
               show: true, margin: 0, borderWidth: 0, clickable: true, hoverable: true
            },
            legend: {
               show: false
            },
            yaxis: {
               show: true, min: 0, max: 100
            },
            xaxis: {
               show: true,
               position: "bottom",
               tickSize: 1,
               tickFormatter: function(val, axis) {
                  %i=0
                  %for disk in all_perfs['disks']:
                     if (val == {{i}}) return '{{disk}}';
                    %i=i+1
                  %end
               }
            }
         }
      );
   </script>
   %end

   %if 'network' in all_states:
   <div name="network_container">
      <img src="/static/{{view_name}}/img/network_{{all_states['network'].lower()}}.png"> </img>
      <script>
         // Draw lines around disk ...
         draw_line(ctx, 50, linePos, 50, linePos+30, line_color, 1, 0.5);
         linePos += 30;
         draw_line(ctx, 50, linePos, 100, linePos, line_color, 1, 0.5);
         //
      </script>
      %for net in all_perfs['network']:
      <div name="network-{{app.helper.make_html_id(net)}}">
         <div class="name">{{net}}: {{all_perfs['network'][net]}}</div>
      </div>
      %end
   </div>
   %end

   %if 'printer' in all_states:
   <div name="printer_container">
      %for prn in all_perfs['printer']:
      <div name="printer-{{app.helper.make_html_id(prn)}}">
         <canvas class='vertical_cylinder_canvas' data-value="{{all_perfs['printer'][prn]}}" data-state="{{all_states['printer']}}" width="30" height="100"></canvas>
         <span class="value">{{all_perfs['printer'][prn]}}%</span>
         <span class="label">{{prn}}</span>
      </div>
      %end
   </div>
   %end

   %if 'services' in all_states:
   <div class="well well-sm" name="services_container">
      <script>
         // Draw lines around disk ...
         draw_line(ctx, 50, linePos, 50, linePos+80, line_color, 1, 0.5);
         linePos += 80;
         draw_line(ctx, 50, linePos, 100, linePos, line_color, 1, 0.5);
         //
      </script>
      %for svc in elt.services:
      <div name="services-{{app.helper.make_html_id(svc.get_name())}}">
         <a href="/service/{{elt.get_name()}}/{{svc.get_name()}}" title="{{svc.get_name()}} - {{svc.state}} - {{app.helper.print_duration(svc.last_chk)}} - {{svc.output}}">
            {{!app.helper.get_fa_icon_state_and_label(cls='service', state=svc.state, label=svc.get_name(), useTitle=False)}}
         </a>
      </div>
      %end
   </div>
   %end
</div>


<script>
   // Initialize all_donuts only if not done before
   if (typeof all_donuts === "undefined"){
      all_donuts = [];
   }
   register_all_donuts();
   setInterval("update_donuts();", 50); 
   
   register_all_cylinders();
</script>
