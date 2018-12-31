%user = app.get_user()

%rebase("layout", breadcrumb=[ ['System parameters', '/system-parameters'] ], title='System parameters')

<div class="panel panel-default">
   %if not configuration['_schedulers']:
   <div class="text-center">
     <h3>No system information is available.</h3>
   </div>
   %else:

   %if user.is_administrator():
   <div class="panel-group" style="margin: 10x">
      <div class="panel panel-default">
         <div class="panel-heading">
            <h4 class="panel-title">
               <a data-toggle="collapse" href="#collapse_commands"><i class="fa fa-paper-plane"></i> Change the configuration</a>
            </h4>
         </div>
         <div id="collapse_commands" class="panel-collapse collapse in">
            <table class="table table-condensed">
               <colgroup>
                  <col style="width: 60%" />
                  <col style="width: 40%" />
               </colgroup>
               <tbody class="small">
                  %include("_global_command.tpl", parameter="enable_event_handlers", title="Event handlers", command_enable='ENABLE_EVENT_HANDLERS', command_disable='DISABLE_EVENT_HANDLERS')
                  %include("_global_command.tpl", parameter="enable_notifications", title="Notifications", command_enable='ENABLE_NOTIFICATIONS', command_disable='DISABLE_NOTIFICATIONS')
                  %include("_global_command.tpl", parameter="enable_flap_detection", title="Flapping detection", command_enable='ENABLE_FLAP_DETECTION', command_disable='DISABLE_FLAP_DETECTION')

                  %include("_global_command.tpl", parameter="execute_host_checks", title="Hosts checks", command_enable='START_EXECUTING_HOST_CHECKS', command_disable='STOP_EXECUTING_HOST_CHECKS')
                  %include("_global_command.tpl", parameter="execute_service_checks", title="Services checks", command_enable='START_EXECUTING_SVC_CHECKS', command_disable='STOP_EXECUTING_SVC_CHECKS')
                  %include("_global_command.tpl", parameter="accept_passive_host_checks", title="Passive hosts checks", command_enable='START_ACCEPTING_PASSIVE_HOST_CHECKS', command_disable='STOP_ACCEPTING_PASSIVE_HOST_CHECKS')
                  %include("_global_command.tpl", parameter="accept_passive_service_checks", title="Passive services checks", command_enable='START_ACCEPTING_PASSIVE_SVC_CHECKS', command_disable='STOP_ACCEPTING_PASSIVE_SVC_CHECKS')

                  %include("_global_command.tpl", parameter="process_performance_data", title="Performance data", command_enable='ENABLE_PERFORMANCE_DATA', command_disable='DISABLE_PERFORMANCE_DATA')


                  %include("_global_command.tpl", parameter="check_host_freshness", title="Hosts freshness check", command_enable='ENABLE_HOST_FRESHNESS_CHECKS', command_disable='DISABLE_HOST_FRESHNESS_CHECKS')
                  %include("_global_command.tpl", parameter="check_service_freshness", title="Services freshness check", command_enable='ENABLE_SERVICE_FRESHNESS_CHECKS', command_disable='DISABLE_SERVICE_FRESHNESS_CHECKS')
               </tbody>
            </table>
         </div>
      </div>
   </div>
   %end

   %include("_dump_dict_panel.tpl", id="c1", title='Global configuration', dump_dict=configuration['_config'])

   %include("_dump_dict_panel.tpl", id="c2", title='Global macros', dump_dict=configuration['_macros'])

   %for config in configuration['_schedulers']:
   %include("_dump_dict_panel.tpl", id=config.get('id'), title="Scheduler %s" % config.get('instance_name', 'Unnamed'), dump_dict=config, icon='heartbeat')
   %end

   %end
</div>
