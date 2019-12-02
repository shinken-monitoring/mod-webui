%rebase("layout", js=['js/shinken-actions.js', 'js/jquery-ui-1.11.4.min.js', 'dashboard/js/widgets.js', 'dashboard/js/jquery.easywidgets.js', 'dashboard/js/actions.js'], css=['dashboard/css/dashboard.css'], title='Dashboard')

%from shinken.bin import VERSION
%user = app.get_user()
%helper = app.helper
%refresh = app.refresh

<script type="text/javascript">
   /* We are saving the global context for the widgets */
   widget_context = 'dashboard';
</script>

%s = app.datamgr.get_services_synthesis(user=user)
%h = app.datamgr.get_hosts_synthesis(user=user)

<table class="table table-invisible table-condensed">
   <tbody>
      <tr>
         <td class="text-center">
            <a href="/all?search=type:host isnot:UP" class="btn btn-sm">
               <i class="fas fa-4x fa-server font-darkgrey"></i>
               <span class="badger-title hosts">{{h['nb_elts']}} hosts</span>
               %host_state = app.datamgr.get_percentage_hosts_state(user, False)
               <span class="badger-big background-{{'critical' if host_state <= app.hosts_states_warning else 'warning' if host_state <= app.hosts_states_critical else 'ok'}}">{{host_state}}%</span>
            </a>
         </td>

         <td class="text-center">
            <a href="/all?search=type:service isnot:OK" class="btn btn-sm">
               <i class="fas fa-4x fa-hdd font-darkgrey"></i>
               <span class="badger-title services">{{s['nb_elts']}} services</span>
               %service_state = app.datamgr.get_percentage_service_state(user, False)
               <span class="badger-big background-{{'critical' if service_state <= app.services_states_warning else 'warning' if service_state <= app.services_states_critical else 'ok'}}">{{service_state}}%</span>
            </a>
         </td>

         <td class="text-center">
            <a href="/problems" class="btn btn-sm">
               <i class="fas fa-4x fa-exclamation-triangle font-darkgrey"></i>
               <span class="badger-title itproblem">IT Problems</span>
               %overall_itproblem = app.datamgr.get_overall_it_state(user)
               <span title="Number of not acknowledged IT problems." class="badger-big background-{{'ok' if overall_itproblem == 0 else 'warning' if overall_itproblem == 1 else 'critical'}}">{{h['nb_problems'] + s['nb_problems']}}</span>
            </a>
         </td>

         <td class="text-center">
            <a href="/impacts" class="btn btn-sm">
               <i class="fas fa-4x fa-bolt font-darkgrey"></i>
               <span class="badger-title impacts">Impacts</span>
               %overall_state = app.datamgr.get_overall_state(user)
               <span title="Number of not acknownledged Impacts." class="badger-big background-{{'ok' if overall_state == 0 else 'warning' if overall_state == 1 else 'critical'}}">{{len(app.datamgr.search_hosts_and_services(app.PROBLEMS_SEARCH_STRING + ' is:impact', user))}}</span>
            </a>
         </td>
      </tr>
   </tbody>
</table>

%if app.prefs_module.is_available():
%if not len(widgets):
   <div class="panel panel-default">
      <div class="panel-heading" style="padding-bottom: -10">
         <center>
            <h3>You don't have any widget yet ...</h3>
         </center>
         <hr/>
         <p>Use the <strong>widget selector</strong> to list all the available widgets.</p>
         <p>Select a proposed widget to view the widget description.</p>
         <p>Click the <strong>Add widget</strong> button on top of the description to include the widget in your dashboard.</p>
      </div>
   </div>
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

<!-- Widgets loading indicator -->
<div id="widgets_loading"></div>

<div class="container-fluid">
    <div class="row">
        <!-- /place-1 -->
        <div class="widget-place col-xs-12 col-sm-12 col-lg-4" id="widget-place-1"> </div>

        <!-- /place-2 -->
        <div class="widget-place col-xs-12 col-sm-12 col-lg-4" id="widget-place-2"> </div>

        <!-- /place-3 -->
        <div class="widget-place col-xs-12 col-sm-12 col-lg-4" id="widget-place-3"> </div>
    </div>
</div>

%if app.can_action():
%include("_dashboard_action-menu.tpl")
%end

<script type="text/javascript">
    var dashboard_logs = false;

    // Function called on each page refresh ... update graphs!
    function on_page_refresh(forced) {
        // Hosts data
        var hosts_count = parseInt($('#overall-hosts-states .hosts-all').data("count"));
        var hosts_problems = parseInt($('#overall-hosts-states .hosts-all').data("problems"));
        if (! sessionStorage.getItem("hosts_problems")) {
           sessionStorage.setItem("hosts_problems", hosts_problems);
        }
        var old_hosts_problems = Number(sessionStorage.getItem("hosts_problems"));
        if (dashboard_logs) console.debug("Hosts: ", hosts_count, hosts_problems, old_hosts_problems);

        // Services data
        var services_count = parseInt($('#overall-services-states .services-all').data("count"));
        var services_problems = parseInt($('#overall-services-states .services-all').data("problems"));
        if (! sessionStorage.getItem("services_problems")) {
           sessionStorage.setItem("services_problems", services_problems);
        }
        var old_services_problems = Number(sessionStorage.getItem("services_problems"));
        if (dashboard_logs) console.debug("services: ", services_count, services_problems, old_services_problems);

        // Sound alerting
        if (sessionStorage.getItem("sound_play") == '1') {
            if ((old_hosts_problems < hosts_problems) || (old_services_problems < services_problems)) {
               playAlertSound();
            }
        }
        if (old_hosts_problems < hosts_problems) {
            var message = (hosts_problems - old_hosts_problems) + " more " + ((hosts_problems - old_hosts_problems)==1 ? "hosts problem" : "hosts problems")
            %if refresh:
            message += " since last " + app_refresh_period + " seconds."
            %else:
            message += " since last refresh."
            %end
            alertify.log(message, "error", 5000);
            if (dashboard_logs) console.debug(message);
        }
        if (hosts_problems < old_hosts_problems) {
            var message = (old_hosts_problems - hosts_problems) + " fewer " + ((old_hosts_problems - hosts_problems)==1 ? "hosts problem" : "hosts problems")
            %if refresh:
            message += " since last " + app_refresh_period + " seconds."
            %else:
            message += " since last refresh."
            %end
            alertify.log(message, "success", 5000);
            if (dashboard_logs) console.debug(message);
        }
        sessionStorage.setItem("hosts_problems", hosts_problems);
        if (old_services_problems < services_problems) {
            var message = (services_problems - old_services_problems) + " more " + ((services_problems - old_services_problems)==1 ? "services problem" : "services problems")
            %if refresh:
            message += " since last " + app_refresh_period + " seconds."
            %else:
            message += " since last refresh."
            %end
            alertify.log(message, "error", 5000);
            if (dashboard_logs) console.debug(message);
        }
        if (services_problems < old_services_problems) {
            var message = (old_services_problems - services_problems) + " fewer " + ((old_services_problems - services_problems)==1 ? "services problem" : "services problems")
            %if refresh:
            message += " since last " + app_refresh_period + " seconds."
            %else:
            message += " since last refresh."
            %end
            alertify.log(message, "success", 5000);
            if (dashboard_logs) console.debug(message);
        }
        sessionStorage.setItem("services_problems", services_problems);
    }

   $(function () {
      on_page_refresh();

      // ... and load all widgets.
      %for w in widgets:
         %if 'base_url' in w and 'position' in w:
            AddWidget("{{!w['base_url']}}", {{!w['options_json']}}, "{{w['position']}}");
         %end
      %end
   });
</script>
