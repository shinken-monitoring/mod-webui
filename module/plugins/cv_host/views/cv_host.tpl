%import json

<script>
   // Load specific CSS
   loadjscssfile('/static/cv_host/css/cv_host.css', 'css');
   
   var debug = true;
   console.log('{{! json.dumps(all_states)}}')
   console.log('{{! json.dumps(all_perfs)}}')

/*
   // Get container dimensions
   var container = $('#cv_host').parent();
   if (debug) console.debug('Container size: ', container.innerWidth(), container.innerHeight());

   // On resize ...
   $(window).bind("load resize", function() {
      // Get container dimensions
      var container = $('#cv_host').parent();
      if (debug) console.debug('Container size: ', container.innerWidth(), container.innerHeight());

      $('#cv_host')
         .css('width', container.innerWidth() - 30)
         .css('height', container.innerHeight() - 30);
         
      $('#cv_host [name="host_container"]')
         .css('width', container.innerWidth() - 34)
         .css('height', container.innerHeight() - 34);
   });
*/
</script>

<div id='cv_host'>
   <div class="row" name="host_layout">
      <div class="col-sm-2" name="host_container">
         <canvas name="host_canvas" width="150" height="150"> </canvas>
         <h1>{{elt.get_name()}}</h1>
         <img src="/static/cv_host/img/host_{{all_states['host'].lower()}}.png"> </img>
      </div>
      <script>
         var host_canvas = $('#cv_host canvas[name="host_canvas"]');
         var ctx = host_canvas[0].getContext('2d');
         // Purple : '#c1bad9', '#a79fcb'
         // Green  : '#A6CE8D', '#81BA6B'
         // Blue   : '#DEF3F5', '#89C3C6'
         // Red    : '#dc4950', '#e05e65'
         // Orange : '#F1B16E', '#EC9054'
         var main_colors = {'UNKNOWN' : '#c1bad9', 'OK' : '#A6CE8D', 'UP' : '#A6CE8D', 'WARNING' : '#F1B16E', 'CRITICAL' : '#dc4950', 'DOWN' : '#dc4950'};
         var huge_colors = {'UNKNOWN' : '#a79fcb', 'OK' : '#81BA6B', 'UP' : '#81BA6B', 'WARNING' : '#EC9054', 'CRITICAL' : '#e05e65', 'DOWN' : '#e05e65'};

         var global_state = "{{all_states['host']}}";
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
         
         var linePos = 200;
      </script>
      <div class="col-sm-10 pull-right" name="host_tags">
         %if hasattr(elt, 'get_host_tags') and len(elt.get_host_tags()) != 0:
         <div class="btn-group pull-right">
            %i=0
            %for t in sorted(elt.get_host_tags()):
               <a href="/all?search=htag:{{t}}">
                  <button class="btn btn-default btn-xs"><i class="fa fa-tag"></i> {{t.lower()}}</button>
               </a>
               %i=i+1
            %end
         </div>
         %end
      </div>
      <div class="col-sm-10" name="host_information">
         <dl class="dl-horizontal">
            <dt>Alias:</dt>
            <dd>{{elt.alias}}</dd>

            <dt>Address:</dt>
            <dd>{{elt.address}}</dd>

            <dt>Importance:</dt>
            <dd>{{!app.helper.get_business_impact_text(elt.business_impact, True)}}</dd>
         </dl>
        
         <dl class="dl-horizontal">
            <dt>Parents:</dt>
            %if len(elt.parents) > 0:
            <dd>
            %for parent in elt.parents:
            <a href="/host/{{parent.get_name()}}" class="link">{{parent.alias}} ({{parent.get_name()}})</a>
            %end
            </dd>
            %else:
            <dd>(none)</dd>
            %end


            <dt>Member of:</dt>
            %if len(elt.hostgroups) > 0:
            <dd>
            %for hg in elt.hostgroups:
            <a href="/hosts-group/{{hg.get_name()}}" class="link">{{hg.alias}} ({{hg.get_name()}})</a>
            %end
            </dd>
            %else:
            <dd>(none)</dd>
            %end

            <dt>Notes:</dt>
            <dd>
            %for note_url in app.helper.get_element_notes_url(elt, default_title="Note", default_icon="tag", popover=True):
               <button class="btn btn-default btn-xs">{{! note_url}}</button>
            %end
            </dd>
         </dl>
      </div>
   </div>

   <div class="row clearfix">
      <div class="col-sm-6" name="left_metrics">
         %if 'cpu' in all_states and 'cpu' in all_perfs:
         <div class="well well-sm" name="cpu_container">
            <h4>CPU</h4>
            %for cpu in all_perfs['cpu']:
            <div class="donut ">
               <div class="graph" style="width: 100px; height: 100px;" id="cpu-{{app.helper.make_html_id(cpu)}}"></div>
               <div class="name">{{cpu}}</div>
               <div class="value">{{all_perfs['cpu'][cpu]}}</div>
            </div>
            <script>
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
                        }
                     }
                  },
                  legend: {
                     show: false
                  }
               });
            </script>
            %end
            <div class="clearfix"></div>
         </div>
         %end

         %if 'memory' in all_states and 'memory' in all_perfs:
         <div class="well well-sm" name="memory_container">
            <h4>Memory</h4>
            <div class="barchart" style="width:100%; height: 120px;" id="memory-barchart"></div>
         </div>
         <script>
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

         %if 'disks' in all_states and 'disks' in all_perfs:
         <div class="well well-sm" name="disks_container">
            <h4>Disks</h4>
            <div class="barchart" style="width:100%; height: 120px;" id="disks-barchart"></div>
         </div>
         <script>
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
         
         %if 'network' in all_states and 'network' in all_perfs:
         <div class="well well-sm" name="network_container">
            <h4>Network</h4>
            <div class="barchart" style="width:100%; height: 120px;" id="network-barchart"></div>
         </div>
         <script>
            // Draw a bar chart ...
            $.plot($('#network-barchart'), [
               %i=0
               %for net in all_perfs['network']:
                  {
                     data: [ [{{i}}, {{all_perfs['network'][net]}}] ],
                     label: '{{net}}',
                     color: main_colors['{{all_states['network']}}'],
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
                        %for net in all_perfs['network']:
                           if (val == {{i}}) return '{{net}}';
                          %i=i+1
                        %end
                     }
                  }
               }
            );
         </script>
         %end
      </div>
   
      <div class="col-sm-6" name="right_metrics">
         %if 'services' in all_states:
         <div class="well well-sm" name="services_container">
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
   </div>
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
