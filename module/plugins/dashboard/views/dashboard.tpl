%rebase("layout", js=['js/jquery-ui-1.10.3.min.js', 'dashboard/js/widgets.js', 'dashboard/js/jquery.easywidgets.js'], css=['dashboard/css/dashboard.css'], title='Dashboard', refresh=True)

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
            <a href="/all?search=type:host isnot:OK" class="btn btn-sm">
               <i class="fa fa-4x fa-server font-darkgrey"></i>
               <span class="badger-title hosts"><i class="fa fa-plus" style="color: #ccc"></i>&nbsp;Hosts</span>
               %host_state = app.datamgr.get_percentage_hosts_state(app.get_user_auth(), False)
               <span class="badger-big badger-left alert-inverse">{{len(app.datamgr.get_hosts(app.get_user_auth()))}}</span>
               <span class="badger-big badger-right alert-{{'critical' if host_state <= app.hosts_states_warning else 'warning' if host_state <= app.hosts_states_critical else 'ok'}}">{{host_state}}%</span>
            </a>
         </td>

         <td>
            <a href="/all?search=type:service isnot:OK" class="btn btn-sm">
               <i class="fa fa-4x fa-bars font-darkgrey"></i>
               <span class="badger-title services"><i class="fa fa-plus" style="color: #ccc"></i>&nbsp;Services</span>
               %service_state = app.datamgr.get_percentage_service_state(app.get_user_auth(), False)
               <span class="badger-big badger-left alert-inverse">{{len(app.datamgr.get_services(app.get_user_auth()))}}</span>
               <span class="badger-big badger-right alert-{{'critical' if service_state <= app.services_states_warning else 'warning' if service_state <= app.services_states_critical else 'ok'}}">{{service_state}}%</span>
            </a>
         </td>

         <td>
         %if len(widgets) > 0:
         <a id="widgets_show_panel" href="#widgets" class="btn btn-sm btn-success"><i class="fa fa-plus"></i> Add a new widget</a>
         %end
         </td>
       
         <td>
            <a href="/problems" class="btn btn-sm">
               <i class="fa fa-4x fa-exclamation-triangle font-darkgrey"></i>
               <span class="badger-title itproblem"><i class="fa fa-plus" style="color: #ccc"></i>&nbsp;IT Problems</span>
               %overall_itproblem = app.datamgr.get_overall_it_state(app.get_user_auth())
               <span title="Number of not acknowledged IT problems." class="badger-big alert-{{'ok' if overall_itproblem == 0 else 'warning' if overall_itproblem == 1 else 'critical'}}">{{app.datamgr.get_overall_it_problems_count(user, get_acknowledged=False)}}</span>
            </a>
         </td>

         <td>
            <a href="/impacts" class="btn btn-sm">
               <i class="fa fa-4x fa-flash font-darkgrey"></i>
               <span class="badger-title impacts"><i class="fa fa-plus" style="color: #ccc"></i>&nbsp;Impacts</span>
               %overall_state = app.datamgr.get_overall_state(app.get_user_auth())
               <span title="Number of not acknownledged IT problems." class="badger-big alert-{{'ok' if overall_state == 0 else 'warning' if overall_state == 1 else 'critical'}}">{{app.datamgr.get_overall_state_problems_count(user)}}</span>
            </a>
         </td>
      </tr>
   </tbody>
</table>

<div id="widgets_loading" class="pull-left"> <img src='/static/images/spinner.gif'> Loading widgets ...</div>

%# Go in the center of the page!
%if len(widgets) == 0:
<span id="center-button" class="col-sm-4 col-sm-offset-4 page-center" >
   <h3>You don't have any widget yet ...</h3>
   <!-- Button trigger widgets modal -->
   <a id="widgets_show_panel" data-toggle="popover" title="Popover title" href="#widgets" class="btn btn-block btn-success"><i class="fa fa-plus"></i>... add a new widget</a>
</span>
%end

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
         <p class="add_button"><a class="btn btn-sm btn-success" href="javascript:AddNewWidget('{{w['base_uri']}}', 'widget-place-1');"> <i class="fa fa-chevron-left"></i> Add {{w['widget_name']}} widget</a></p>
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
   // Activate the popover ...
   $(function () {
      $('#widgets_show_panel').popover({ 
         html : true,
         placement: 'bottom', 
         title: 'Available widgets', 
         content: function() {
            return $('#widgets').html();
         }
      });

      // ... and load all widgets.
      %for w in widgets:
         %if 'base_url' in w and 'position' in w:
            %uri = w['base_url'] + "?" + w['options_uri']
            AddWidget("{{!uri}}", "{{w['position']}}");
         %end
      %end
   });
</script>
