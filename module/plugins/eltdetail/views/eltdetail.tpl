%import time
%now = int(time.time())

%# If got no element, bailout
%if not elt:
%rebase("layout", title='Invalid element name')

Invalid element name

%else:

%helper = app.helper

%from shinken.macroresolver import MacroResolver

%elt_type = elt.__class__.my_type

%business_rule = False
%if elt.get_check_command().startswith('bp_rule'):
%business_rule = True
%end

%if elt_type=='host':
%breadcrumb = [ ['All hosts', '/hosts-groups'], [elt.host_name, '/host/'+elt.host_name] ]
%title = 'Host detail: ' + elt.host_name
%else:
%breadcrumb = [ ['All services', '/services-groups'], [elt.host.host_name, '/host/'+elt.host.host_name], [elt.service_description, '/service/'+elt.host.host_name+'/'+elt.service_description] ]
%title = 'Service detail: ' + elt.service_description+' on '+elt.host.host_name
%end

%js=['eltdetail/js/flot/jquery.flot.min.js', 'eltdetail/js/flot/jquery.flot.tickrotor.js', 'eltdetail/js/flot/jquery.flot.resize.min.js', 'eltdetail/js/flot/jquery.flot.pie.min.js', 'eltdetail/js/flot/jquery.flot.categories.min.js', 'eltdetail/js/flot/jquery.flot.time.min.js', 'eltdetail/js/flot/jquery.flot.stack.min.js', 'eltdetail/js/flot/jquery.flot.valuelabels.js',  'eltdetail/js/jquery.color.js', 'eltdetail/js/bootstrap-switch.min.js', 'eltdetail/js/graphs.js', 'eltdetail/js/custom_views.js', 'eltdetail/js/eltdetail.js']
%css=['eltdetail/css/bootstrap-switch.min.css', 'eltdetail/css/eltdetail.css']
%rebase("layout", js=js, css=css, breadcrumb=breadcrumb, title=title)

%# Main variables
%elt_name = elt.host_name if elt_type=='host' else elt.service_description+' on '+elt.host.host_name
%elt_display_name = elt.display_name if elt_type=='host' else elt.service_description

<div id="element">
   <!-- First row : tags and actions ... -->
   %if elt.action_url != '' or (elt_type=='host' and len(elt.get_host_tags()) != 0) or (elt_type=='service' and len(elt.get_service_tags()) != 0) or (elt_type=='host' and len(elt.hostgroups) > 0) or (elt_type=='service' and len(elt.servicegroups) > 0):
   <div>
      %if (elt_type=='host' and len(elt.hostgroups) > 0) or (elt_type=='service' and len(elt.servicegroups) > 0):
      <div class="btn-group pull-right">
         <button class="btn btn-primary btn-xs"><i class="fa fa-sitemap"></i> Groups</button>
         <button class="btn btn-primary btn-xs dropdown-toggle" data-toggle="dropdown"><span class="caret"></span></button>
         <ul class="dropdown-menu pull-right">
         %if elt_type=='host':
            %for hg in elt.hostgroups:
            <li>
            <a href="/hosts-group/{{hg.get_name()}}">{{hg.alias if hg.alias else hg.get_name()}}</a>
            </li>
            %end
         %else:
            %for sg in elt.servicegroups:
            <li>
            <a href="/services-group/{{sg.get_name()}}">{{sg.alias if sg.alias else sg.get_name()}}</a>
            </li>
            %end
         %end
         </ul>
      </div>
      <div class="pull-right">&nbsp;&nbsp;</div>
      %end
      %if elt.action_url != '':
      <div class="btn-group pull-right">
         %action_urls = elt.action_url.split('|')
         <button class="btn btn-info btn-xs"><i class="fa fa-external-link"></i> {{'Action' if len(action_urls) == 1 else 'Actions'}}</button>
         <button class="btn btn-info btn-xs dropdown-toggle" data-toggle="dropdown"><span class="caret"></span></button>
         <!-- Do not know why but MacroResolver sometimes throws an exception !!! -->
         <ul class="dropdown-menu pull-right">
            %for action_url in helper.get_element_actions_url(elt, default_title="Url", default_icon="globe", popover=True):
            <li>{{!action_url}}</li>
            %end
         </ul>
      </div>
      <div class="pull-right">&nbsp;&nbsp;</div>
      %end
      %if hasattr(elt, 'get_host_tags') and len(elt.get_host_tags()) != 0:
      <div class="btn-group pull-right">
         %i=0
         %for t in sorted(elt.get_host_tags()):
            <a href="/all?search=htag:{{t}}">
               %if app.tag_as_image:
               <img src="/tag/{{t.lower()}}" alt="{{t.lower()}}" =title="Tag: {{t.lower()}}" style="height: 24px"></img>
               %else:
               <button class="btn btn-default btn-xs"><i class="fa fa-tag"></i> {{t.lower()}}</button>
               %end
            </a>
            %i=i+1
         %end
      </div>
      %end
      %if hasattr(elt, 'get_service_tags') and len(elt.get_service_tags()) != 0:
      <div class="btn-group pull-right">
         %i=0
         %for t in sorted(elt.get_service_tags()):
            <a href="/all?search=stag:{{t}}">
               %if app.tag_as_image:
               <img src="/tag/{{t.lower()}}" alt="{{t.lower()}}" =title="Tag: {{t.lower()}}" style="height: 24px"></img>
               %else:
               <button class="btn btn-default btn-xs"><i class="fa fa-tag"></i> {{t.lower()}}</button>
               %end
            </a>
            %i=i+1
         %end
      </div>
      %end
   </div>
   %end

   <!-- Second row : host/service overview ... -->
   <div class="panel panel-default">
      <div class="panel-heading cursor" data-toggle="collapse" data-parent="#Overview" href="#collapseOverview">
         <h4 class="panel-title"><span class="caret"></span>&nbsp;Overview {{elt_name}} ({{elt.display_name if elt.display_name else elt.alias if elt.alias else 'none'}}) {{!helper.get_business_impact_text(elt.business_impact)}}</h4>
      </div>
  
      <div id="collapseOverview" class="panel-body panel-collapse collapse">
         %if elt_type=='host':
         <dl class="col-sm-6 dl-horizontal">
            <dt>Alias:</dt>
            <dd>{{elt.alias}}</dd>

            <dt>Address:</dt>
            <dd>{{elt.address}}</dd>

            <dt>Importance:</dt>
            <dd>{{!helper.get_business_impact_text(elt.business_impact, True)}}</dd>
         </dl>
        
         <dl class="col-sm-6 dl-horizontal">
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
            %for note_url in helper.get_element_notes_url(elt, default_title="Note", default_icon="tag", popover=True):
               <button class="btn btn-default btn-xs">{{! note_url}}</button>
            %end
            </dd>
         </dl>
         %else:
         <dl class="col-sm-6 dl-horizontal">
            <dt>Host:</dt>
            <dd>
               <a href="/host/{{elt.host.host_name}}" class="link">{{elt.host.host_name}} ({{elt.host.display_name if elt.host.display_name else elt.host.alias if elt.host.alias else 'none'}})</a>
            </dd>

            <dt>Importance:</dt>
            <dd>{{!helper.get_business_impact_text(elt.business_impact, True)}}</dd>
         </dl>
        
         <dl class="col-sm-6 dl-horizontal">
            <dt>Member of:</dt>
            %if len(elt.servicegroups) > 0:
            <dd>
            %i=0
            %for sg in elt.servicegroups:
            {{',' if i != 0 else ''}}
            <a href="/services-group/{{sg.get_name()}}" class="link">{{sg.alias if sg.alias else sg.get_name()}}</a>
            %end
            </dd>
            %else:
            <dd>(none)</dd>
            %end

            <dt>Notes: </dt>
            %if elt.notes != '' and elt.notes_url != '':
            <dd><a href="{{elt.notes_url}}" target=_blank>{{elt.notes}}</a></dd>
            %elif elt.notes == '' and elt.notes_url != '':
            <dd><a href="{{elt.notes_url}}" target=_blank>{{elt.notes_url}}</a></dd>
            %elif elt.notes != '' and elt.notes_url == '':
            <dd>{{elt.notes}}</dd>
            %else:
            <dd>(none)</dd>
            %end
         </dl>
         %end
      </div>
   </div>

   <!-- Third row : business impact alerting ... -->
   %if app.can_action() and elt.is_problem and elt.business_impact > 2 and not elt.problem_has_been_acknowledged:
   <div class="panel panel-default">
      <div class="panel-heading" style="padding-bottom: -10">
         <div class="aroundpulse pull-left" style="padding: 8px;">
            <span class="big-pulse pulse"></span>
            <i class="fa fa-3x fa-spin fa-gear"></i>
         </div>
         <div style="margin-left: 60px;">
         %disabled_ack = '' if elt.is_problem and not elt.problem_has_been_acknowledged else 'disabled'
         %disabled_fix = '' if elt.is_problem and elt.event_handler_enabled and elt.event_handler else 'disabled'
         <p class="alert alert-danger" style="margin-bottom:0">This element has an important impact on your business, you may <button name="bt-acknowledge" class="{{disabled_ack}} btn btn-primary btn-xs" data-toggle="tooltip" data-placement="bottom" title="Acknowledge this {{elt_type}} problem">acknowledge it</button> or <button name="bt-event-handler" class="{{disabled_fix}} btn btn-primary btn-xs" data-toggle="tooltip" data-placement="bottom" title="Launch the event handler for this {{elt_type}}">try to fix it</button>.</p>
         </div>
      </div>
   </div>
   %end
  
   <!-- Third row (bis) : business rule ... -->
   %if business_rule:
   <div class="panel panel-default">
      <div class="panel-heading" style="padding-bottom: -10">
         <div class="aroundpulse pull-left" style="padding: 8px;">
            <span class="big-pulse pulse"></span>
            <i class="fa fa-2x fa-university"></i>
         </div>
         <div style="margin-left: 60px;">
            <p class="alert alert-warning" style="margin-bottom:0">This element is a business rule.</p>
         </div>
      </div>
   </div>
   %end
  
   %if elt_type=='host':
   %synthesis = helper.get_synthesis(elt.services)
   %s = synthesis['services']
   %h = synthesis['hosts']
   <div class="panel panel-default">
     <div class="panel-body">
       <table class="table table-invisible table-condensed">
         <tbody>
           <tr>
             <td>
               <b>{{s['nb_elts']}} services:&nbsp;</b> 
             </td>

             %for state in 'ok', 'warning', 'critical', 'pending', 'unknown', 'ack', 'downtime':
             <td>
               %label = "%s <i>(%s%%)</i>" % (s['nb_' + state], s['pct_' + state])
               {{!helper.get_fa_icon_state_and_label(cls='service', state=state, label=label, disabled=(not s['nb_' + state]))}}
             </td>
             %end
           </tr>
         </tbody>
       </table>
     </div>
   </div>
   %end

   <!-- Fourth row : host/service information -->
   <div>
      <!-- Detail info box start -->
         <ul class="nav nav-tabs">
            %_go_active = 'active'
            %if 'custom_views' in params['tabs']:
            %for cvname in elt.custom_views:
               %cvconf = 'default'
               %if '/' in cvname:
                  %cvconf = cvname.split('/')[1]
                  %cvname = cvname.split('/')[0]
               %end
               <li class="{{_go_active}} cv_pane" data-name="{{cvname}}" data-conf="{{cvconf}}" data-element='{{elt.get_full_name()}}' id='tab-cv-{{cvname}}-{{cvconf}}'><a href="#cv{{cvname}}_{{cvconf}}" data-toggle="tab">{{cvname.capitalize()}}{{'/'+cvconf.capitalize() if cvconf!='default' else ''}}</a></li>
               %_go_active = ''
            %end
            %end

            %if 'information' in params['tabs']:
            <li class="{{_go_active}}"><a href="#information" data-toggle="tab">Information</a></li>
            %end
            %if 'impacts' in params['tabs']:
            <li><a href="#impacts" data-toggle="tab">{{'Services' if elt_type == 'host' else 'Impacts'}}</a></li>
            %end
            %if 'configuration' in params['tabs'] and elt.customs:
            <li><a href="#configuration" data-toggle="tab">Configuration</a></li>
            %end
            %if 'commands' in params['tabs'] and app.can_action():
            <li><a href="#commands" data-toggle="tab">Commands</a></li>
            %end
            
            %if 'comments' in params['tabs']:
            <li><a href="#comments" data-toggle="tab">Comments</a></li>
            %end
            %if 'downtimes' in params['tabs']:
            <li><a href="#downtimes" data-toggle="tab">Downtimes</a></li>
            %end
            
            %if 'timeline' in params['tabs']:
            <li class="timeline_pane"><a href="#timeline" data-toggle="tab">Timeline</a></li>
            %end
            %if 'metrics' in params['tabs']:
            <li><a href="#metrics" data-toggle="tab">Metrics</a></li>
            %end
            %if 'graphs' in params['tabs']:
            <li><a href="#graphs" data-toggle="tab">Graphs</a></li>
            %end
            %if 'depgraph' in params['tabs']:
            <li><a href="#depgraph" data-toggle="tab">Impact graph</a></li>
            %end
            %if 'history' in params['tabs'] and app.logs_module:
            <li><a href="#history" data-toggle="tab">History</a></li>
            %end
            %if 'availability' in params['tabs'] and app.logs_module:
            <li><a href="#availability" data-toggle="tab">Availability</a></li>
            %end
            %if 'helpdesk' in params['tabs'] and app.helpdesk_module:
            <li><a href="#helpdesk" data-toggle="tab">Helpdesk</a></li>
            %end
         </ul>
         
         <div class="tab-content">
            <!-- Tab custom views -->
            %if 'custom_views' in params['tabs']:
            %_go_active = 'active'
            %_go_fadein = 'in'
            %cvs = []
            %[cvs.append(item) for item in elt.custom_views if item not in cvs]
            %for cvname in cvs:
               %cvconf = 'default'
               %if '/' in cvname:
                  %cvconf = cvname.split('/')[1]
                  %cvname = cvname.split('/')[0]
               %end
               <div class="tab-pane fade {{_go_active}} {{_go_fadein}}" data-name="{{cvname}}" data-conf="{{cvconf}}" data-element="{{elt.get_full_name()}}" id="cv{{cvname}}_{{cvconf}}">
                  <div class="panel panel-default">
                     <div class="panel-body">
                        <span class="alert alert-error">Sorry, I cannot load the {{cvname}}/{{cvconf}} view!</span>
                     </div>
                  </div>
               </div>
               %_go_active = ''
               %_go_fadein = ''
            %end
            %end
            <!-- Tab custom views end -->

            <!-- Tab Information start-->
            %if 'information' in params['tabs']:
            <div class="tab-pane fade {{_go_active}} {{_go_fadein}}" id="information">
               <div class="panel panel-default">
                  <div class="panel-body">
                     <div class="col-lg-6">
                        <table class="table table-condensed">
                           <colgroup>
                              <col style="width: 40%" />
                              <col style="width: 60%" />
                           </colgroup>
                           <thead>
                              <tr>
                                 <th colspan="2">Status:</td>
                              </tr>
                           </thead>
                           <tbody style="font-size:x-small;">
                              <tr>
                                 <td><strong>Status:</strong></td>
                                 <td>
                                    {{! helper.get_fa_icon_state(obj=elt, label='title')}}
                                 </td>
                              </tr>
                              <tr>
                                 <td><strong>Since:</strong></td>
                                 <td>
                                    {{! helper.print_duration(elt.last_state_change, just_duration=True, x_elts=2)}}
                                 </td>
                              </tr>
                           </tbody>
                        </table>
                   
                        <table class="table table-condensed table-nowrap">
                           <colgroup>
                              <col style="width: 40%" />
                              <col style="width: 60%" />
                           </colgroup>
                           <thead>
                              <tr>
                                 <th colspan="2">Last check:</td>
                              </tr>
                           </thead>
                           <tbody style="font-size:x-small;">
                              <tr>
                                 <td><strong>Last Check:</strong></td>
                                 <td><span class="popover-dismiss" data-html="true" data-toggle="popover" data-trigger="hover" data-placement="bottom" data-content="Last check was at {{time.asctime(time.localtime(elt.last_chk))}}">was {{helper.print_duration(elt.last_chk)}}</span></td>
                              </tr>
                              <tr>
                                 <td><strong>Output:</strong></td>
                                 <td class="popover-dismiss" 
                                       data-html="true" data-toggle="popover" data-trigger="hover" data-placement="bottom" 
                                       data-title="{{elt.get_full_name()}} check output" 
                                       data-content=" {{elt.output}}{{'<br/>'+elt.long_output.replace('\n', '<br/>') if elt.long_output else ''}}"
                                       >
                                  {{!helper.strip_html_output(elt.output[:app.max_output_length]) if app.allow_html_output else elt.output[:app.max_output_length]}}
                                 </td>
                              </tr>
                              <tr>
                                 <td><strong>Performance data:</strong></td>
                                 <td class="popover-dismiss ellipsis" 
                                       data-html="true" data-toggle="popover" data-trigger="hover" data-placement="bottom" 
                                       data-title="{{elt.get_full_name()}} performance data" 
                                       data-content=" {{elt.perf_data if len(elt.perf_data) > 0 else '(none)'}}"
                                       >
                                  {{elt.perf_data if len(elt.perf_data) > 0 else '(none)'}}
                                 </td>
                              </tr>
                              <tr>
                                 <td><strong>Check latency / duration:</strong></td>
                                 <td>
                                    {{'%.2f' % elt.latency}} / {{'%.2f' % elt.execution_time}} seconds
                                 </td>
                              </tr>
                              
                              <tr>
                                 <td><strong>Last State Change:</strong></td>
                                 <td>{{time.asctime(time.localtime(elt.last_state_change))}}</td>
                              </tr>
                              <tr>                             
                                 <td><strong>Current Attempt:</strong></td>
                                 <td>{{elt.attempt}}/{{elt.max_check_attempts}} ({{elt.state_type}} state)</td>
                              </tr>
                              <tr>     
                                 <td><strong>Next Active Check:</strong></td>
                                 <td><span class="popover-dismiss" data-html="true" data-toggle="popover" data-trigger="hover" data-placement="bottom" data-content="Next active check at {{time.asctime(time.localtime(elt.next_chk))}}">{{helper.print_duration(elt.next_chk)}}</span></td>
                              </tr>
                           </tbody>
                        </table>
                              
                        <table class="table table-condensed">
                           <colgroup>
                              <col style="width: 40%" />
                              <col style="width: 60%" />
                           </colgroup>
                           <thead>
                              <tr>
                                 <th colspan="2">Checks configuration:</td>
                              </tr>
                           </thead>
                           <tbody style="font-size:x-small;">
                              %if hasattr(elt, "check_period") and hasattr(elt.check_period, "get_name"):
                              <tr>
                                 <td><strong>Check period:</strong></td>
                                 %tp=app.datamgr.get_timeperiod(elt.check_period.get_name())
                                 <td name="check_period" class="popover-dismiss" 
                                       data-html="true" data-toggle="popover" data-trigger="hover" data-placement="left" 
                                       data-title='{{tp.alias if hasattr(tp, "alias") else tp.timeperiod_name}}' 
                                       data-content='{{!helper.get_timeperiod_html(tp)}}'
                                       >
                                 {{! helper.get_on_off(elt.check_period.is_time_valid(now), 'Is element check period currently active?')}}
                                 <a href="/timeperiods">{{elt.check_period.alias}}</a>
                                 </td>
                              </tr>
                              %else:
                              <tr>
                                 <td><strong>No defined check period!</strong></td>
                                 <td></td>
                              </tr>
                              %end
                              %if elt.maintenance_period is not None:
                              <tr>
                                 <td><strong>Maintenance period:</strong></td>
                                 <td name="maintenance_period" class="popover-dismiss" 
                                       data-html="true" data-toggle="popover" data-trigger="hover" data-placement="left" 
                                       data-title='{{tp.alias if hasattr(tp, "alias") else tp.timeperiod_name}}'
                                       data-content='{{!helper.get_timeperiod_html(tp)}}'
                                       >
                                 {{! helper.get_on_off(elt.maintenance_period.is_time_valid(now), 'Is element maintenance period currently active?')}}
                                 <a href="/timeperiods">{{elt.maintenance_period.alias}}</a>
                                 </td>
                              </tr>
                              %end
                              <tr>
                                 <td><strong>Check command:</strong></td>
                                 <td>
                                    <a href="/commands#{{elt.get_check_command()}}">{{elt.get_check_command()}}</a>
                                 </td>
                                 <td>
                                 </td>
                              </tr>
                              <tr>
                                 <td><strong>Active checks:</strong></td>
                                 <td>
                                    <input type="checkbox" {{'checked' if elt.active_checks_enabled else ''}} 
                                          class="switch" data-size="mini" data-on-color="success" data-off-color="danger"
                                          data-type="action" action="toggle-active-checks" 
                                          data-element="{{helper.get_uri_name(elt)}}" data-value="{{elt.active_checks_enabled}}"
                                          >
                                 </td>
                              </tr>
                              %if (elt.active_checks_enabled):
                              <tr>
                                 <td><strong>Check interval:</strong></td>
                                 <td>{{elt.check_interval}} minutes</td>
                              </tr>
                              <tr>
                                 <td><strong>Retry interval:</strong></td>
                                 <td>{{elt.retry_interval}} minutes</td>
                              </tr>
                              <tr>
                                 <td><strong>Max check attempts:</strong></td>
                                 <td>{{elt.max_check_attempts}}</td>
                              </tr>
                              %end
                              <tr>
                                 <td><strong>Passive checks:</strong></td>
                                 <td>
                                    <input type="checkbox" {{'checked' if elt.passive_checks_enabled else ''}} 
                                          class="switch" data-size="mini" data-on-color="success" data-off-color="danger"
                                          data-type="action" action="toggle-passive-checks"
                                          data-element="{{helper.get_uri_name(elt)}}" data-value="{{elt.passive_checks_enabled}}"
                                          >
                                 </td>
                              </tr>
                              %if (elt.passive_checks_enabled):
                              <tr>
                                 <td><strong>Freshness check:</strong></td>
                                 <td>{{! helper.get_on_off(elt.check_freshness, 'Is freshness check enabled?')}}</td>
                              </tr>
                              %if (elt.check_freshness):
                              <tr>
                                 <td><strong>Freshness threshold:</strong></td>
                                 <td>{{elt.freshness_threshold}} seconds</td>
                              </tr>
                              %end
                              %end
                              <tr>
                                 <td><strong>Process performance data:</strong></td>
                                 <td>{{! helper.get_on_off(elt.process_perf_data, 'Is perfdata process enabled?')}}</td>
                              </tr>
                           </tbody>
                        </table>
                        <table class="table table-condensed">
                           <colgroup>
                              <col style="width: 40%" />
                              <col style="width: 60%" />
                           </colgroup>
                           <thead>
                              <tr>
                                 <th colspan="2">Event handler:</td>
                              </tr>
                           </thead>
                           <tbody style="font-size:x-small;">
                              <tr>
                                 <td><strong>Event handler enabled:</strong></td>
                                 <td>
                                    <input type="checkbox" {{'checked' if elt.event_handler_enabled else ''}}
                                          class="switch" data-size="mini" data-on-color="success" data-off-color="danger"
                                          data-type="action" action="toggle-event-handler"
                                          data-element="{{helper.get_uri_name(elt)}}" data-value="{{elt.event_handler_enabled}}"
                                          >
                                 </td>
                              </tr>
                              %if elt.event_handler_enabled and elt.event_handler:
                              <tr>
                                 <td><strong>Event handler:</strong></td>
                                 <td>
                                    <a href="/commands#{{elt.event_handler.get_name()}}">{{ elt.event_handler.get_name() }}</a>
                                 </td>
                              </tr>
                              %end
                              %if elt.event_handler_enabled and not elt.event_handler:
                              <tr>
                                 <td></td>
                                 <td><strong>No event handler defined!</strong></td>
                              </tr>
                              %end
                           </tbody>
                        </table>
                     </div>
                     <div class="col-lg-6">
                        <table class="table table-condensed">
                           <colgroup>
                              <col style="width: 40%" />
                              <col style="width: 60%" />
                           </colgroup>
                           <thead>
                              <tr>
                                 <th colspan="2">Flapping detection:</td>
                              </tr>
                           </thead>
                           <tbody style="font-size:x-small;">
                              <tr>
                                 <td><strong>Flapping detection:</strong></td>
                                 <td>
                                    <input type="checkbox" {{'checked' if elt.flap_detection_enabled else ''}}
                                          class="switch" data-size="mini" data-on-color="success" data-off-color="danger"
                                          data-type="action" action="toggle-flap-detection"
                                          data-element="{{helper.get_uri_name(elt)}}" data-value="{{elt.flap_detection_enabled}}"
                                          >
                                 </td>
                              </tr>
                              %if elt.flap_detection_enabled:
                              <tr>
                                 <td><strong>Options:</strong></td>
                                 <td>{{', '.join(elt.flap_detection_options)}}</td>
                              </tr>
                              <tr>
                                 <td><strong>Low threshold:</strong></td>
                                 <td>{{elt.low_flap_threshold}}</td>
                              </tr>
                              <tr>
                                 <td><strong>High threshold:</strong></td>
                                 <td>{{elt.high_flap_threshold}}</td>
                              </tr>
                              %end
                           </tbody>
                        </table>

                        %if len(elt.stalking_options) > 0 and elt.stalking_options[0]:
                        <table class="table table-condensed">
                           <colgroup>
                              <col style="width: 40%" />
                              <col style="width: 60%" />
                           </colgroup>
                           <thead>
                              <tr>
                                 <th colspan="2">Stalking options:</td>
                              </tr>
                           </thead>
                           <tbody style="font-size:x-small;">
                              <tr>
                                 <td><strong>Options:</strong></td>
                                 <td>{{', '.join(elt.stalking_options)}}</td>
                              </tr>
                           </tbody>
                        </table>
                        %end

                        <table class="table table-condensed">
                           <colgroup>
                              <col style="width: 40%" />
                              <col style="width: 60%" />
                           </colgroup>
                           <thead>
                              <tr>
                                 <th colspan="2">Notifications:</td>
                              </tr>
                           </thead>
                           <tbody style="font-size:x-small;">
                              <tr>
                                 <td><strong>Notifications:</strong></td>
                                 <td>
                                    <input type="checkbox" {{'checked' if elt.notifications_enabled else ''}} 
                                          class="switch" data-size="mini" data-on-color="success" data-off-color="danger"
                                          data-type="action" action="toggle-notifications"
                                          data-element="{{helper.get_uri_name(elt)}}" data-value="{{elt.notifications_enabled}}"
                                          >
                                 </td>
                              </tr>
                              %if elt.notifications_enabled and elt.notification_period:
                              <tr>
                                 <td><strong>Notification period:</strong></td>
                                 %tp=app.datamgr.get_timeperiod(elt.notification_period.get_name())
                                 <td name="notification_period" class="popover-dismiss" data-html="true" data-toggle="popover" data-trigger="hover" data-placement="left" 
                                       data-title='{{tp.alias if hasattr(tp, "alias") else tp.timeperiod_name}}' 
                                       data-content='{{!helper.get_timeperiod_html(tp)}}'>
                                    {{! helper.get_on_off(elt.notification_period.is_time_valid(now), 'Is element notification period currently active?')}}
                                    <a href="/timeperiods">{{elt.notification_period.alias}}</a>
                                 </td>
                              </tr>
                              <tr>
                                 %if elt_type=='host':
                                    %message = {}
                                    %# [d,u,r,f,s,n]
                                    %message['d'] = 'Down'
                                    %message['u'] = 'Unreachable'
                                    %message['r'] = 'Recovery'
                                    %message['f'] = 'Flapping'
                                    %message['s'] = 'Downtimes'
                                    %message['n'] = 'None'
                                 %else:
                                    %message = {}
                                    %# [w,u,c,r,f,s,n]
                                    %message['w'] = 'Warning'
                                    %message['u'] = 'Unknown'
                                    %message['c'] = 'Critical'
                                    %message['r'] = 'Recovery'
                                    %message['f'] = 'Flapping'
                                    %message['s'] = 'Downtimes'
                                    %message['n'] = 'None'
                                 %end
                                 <td><strong>Notification options:</strong></td>
                                 <td>
                                 %for m in message:
                                    {{! helper.get_on_off(m in elt.notification_options, '', message[m]+'&nbsp;')}}
                                 %end
                                 </td>
                              </tr>
                              <tr>
                                 <td><strong>Last notification:</strong></td>
                                 <td>{{helper.print_date(elt.last_notification)}} (notification {{elt.current_notification_number}})</td>
                              </tr>
                              <tr>
                                 <td><strong>Notification interval:</strong></td>
                                 <td>{{elt.notification_interval}} mn</td>
                              </tr>
                              <tr>
                                 <td><strong>Contacts:</strong></td>
                                 %contacts=[]
                                 %[contacts.append('<a href="/contact/'+item.contact_name+'">'+item.alias+'</a>' if item.alias else item.get_name()) for item in elt.contacts if item not in contacts]
                                 <td>{{!', '.join(contacts)}}</td>
                              </tr>
                              <tr>
                                 <td><strong>Contacts groups:</strong></td>
                                 <td></td>
                              </tr>
                              %i=0
                              %for (group) in elt.contact_groups: 
                              <tr>
                                 %cg = app.datamgr.get_contactgroup(group)
                                 <td style="text-align: right; font-style: italic;"><strong>{{cg.alias if cg.alias else cg.get_name()}}</strong></td>
                                 %contacts=[]
                                 %[contacts.append('<a href="/contact/'+item.contact_name+'">'+item.alias+'</a>' if item.alias else item.get_name()) for item in cg.members if item not in contacts]
                                 <td>{{!', '.join(contacts)}}</td>
                                 %i=i+1
                              </tr>
                              %end
                              %end
                           </tbody>
                        </table>
                     </div>
                  </div>
               </div>
            </div>
            %end
            <!-- Tab Information end -->

             <!-- Tab Impacts start -->
            %if 'impacts' in params['tabs']:
            <div class="tab-pane fade" id="impacts">
               <div class="panel panel-default">
                  <div class="panel-body">
                     <div class="{{'col-lg-6'}} if elt_type =='host' else 'col-lg-12'">
                        %displayed_services=False
                        <!-- Show our father dependencies if we got some -->
                        %if len(elt.parent_dependencies) > 0:
                        <h4>Root cause:</h4>
                        {{!helper.print_business_rules(app.datamgr.get_business_parents(elt), source_problems=elt.source_problems)}}
                        %end

                        <!-- If we are an host and not a problem, show our services -->
                        %if elt_type=='host' and not elt.is_problem:
                        %if len(elt.services) > 0:
                        %displayed_services=True
                        <h4>My services:</h4>
                        <div class="services-tree">
                          {{!helper.print_aggregation_tree(helper.get_host_service_aggregation_tree(elt, app), helper.get_html_id(elt), expanded=False, max_sons=3)}}
                        </div>
                        %elif len(elt.parent_dependencies) == 0:
                        <h4>No services!</h4>
                        %end
                        %end #of the only host part

                        <!-- If we are a root problem and got real impacts, show them! -->
                        %if elt.is_problem and len(elt.impacts) != 0:
                        <h4>My impacts:</h4>
                        <div class='host-services'>
                           %s = ""
                           <ul>
                           %for svc in helper.get_impacts_sorted(elt):
                              %s += "<li>"
                              %s += helper.get_fa_icon_state(svc)
                              %s += helper.get_link(svc, short=True)
                              %s += "(" + helper.get_business_impact_text(svc.business_impact) + ")"
                              %s += """ is <span class="font-%s"><strong>%s</strong></span>""" % (svc.state.lower(), svc.state)
                              %s += " since %s" % helper.print_duration(svc.last_state_change, just_duration=True, x_elts=2)
                              %s += "</li>"
                           %end
                           {{!s}}
                           </ul>
                        </div>
                        %# end of the 'is problem' if
                        %end
                     </div>
                     %if elt_type=='host':
                     <div class="col-lg-6">
                        %if not displayed_services:
                        <!-- Show our own services  -->
                        <h4>My services:</h4>
                        <div>
                          {{!helper.print_aggregation_tree(helper.get_host_service_aggregation_tree(elt, app), helper.get_html_id(elt))}}
                        </div>
                        %end
                     </div>
                     %end
                  </div>
               </div>
            </div>
            %end
            <!-- Tab Impacts end -->

           <!-- Tab Configuration start -->
            %if 'configuration' in params['tabs'] and elt.customs:
            <div class="tab-pane fade" id="configuration">
               <div class="panel panel-default">
                  <div class="panel-body">
                     <table class="table table-condensed table-bordered">
                        <colgroup>
                           %if app.can_action():
                           <col style="width: 30%" />
                           <col style="width: 60%" />
                           <col style="width: 10%" />
                           %else:
                           <col style="width: 40%" />
                           <col style="width: 60%" />
                           %end
                        </colgroup>
                        <thead>
                           <tr>
                              <th colspan="3">Customs:</td>
                           </tr>
                        </thead>
                        <tbody style="font-size:x-small;">
                        %for var in sorted(elt.customs):
                           <tr>
                              <td>{{var}}</td>
                              <td>{{elt.customs[var]}}</td>
                              %if app.can_action():
                              <td>
                                 <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm" 
                                       data-type="action" action="change-variable"
                                       data-toggle="tooltip" data-placement="bottom" title="Change a custom variable for this {{elt_type}}"
                                       data-element="{{helper.get_uri_name(elt)}}" data-variable="{{var}}" data-value="{{elt.customs[var]}}"
                                       >
                                    <i class="fa fa-gears"></i> Change 
                                 </button>
                              </td>
                              %end
                           </tr>
                        %end
                        </tbody>
                     </table>
                  </div>
               </div>
            </div>
            %end
            <!-- Tab Configuration end -->
            
            <!-- Tab Commands start -->
            %if 'commands' in params['tabs'] and app.can_action():
            <div class="tab-pane fade" id="commands">
               <div class="panel panel-default">
                  <div class="panel-body">

                     <div class="col-sm-6">
                        <table class="table table-condensed">
                           <colgroup>
                              <col style="width: 60%" />
                              <col style="width: 40%" />
                           </colgroup>
                           <thead>
                              <tr>
                                 <th colspan="2">Toggle current:</td>
                              </tr>
                           </thead>
                           <tbody>
                              <tr>
                                 <td><strong>Active checks enabled:</strong></td>
                                 <td>
                                    <input type="checkbox" class="switch" {{'checked' if elt.active_checks_enabled else ''}} 
                                          data-type="action" action="toggle-active-checks" 
                                          data-element="{{helper.get_uri_name(elt)}}" data-value="{{elt.active_checks_enabled}}"
                                          >
                                 </td>
                              </tr>
                              <tr>
                                 <td><strong>Passive checks enabled:</strong></td>
                                 <td>
                                    <input type="checkbox" class="switch" {{'checked' if elt.passive_checks_enabled else ''}} 
                                          data-type="action" action="toggle-passive-checks"
                                          data-element="{{helper.get_uri_name(elt)}}" data-value="{{elt.passive_checks_enabled}}"
                                          >
                                 </td>
                              </tr>
                              <tr>
                                 <td><strong>Notifications enabled:</strong></td>
                                 <td>
                                    <input type="checkbox" class="switch" {{'checked' if elt.notifications_enabled else ''}} 
                                          data-type="action" action="toggle-notifications"
                                          data-element="{{helper.get_uri_name(elt)}}" data-value="{{elt.notifications_enabled}}"
                                          >
                                 </td>
                              </tr>
                              <tr>
                                 <td><strong>Event handler enabled:</strong></td>
                                 <td>
                                    <input type="checkbox" class="switch" {{'checked' if elt.event_handler_enabled else ''}}
                                          data-type="action" action="toggle-event-handler"
                                          data-element="{{helper.get_uri_name(elt)}}" data-value="{{elt.event_handler_enabled}}"
                                          >
                                 </td>
                              </tr>
                              <tr>
                                 <td><strong>Flapping detection enabled:</strong></td>
                                 <td>
                                    <input type="checkbox" class="switch" {{'checked' if elt.flap_detection_enabled else ''}} 
                                          data-type="action" action="toggle-flap-detection"
                                          data-element="{{helper.get_uri_name(elt)}}" data-value="{{elt.flap_detection_enabled}}"
                                          >
                                 </td>
                              </tr>
                           </tbody>
                        </table>
                     </div>
                  </div>
               </div>
            </div>
            %end
            <!-- Tab Commands end -->

            <!-- Tab Comments start -->
            %if 'comments' in params['tabs']:
            <div class="tab-pane fade" id="comments">
               <div class="panel panel-default">
                  <div class="panel-body">
                     %if len(elt.comments) > 0:
                     <table class="table table-condensed table-hover">
                        <thead>
                           <tr>
                              <th>Author</th>
                              <th>Comment</th>
                              <th>Date</th>
                              <th></th>
                           </tr>
                        </thead>
                        <tbody>
                        %for c in elt.comments:
                           <tr>
                              <td>{{c.author}}</td>
                              <td>{{c.comment}}</td>
                              <td>{{helper.print_date(c.entry_time)}}</td>
                              <td>
                                 <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm" 
                                       data-type="action" action="delete-comment"
                                       data-toggle="tooltip" data-placement="bottom" title="Delete the comment '{{c.id}}' for this {{elt_type}}"
                                       data-element="{{helper.get_uri_name(elt)}}" data-comment="{{c.id}}"
                                       >
                                    <i class="fa fa-trash-o"></i> 
                                 </button>
                              </td>
                           </tr>
                        %end
                        </tbody>
                     </table>

                     %else:
                     <div class="alert alert-info">
                        <p class="font-blue">No comments available.</p>
                     </div>
                     %end
                     
                     <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm" 
                           data-type="action" action="add-comment"
                           data-toggle="tooltip" data-placement="bottom" title="Add a comment for this {{elt_type}}"
                           data-element="{{helper.get_uri_name(elt)}}" 
                           >
                        <i class="fa fa-plus"></i> Add a comment
                     </button>
                     %if len(elt.comments) > 0:
                     <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm" 
                           data-type="action" action="delete-comments"
                           data-toggle="tooltip" data-placement="bottom" title="Delete all the comments of this {{elt_type}}"
                           data-element="{{helper.get_uri_name(elt)}}" 
                           >
                        <i class="fa fa-minus"></i> Delete all comments
                     </button>
                     %end
                  </div>
                  
               </div>
            </div>
            %end
            <!-- Tab Comments end -->

            <!-- Tab Downtimes start -->
            %if 'downtimes' in params['tabs']:
            <div class="tab-pane fade" id="downtimes">
               <div class="panel panel-default">
                  <div class="panel-body">
                     %if len(elt.downtimes) > 0:
                     <table class="table table-condensed table-hover">
                        <thead>
                           <tr>
                              <th>Author</th>
                              <th>Reason</th>
                              <th>Period</th>
                              <th></th>
                           </tr>
                        </thead>
                        <tbody>
                        %for dt in elt.downtimes:
                           <tr>
                              <td>{{dt.author}}</td>
                              <td>{{dt.comment}}</td>
                              <td>{{helper.print_date(dt.start_time)}} - {{helper.print_date(dt.end_time)}}</td>
                              <td>
                                 <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm" 
                                       data-type="action" action="delete-downtime"
                                       data-toggle="tooltip" data-placement="bottom" title="Delete the downtime '{{dt.id}}' for this {{elt_type}}"
                                       data-element="{{helper.get_uri_name(elt)}}" data-downtime="{{dt.id}}"
                                       >
                                    <i class="fa fa-trash-o"></i> 
                                 </button>
                              </td>
                           </tr>
                        %end
                        </tbody>
                     </table>
                     %else:
                     <div class="alert alert-info">
                        <p class="font-blue">No downtimes available.</p>
                     </div>
                     %end
                  
                     <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm" 
                           data-type="action" action="schedule-downtime"
                           data-toggle="tooltip" data-placement="bottom" title="Schedule a downtime for this {{elt_type}}"
                           data-element="{{helper.get_uri_name(elt)}}" 
                           >
                        <i class="fa fa-plus"></i> Schedule a downtime
                     </button>
                     %if len(elt.downtimes) > 0:
                     <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm" 
                           data-type="action" action="delete-downtimes"
                           data-toggle="tooltip" data-placement="bottom" title="Delete all the downtimes of this {{elt_type}}"
                           data-element="{{helper.get_uri_name(elt)}}" 
                           >
                        <i class="fa fa-minus"></i> Delete all downtimes
                     </button>
                     %end

                     </div>
                  </div>
               </div>
            %end
            <!-- Tab Downtimes end -->

            <!-- Tab Timeline start -->
            %if 'timeline' in params['tabs']:
            <div class="tab-pane fade" id="timeline">
               <div class="panel panel-default">
                  <div class="panel-body">
                     <div id="inner_timeline" data-element='{{elt.get_full_name()}}'>
                        <span class="alert alert-error">Sorry, I cannot load the timeline graph!</span>
                     </div>
                  </div>
               </div>
            </div>
            %end
            <!-- Tab Timeline end -->

            <!-- Tab Metrics start -->
            %if 'metrics' in params['tabs']:
            %from shinken.misc.perfdata import PerfDatas
            <div class="tab-pane fade" id="metrics">
               <div class="panel panel-default">
                  <div class="panel-body">
                     <table class="table table-condensed">
                        <thead>
                           <tr>
                              %if elt_type=='host' and elt.services:
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
                        %if elt_type=='host' and elt.services:
                        %for s in elt.services:
                           %service_line = True
                           %perfdatas = PerfDatas(s.perf_data)
                           %if perfdatas:
                           %for metric in sorted(perfdatas, key=lambda metric: metric.name):
                           %if metric.name and metric.value:
                           <tr>
                              <td><strong>{{s.get_name() if service_line else ''}}</strong></td>
                              %service_line = False
                              <td><strong>{{metric.name}}</strong></td>
                              <td>{{metric.value}}</td>
                              <td>{{metric.warning if metric.warning else ''}}</td>
                              <td>{{metric.critical if metric.critical else ''}}</td>
                              <td>{{metric.min if metric.min else ''}}</td>
                              <td>{{metric.max if metric.max else ''}}</td>
                              <td>{{metric.uom if metric.uom else ''}}</td>
                              
                              <td>
                                 %# Graphs
                                 %import time
                                 %import re
                                 %now = time.time()
                                 %graphs = app.get_graph_uris(s, now-4*3600, now)
                                 %for graph in graphs:
                                    %if re.findall('\\b'+metric.name+'\\b', graph['img_src']):
                                       <a role="button" tabindex="0" data-toggle="popover" title="{{ s.get_full_name() }}" data-html="true" data-content="<img src='{{ graph['img_src'] }}' width='600px' height='200px'>" data-trigger="hover" data-placement="left">{{!helper.get_perfometer(s, metric.name)}}</a>
                                    %end
                                 %end
                              </td>
                           </tr>
                           %end
                           %end
                           %end
                        %end
                        %end
                        %if elt_type=='service':
                           %perfdatas = PerfDatas(elt.perf_data)
                           %if perfdatas:
                           %for metric in sorted(perfdatas, key=lambda metric: metric.name):
                           %if metric.name and metric.value:
                           <tr>
                              <td><strong>{{metric.name}}</strong></td>
                              <td>{{metric.value}}</td>
                              <td>{{metric.warning if metric.warning else ''}}</td>
                              <td>{{metric.critical if metric.critical else ''}}</td>
                              <td>{{metric.min if metric.min else ''}}</td>
                              <td>{{metric.max if metric.max else ''}}</td>
                              <td>{{metric.uom if metric.uom else ''}}</td>
                              
                              <td>
                                 %# Graphs
                                 %import time
                                 %import re
                                 %now = time.time()
                                 %graphs = app.get_graph_uris(elt, now-4*3600, now)
                                 %for graph in graphs:
                                    %if re.findall('\\b'+metric.name+'\\b', graph['img_src']):
                                       <a role="button" tabindex="0" data-toggle="popover" title="{{ elt.get_full_name() }}" data-html="true" data-content="<img src='{{ graph['img_src'] }}' width='600px' height='200px'>" data-trigger="hover" data-placement="left">{{!helper.get_perfometer(elt, metric.name)}}</a>
                                    %end
                                 %end
                              </td>
                           </tr>
                           %end
                           %end
                           %end
                        %end
                        </tbody>
                     </table>
                  </div>
               </div>
            </div>
            %end
            <!-- Tab Metrics end -->

            <!-- Tab Graph start -->
            %if 'graphs' in params['tabs']:
            <script>
            var html_graphes = [];
            var current_graph = '';
            var graphstart={{graphstart}};
            var graphend={{graphend}};
            </script>
            <div class="tab-pane fade" id="graphs">
               <div class="panel panel-default">
                  <div class="panel-body">
                     %# Set source as '' or module ui-graphite will try to fetch templates from default 'detail'
                     %uris = app.get_graph_uris(elt, graphstart, graphend)
                     %if len(uris) == 0:
                     <div class="alert alert-info">
                         <div class="font-blue"><strong>No graphs available for this {{elt_type}}!</strong></div>
                     </div>
                     %else:
                     <div class='well'>
                        <!-- Get the uris for the 5 standard time ranges in advance  -->
                        %fourhours = now - 3600*4
                        %lastday =   now - 86400
                        %lastweek =  now - 86400*7
                        %lastmonth = now - 86400*31
                        %lastyear =  now - 86400*365

                        <ul id="graph_periods" class="nav nav-pills nav-justified">
                          <li><a data-type="graph" data-period="4h" data-graphend="{{now}}" data-graphstart="{{fourhours}}"  > 4 hours</a></li>
                          <li><a data-type="graph" data-period="1d" data-graphend="{{now}}" data-graphstart="{{lastday}}"    > 1 day</a></li>
                          <li><a data-type="graph" data-period="1w" data-graphend="{{now}}" data-graphstart="{{lastweek}}"   > 1 week</a></li>
                          <li><a data-type="graph" data-period="1m" data-graphend="{{now}}" data-graphstart="{{lastmonth}}"  > 1 month</a></li>
                          <li><a data-type="graph" data-period="1y" data-graphend="{{now}}" data-graphstart="{{lastyear}}"   > 1 year</a></li>
                        </ul>
                     </div>

                     <div class='well'>
                        <div id='real_graphs'>
                        </div>
                     </div>
                     
                     <script>
                     $('a[href="#graphs"]').on('shown.bs.tab', function (e) {
                        %uris = dict()
                        %uris['4h'] = app.get_graph_uris(elt, fourhours, now)
                        %uris['1d'] = app.get_graph_uris(elt, lastday,   now)
                        %uris['1w'] = app.get_graph_uris(elt, lastweek,  now)
                        %uris['1m'] = app.get_graph_uris(elt, lastmonth, now)
                        %uris['1y'] = app.get_graph_uris(elt, lastyear,  now)

                        // let's create the html content for each time range
                        var element='/{{elt_type}}/{{elt.get_full_name()}}';
                        %for period in ['4h', '1d', '1w', '1m', '1y']:
                        
                        html_graphes['{{period}}'] = '<p>';
                        %for g in uris[period]:
                        %(img_src, link) = app.get_graph_img_src( g['img_src'], g['link'])
                        
                        // Adjust image width / height parameter ... width is sized to container, and height is 1/3
                        var img_src = "{{img_src}}".replace("'","\'")
                        img_src = img_src.replace(/(width=).*?(&)/,'$1' + $('#real_graphs').width() + '$2');
                        img_src = img_src.replace(/(height=).*?(&)/,'$1' + ($('#real_graphs').width() / 3) + '$2');
                        
                        html_graphes['{{period}}'] +=  '<img src="'+ img_src +'" class="jcropelt"/> \
                                                       <br>';
                        %end
                        html_graphes['{{period}}'] += '</p>';

                        %end
                        
                        // Set first graph
                        current_graph = '4h';
                        $('a[data-type="graph"][data-period="'+current_graph+'"]').trigger('click');
                     });
                     </script>
                     %end
                  </div>
               </div>
            </div>
            %end
            <!-- Tab Graph end -->

            <!-- Tab Dependency graph Start -->
            %if 'depgraph' in params['tabs']:
            <div class="tab-pane fade" id="depgraph">
               <div class="panel panel-default">
                  <div class="panel-body">
                     <div class="btn-group btn-group-sm pull-right">
                        <button data-type="action" action="fullscreen-request" data-element="inner_depgraph" class="btn btn-primary"><i class="fa fa-desktop"></i> Fullscreen</button>
                     </div>
                     <div id="inner_depgraph" data-element='{{elt.get_full_name()}}'>
                     </div>
                  </div>
               </div>
            </div>
            %end
            <!-- Tab Dependency graph End -->

            <!-- Tab History start -->
            %if 'history' in params['tabs'] and app.logs_module:
            <div class="tab-pane fade" id="history">
               <div class="panel panel-default">
                  <div class="panel-body">
                     <div id="inner_history" data-element='{{elt.get_full_name()}}'>
                     </div>
                  </div>
               </div>
            </div>
            %end
            <!-- Tab History end -->

            <!-- Tab Availability start -->
            %if 'availability' in params['tabs'] and app.logs_module:
            <div class="tab-pane fade" id="availability">
               <div class="panel panel-default">
                  <div class="panel-body">
                     <div id="inner_availability" data-element='{{elt.get_full_name()}}'>
                     </div>
                  </div>
               </div>
            </div>
            %end
            <!-- Tab Availability end -->

            <!-- Tab Helpdesk start -->
            %if 'helpdesk' in params['tabs'] and app.helpdesk_module:
            <div class="tab-pane fade" id="helpdesk">
               <div class="panel panel-default">
                  <div class="panel-body">
                     <div id="inner_helpdesk" data-element='{{elt.get_full_name()}}'>
                     </div>
                  
                     <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm" 
                           data-type="action" action="create-ticket"
                           data-toggle="tooltip" data-placement="bottom" title="Create a ticket for this {{elt_type}}"
                           data-element="{{helper.get_uri_name(elt)}}" 
                           >
                        <i class="fa fa-medkit"></i> Create a ticket
                     </button>
                  </div>
               </div>
            </div>
            %end
            <!-- Tab Helpdesk end -->
         </div>
      <!-- Detail info box end -->
   </div>
</div>
%#End of the element exist or not case
%end
