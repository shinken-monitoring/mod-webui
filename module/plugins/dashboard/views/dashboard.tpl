%rebase("layout", js=['js/jquery-ui-1.10.3.min.js', 'dashboard/js/widgets.js', 'dashboard/js/jquery.easywidgets.js'], css=['dashboard/css/dashboard.css'], title='Dashboard')

%from shinken.bin import VERSION
%helper = app.helper

<script type="text/javascript">
   /* We are saving the global context for the widgets */
   widget_context = 'dashboard';
</script>

<table class="table table-invisible table-condensed">
   <tbody>
      <tr>
         <td>
            <center><a href="/all?search=type:host isnot:UP" class="btn btn-sm">
               <i class="fa fa-4x fa-server font-darkgrey"></i>
               <span class="badger-title hosts"><i class="fa fa-plus" style="color: #ccc"></i>&nbsp;Hosts</span>
               %host_state = app.datamgr.get_percentage_hosts_state(user, False)
               <span class="badger-big badger-left">{{len(app.datamgr.get_hosts(user))}}</span>
               <span class="badger-big badger-right background-{{'critical' if host_state <= app.hosts_states_warning else 'warning' if host_state <= app.hosts_states_critical else 'ok'}}">{{host_state}}%</span>
            </a></center>
         </td>

         <td>
            <center><a href="/all?search=type:service isnot:OK" class="btn btn-sm">
               <i class="fa fa-4x fa-bars font-darkgrey"></i>
               <span class="badger-title services"><i class="fa fa-plus" style="color: #ccc"></i>&nbsp;Services</span>
               %service_state = app.datamgr.get_percentage_service_state(user, False)
               <span class="badger-big badger-left">{{len(app.datamgr.get_services(user))}}</span>
               <span class="badger-big badger-right background-{{'critical' if service_state <= app.services_states_warning else 'warning' if service_state <= app.services_states_critical else 'ok'}}">{{service_state}}%</span>
            </a></center>
         </td>

         %if app.prefs_module.is_available():
         %if len(widgets) > 0:
         <td>
         <center>
         <a id="widgets_show_panel" href="#widgets" class="btn btn-sm btn-success"><i class="fa fa-plus"></i> Add a new widget</a>
         </center>
         </td>
         %end
         %end

         <td>
            <center><a href="/problems" class="btn btn-sm">
               <i class="fa fa-4x fa-exclamation-triangle font-darkgrey"></i>
               <span class="badger-title itproblem"><i class="fa fa-plus" style="color: #ccc"></i>&nbsp;IT Problems</span>
               %overall_itproblem = app.datamgr.get_overall_it_state(user)
               <span title="Number of not acknowledged IT problems." class="badger-big background-{{'ok' if overall_itproblem == 0 else 'warning' if overall_itproblem == 1 else 'critical'}}">{{len(app.datamgr.get_problems(user, sorter=None))}}</span>
            </a></center>
         </td>

         <td>
            <center><a href="/impacts" class="btn btn-sm">
               <i class="fa fa-4x fa-flash font-darkgrey"></i>
               <span class="badger-title impacts"><i class="fa fa-plus" style="color: #ccc"></i>&nbsp;Impacts</span>
               %overall_state = app.datamgr.get_overall_state(user)
               <span title="Number of not acknownledged IT problems." class="badger-big background-{{'ok' if overall_state == 0 else 'warning' if overall_state == 1 else 'critical'}}">{{len(app.datamgr.get_impacts(user))}}</span>
            </a></center>
         </td>
      </tr>
   </tbody>
</table>

<!-- Widgets loading indicator -->
<div id="widgets_loading"></div>

%if app.prefs_module.is_available():
   %if len(widgets) == 0:
   <span id="center-button" class="col-sm-4 col-sm-offset-4 page-center" >
      <h3>You don't have any widget yet ...</h3>
      <!-- Button trigger widgets modal -->
      <a id="widgets_show_panel" href="#widgets" class="btn btn-block btn-success"><i class="fa fa-plus"></i>... add a new widget</a>
   </span>
   %end
%else:
   <div class="panel panel-default">
      <div class="panel-heading" style="padding-bottom: -10">
         <center>
            <h3>You do not have any user's preferences storage module installed.</h3>
            <h4 class="alert alert-danger">The Web UI dashboard and user's preferences will not be saved.</h4>
         </center>
         <hr/>
         <p>Installing and using a storage module is really easy, follow instructions in this documentation: <a href="https://github.com/shinken-monitoring/mod-webui/wiki/Installing-WebUI-storage-modules" target="_blank"> installing WebUI storage module</a></p>
      </div>
   </div>
%end

<!-- Widgets selection popover content -->
<div id="widgets" class="hidden">
   %for w in app.get_widgets_for('dashboard'):
      <button type="button" class="btn btn-block" style="margin-bottom: 2px;" data-toggle="collapse" data-target="#desc_{{w['widget_name']}}">
        {{w['widget_name']}}
      </button>

      <div id="desc_{{w['widget_name']}}" class='widget_desc collapse' >
         <div class="row">
            <span class="col-sm-6 hidden-sm hidden-xs">
               <img class="img-rounded" style="width:100%" src="{{w['widget_picture']}}" id="widget_desc_{{w['widget_name']}}"/>
            </span>
            <span>{{!w['widget_desc']}}</span>
         </div>
         <p class="add_button"><a class="btn btn-sm btn-success" href="javascript:AddNewWidget('{{w['base_uri']}}', null, 'widget-place-1');"> <i class="fa fa-chevron-left"></i> Add {{w['widget_name']}} widget</a></p>
      </div>
   %end
</div>

<div class="widget-place col-sm-12" id="widget-place-1"> </div>
<!-- /place-1 -->

<div class="widget-place col-sm-12" id="widget-place-2"> </div>
<!-- /place-2 -->

<div class="widget-place col-sm-12" id="widget-place-3"> </div>
<!-- /place-3 -->

<script type="text/javascript">
   $(function () {
      // Activate the popover ...
      $('#widgets_show_panel').popover({
         html : true,
         placement: 'bottom',
         title: 'Available widgets' + '<a class="close">×</a>',
         animation: true,
         content: function() {
            return $('#widgets').html();
         }
      });
      $('#widgets_show_panel').on('shown.bs.popover', function () {
         $('a.close').on('click', function () {
            $('#widgets_show_panel').popover('hide');
         });
      })

      // ... and load all widgets.
      %for w in widgets:
         %if 'base_url' in w and 'position' in w:
            AddWidget("{{!w['base_url']}}", {{!w['options_json']}}, "{{w['position']}}");
         %end
      %end
   });
</script>
