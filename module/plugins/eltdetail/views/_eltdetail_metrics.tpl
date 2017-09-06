%from shinken.misc.perfdata import PerfDatas
<div class="tab-pane fade" id="metrics">
  <div class="panel panel-default" style="border-top:none; border-radius:0;">
    <div class="panel-body">
      <table class="table table-condensed">
        <thead>
          <tr>
            %if elt_type=='host':
            <th>Service</th>
            %end
            <th>Metric</th>
            <th>Value</th>
            <th>Warning</th>
            <th>Critical</th>
            <th>Min</th>
            <th>Max</th>
            <th>UOM</th>
            <th></th>
          </tr>
        </thead>
        <tbody style="font-size:x-small;">
          %# Host check metrics ...
          %if elt_type=='host' or elt_type=='service':
          %host_line = True
          %perfdatas = PerfDatas(elt.perf_data)
          %if perfdatas:
          %for metric in sorted(perfdatas, key=lambda metric: metric.name):
          %if metric.name:
          <tr>
            %if elt_type=='host':
            <td><strong>{{'Host check' if host_line else ''}}</strong></td>
            %host_line = False
            %end
            <td><strong>{{metric.name}}</strong></td>
            <td>{{metric.value}}</td>
            <td>{{metric.warning if metric.warning!=None else ''}}</td>
            <td>{{metric.critical if metric.critical!=None else ''}}</td>
            <td>{{metric.min if metric.min!=None else ''}}</td>
            <td>{{metric.max if metric.max!=None else ''}}</td>
            <td>{{metric.uom if metric.uom else ''}}</td>

            %if app.graphs_module.is_available():
            <td>
              %graphs = app.graphs_module.get_graph_uris(elt, duration=12*3600)
              %for graph in graphs:
              %if re.findall('\\b'+metric.name+'\\b', graph['img_src']):
              <a role="button" tabindex="0"
                data-toggle="popover" title="{{ elt.get_full_name() }}"
                data-html="true"
                data-content="<img src='{{ graph['img_src'] }}' width='600px' height='200px'>"
                data-placement="left">{{!helper.get_perfometer(elt, metric.name)}}</a>
              %end
              %end
            </td>
            %else:
            <td>
              <a role="button" tabindex="0" >{{!helper.get_perfometer(elt, metric.name)}}</a>
            </td>
            %end
          </tr>
          %end
          %end
          %end
          %end
          %# Host services metrics ...
          %if elt_type=='host' and elt.services:
          %for s in elt.services:
          %service_line = True
          %perfdatas = PerfDatas(s.perf_data)
          %if perfdatas:
          %for metric in sorted(perfdatas, key=lambda metric: metric.name):
          %if metric.name and metric.value:
          <tr>
            <td>{{!helper.get_link(s, short=True) if service_line else ''}}</td>
            %service_line = False
            <td><strong>{{metric.name}}</strong></td>
            <td>{{metric.value}}</td>
            <td>{{metric.warning if metric.warning!=None else ''}}</td>
            <td>{{metric.critical if metric.critical!=None else ''}}</td>
            <td>{{metric.min if metric.min!=None else ''}}</td>
            <td>{{metric.max if metric.max!=None else ''}}</td>
            <td>{{metric.uom if metric.uom else ''}}</td>

            %if app.graphs_module.is_available():
            <td>
              %graphs = app.graphs_module.get_graph_uris(s, duration=12*3600)
              %for graph in graphs:
              %if re.findall('\\b'+metric.name+'\\b', graph['img_src']):
              <a role="button" tabindex="0"
                data-toggle="popover" title="{{ s.get_full_name() }}"
                data-html="true"
                data-content="<img src='{{ graph['img_src'] }}' width='600px' height='200px'>"
                data-placement="left">{{!helper.get_perfometer(s, metric.name)}}</a>
              %end
              %end
            </td>
            %else:
            <td>
              <a role="button" tabindex="0" >{{!helper.get_perfometer(s, metric.name)}}</a>
            </td>
            %end
          </tr>
          %end
          %end
          %end
          %end
          %end
        </tbody>
      </table>
    </div>
  </div>
</div>
