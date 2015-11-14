%if not 'global' in all_states:
<div view="cv_host" conf="{{config}}">
   <span class="alert alert-error">Sorry, I cannot load the view!</span>
</div>
%else:
<script>
   // Load specific CSS
   //loadjscssfile('/static/cv_host/css/cv_host.css', 'css');

   function draw_arc(ctx, x, y, radius, startAngle, endAngle, clockwise, color, lineWidth){
      var savec_lineWidth = ctx.lineWidth;
      var saved_color = ctx.strokeStyle;
      ctx.strokeStyle = color;
      ctx.lineWidth = lineWidth;
      ctx.beginPath();
      ctx.arc(x, y, radius, startAngle, endAngle, clockwise);
      ctx.stroke();
      ctx.strokeStyle = saved_color;
      ctx.lineWidth = savec_lineWidth;
   }
</script>

<div view="cv_host" conf="{{config}}">
   <div class="row" name="host_layout">
      <div class="col-sm-2" name="host_container">
         <canvas name="host_canvas" width="150" height="150"> </canvas>
         <h3 class="hostname">{{elt.get_name()}}</h3>
         <img src="/static/cv_host/img/host_{{all_states['host'].lower()}}.png"> </img>
      </div>
      <script>
         var host_canvas = $('[view="cv_host"][conf="{{config}}"] canvas[name="host_canvas"]');
         var ctx = host_canvas[0].getContext('2d');
         // Purple : '#c1bad9', '#a79fcb'
         // Green  : '#A6CE8D', '#81BA6B'
         // Blue   : '#DEF3F5', '#89C3C6'
         // Red    : '#dc4950', '#e05e65'
         // Orange : '#F1B16E', '#EC9054'
         // Grey   : '#dddddd', '#666666'
         var main_colors = {'UNKNOWN' : '#c1bad9', 'OK' : '#A6CE8D', 'UP' : '#A6CE8D', 'WARNING' : '#F1B16E', 'CRITICAL' : '#dc4950', 'DOWN' : '#dc4950', 'ACK' : '#dddddd', 'DOWNTIME' : '#666666'};
         var huge_colors = {'UNKNOWN' : '#a79fcb', 'OK' : '#81BA6B', 'UP' : '#81BA6B', 'WARNING' : '#EC9054', 'CRITICAL' : '#e05e65', 'DOWN' : '#e05e65', 'ACK' : '#666666', 'DOWNTIME' : '#dddddd'};

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
            <dt>Depends upon:</dt>
            %if elt.parent_dependencies:
            <dd>
            %parents=['<a href="/host/'+parent.host_name+'" class="link">'+parent.display_name+'</a>' for parent in sorted(elt.parent_dependencies,key=lambda x:x.display_name)]
            {{!','.join(parents)}}
            </dd>
            %else:
            <dd>(none)</dd>
            %end

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

            <dt>Depends upon me:</dt>
            %if elt.child_dependencies:
            <dd>
            %children=['<a href="/host/'+child.host_name+'" class="link">'+child.display_name+'</a>' for child in sorted(elt.child_dependencies,key=lambda x:x.display_name) if child.__class__.my_type=='host']
            {{!','.join(children)}}
            </dd>
            %else:
            <dd>(none)</dd>
            %end

            <dt>Children:</dt>
            %if elt.childs:
            <dd>
            %children=['<a href="/host/'+child.host_name+'" class="link">'+child.display_name+'</a>' for child in sorted(elt.childs,key=lambda x:x.display_name)]
            {{!','.join(children)}}
            </dd>
            %else:
            <dd>(none)</dd>
            %end
         </dl>

         <dl class="dl-horizontal">
            <dt>Member of:</dt>
            %if len(elt.hostgroups) > 0:
            <dd>
            %i=0
            %for hg in elt.hostgroups:
            {{',' if i != 0 else ''}}
            <a href="/hosts-group/{{hg.get_name()}}" class="link">{{hg.alias if hg.alias else hg.get_name()}}</a>
            %i=i+1
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

   <div class="row" name="services_layout">
      <div class="col-sm-6" name="left_metrics">
         %if 'load' in all_states and all_perfs['load']:
         <div class="well well-sm" name="load_container">
            <span class="pull-right">{{!app.helper.get_fa_icon_state_and_label(cls='service', state=all_states['load'])}}</span>
            <h4>Load average</h4>
            %for load in all_perfs['load']:
            <div class="donut ">
               <div class="graph" style="width: 100px; height: 100px;" id="{{config}}-load-{{app.helper.make_html_id(load)}}"></div>
               <div class="name">{{load}}</div>
               <div class="value">{{all_perfs['load'][load]}}</div>
            </div>
            <script>
               var data = [];

               %if '%' in load:
               data[1] = { label: "{{load}}", data: {{all_perfs['load'][load]}}, color: main_colors['{{all_states['load']}}'] };
               data[0] = { label: "", data: 100-{{all_perfs['load'][load]}}, color: '#cccccc' };
               %else:
               data[1] = { label: "{{load}}", data: {{10 * all_perfs['load'][load]}}, color: main_colors['{{all_states['load']}}'] };
               data[0] = { label: "", data: 100-{{10 * all_perfs['load'][load]}}, color: '#cccccc' };
               %end

               $.plot($('#{{config}}-load-{{app.helper.make_html_id(load)}}'), data, {
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

         %if 'cpu' in all_states and all_perfs['cpu']:
         <div class="well well-sm" name="cpu_container">
            <span class="pull-right">{{!app.helper.get_fa_icon_state_and_label(cls='service', state=all_states['cpu'])}}</span>
            <h4>CPU</h4>
            %for cpu in all_perfs['cpu']:
            <div class="donut ">
               <div class="graph" style="width: 100px; height: 100px;" id="{{config}}-cpu-{{app.helper.make_html_id(cpu)}}"></div>
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

               $.plot($('#{{config}}-cpu-{{app.helper.make_html_id(cpu)}}'), data, {
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

         %if 'memory' in all_states and all_perfs['memory']:
         <div class="well well-sm" name="memory_container">
            <span class="pull-right">{{!app.helper.get_fa_icon_state_and_label(cls='service', state=all_states['memory'])}}</span>
            <h4>Memory</h4>
            <div class="barchart" style="width:100%; height: 120px;" id="{{config}}-memory-barchart"></div>
         </div>
         <script>
            // Draw a bar chart ...
            $.plot($('#{{config}}-memory-barchart'), [
               %i=0
               %for mem in all_perfs['memory']:
                  {
                     data: [ [{{i}}, {{all_perfs['memory'][mem]}}] ],
                     color: main_colors['{{all_states['memory']}}'],
                     valueLabels: {
                        show: true,
                        yoffset: 0, yoffsetMin: 0,
                        labelFormatter: function(v) {
                           return (+v).toFixed(0);
                        },
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
                     %try:
                     show: true, min: 0, max: {{ max(100, max(all_perfs['memory'].values())) }}
                     %except ValueError:
                     show: true, min: 0, max: 100
                     %end
                  },
                  xaxis: {
                     show: true,
                     position: "bottom",
                     tickSize: 1,
                     rotateTicks: {{0 if len(all_perfs['memory']) < 5 else 60}},
                     tickFormatter: function(val, axis) {
                        var values=[];
                        %for mem in all_perfs['memory']:
                           values.push('{{mem}}');
                        %end

                        if (val==-1) return ('');
                        return (values[val]);
                     }
                  }
               }
            );
         </script>
         %end

         %if 'disks' in all_states and all_perfs['disks']:
         <div class="well well-sm" name="disks_container">
            <span class="pull-right">{{!app.helper.get_fa_icon_state_and_label(cls='service', state=all_states['disks'])}}</span>
            <h4>Disks</h4>
            <div class="barchart" style="width:100%; height: 120px;" id="{{config}}-disks-barchart"></div>
         </div>
         <script>
            // Draw a bar chart ...
            $.plot($('#{{config}}-disks-barchart'), [
               %i=0
               %for disk in all_perfs['disks']:
                  {
                     data: [ [{{i}}, {{all_perfs['disks'][disk]}}] ],
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
                     %try:
                     show: true, min: 0, max: {{ max(100, max(all_perfs['disks'].values())) }}
                     %except ValueError:
                     show: true, min: 0, max: 100
                     %end
                  },
                  xaxis: {
                     show: true,
                     position: "bottom",
                     tickSize: 1,
                     rotateTicks: {{0 if len(all_perfs['disks']) < 5 else 60}},
                     tickFormatter: function(val, axis) {
                        var values=[];
                        %for disk in all_perfs['disks']:
                           values.push('{{disk}}');
                        %end

                        if (val==-1) return ('');
                        return (values[val]);
                     }
                  }
               }
            );
         </script>
         %end

         %if 'network' in all_states and all_perfs['network']:
         <div class="well well-sm" name="network_container">
            <span class="pull-right">{{!app.helper.get_fa_icon_state_and_label(cls='service', state=all_states['network'])}}</span>
            <h4>Network</h4>
            <div class="barchart" style="width:100%; height: 120px;" id="{{config}}-network-barchart"></div>
         </div>
         <script>
            // Draw a bar chart ...
            $.plot($('#{{config}}-network-barchart'), [
               %i=0
               %for net in all_perfs['network']:
                  {
                     data: [ [{{i}}, {{all_perfs['network'][net]}}] ],
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
                     %try:
                     show: true, min: 0, max: {{ max(100, max(all_perfs['network'].values())) }}
                     %except ValueError:
                     show: true, min: 0, max: 100
                     %end
                  },
                  xaxis: {
                     show: true,
                     position: "bottom",
                     tickSize: 1,
                     rotateTicks: {{0 if len(all_perfs['network']) < 5 else 60}},
                     tickFormatter: function(val, axis) {
                        var values=[];
                        %for net in all_perfs['network']:
                           values.push('{{net}}');
                        %end

                        if (val==-1) return ('');
                        return (values[val]);
                     }
                  }
               }
            );
         </script>
         %end
      </div>

      <div class="col-sm-6" name="right_metrics">
         %if 'services' in all_states:
         <div class="well well-sm services-tree" name="services_container">
           {{!app.helper.print_aggregation_tree(app.helper.get_host_service_aggregation_tree(elt, app), app.helper.get_html_id(elt), expanded=True, max_sons=3)}}
         </div>
         %end
      </div>
   </div>
</div>


<script>
   // Elements popover
   $('[data-toggle="popover"]').popover();

   $('[data-toggle="popover medium"]').popover({
      trigger: "hover",
      placement: 'bottom',
      toggle : "popover",
      viewport: {
         selector: 'body',
         padding: 10
      },

      template: '<div class="popover popover-medium"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>',
   });

   // When toggle list is activated ...
   $('[name="services_container"] a.toggle-list').on('click', function () {
      var state = $(this).data('state');
      var target = $(this).data('target');

      if (state=='expanded') {
         $('[name="services_container"] ul[name="'+target+'"]').hide();
         $(this).data('state', 'collapsed')
         $(this).children('i').removeClass('fa-minus').addClass('fa-plus');
      } else {
         $('[name="services_container"] ul[name="'+target+'"]').show();
         $(this).data('state', 'expanded')
         $(this).children('i').removeClass('fa-plus').addClass('fa-minus');
      }
   });
</script>
%end