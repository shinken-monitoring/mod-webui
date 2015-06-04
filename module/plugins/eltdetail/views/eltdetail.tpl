%import time

%# If got no element, bailout
%if not elt:
%rebase("layout", title='Invalid element name')

Invalid element name

%else:

%helper = app.helper
%datamgr = app.datamgr

%from shinken.macroresolver import MacroResolver

%elt_type = elt.__class__.my_type

%top_right_banner_state = datamgr.get_overall_state()

%# Look for actions if we must show them or not
%global_disabled = ''
%if app.manage_acl and not helper.can_action(user):
  %global_disabled = 'disabled-link'
%end

%business_rule = False
%if elt_type=='host':
   %# Count hosts services for different states
   %sOK=0
   %sWARNING=0
   %sCRITICAL=0
   %sPENDING=0
   %sUNKNOWN=0
   %sACK=0
   %sDOWNTIME=0

   %for s in elt.services:
      %if s.state == 'OK':
         %sOK=sOK+1
      %elif s.state == 'WARNING':
         %sWARNING=sWARNING+1
      %elif s.state == 'CRITICAL':
         %sCRITICAL=sCRITICAL+1
      %elif s.state == 'PENDING':
         %sPENDING=sPENDING+1
      %else:
         %sUNKNOWN=sUNKNOWN+1
      %end
      %if s.problem_has_been_acknowledged:
         %sACK=sACK+1
      %end
      %if s.in_scheduled_downtime:
         %sDOWNTIME=sDOWNTIME+1
      %end
   %end
%else:
%if elt.get_check_command().startswith('bp_rule'):
%business_rule = True
%end
%end

%if elt_type=='host':
%breadcrumb = [ ['All hosts', '/hosts-groups'], [elt.host_name, '/host/'+elt.host_name] ]
%title = 'Host detail: ' + elt.host_name
%else:
%breadcrumb = [ ['All services', '/services-groups'], [elt.host.host_name, '/host/'+elt.host.host_name], [elt.service_description, '/service/'+elt.host.host_name+'/'+elt.service_description] ]
%title = 'Service detail: ' + elt.service_description+' on '+elt.host.host_name
%end

%rebase("layout", js=['eltdetail/js/jquery.color.js', 'eltdetail/js/bootstrap-switch.js', 'eltdetail/js/jquery.Jcrop.js', 'eltdetail/js/hide.js', 'eltdetail/js/dollar.js', 'eltdetail/js/gesture.js', 'eltdetail/js/graphs.js', 'eltdetail/js/depgraph.js', 'eltdetail/js/custom_views.js', 'eltdetail/js/screenfull.js', 'eltdetail/js/shinken-gauge.js', 'eltdetail/js/timeline.js', 'timeline/js/timeline.js', 'eltdetail/js/history.js'], css=['eltdetail/css/bootstrap-switch.css', 'eltdetail/css/eltdetail.css', 'eltdetail/css/hide.css', 'eltdetail/css/gesture.css', 'eltdetail/css/jquery.Jcrop.css', 'eltdetail/css/shinken-gauge.css', 'timeline/css/timeline.css'], user=user, app=app, refresh=True, breadcrumb=breadcrumb, title=title)

<script type="text/javascript">
   var elt_name = '{{elt.get_full_name()}}';

   var graphstart={{graphstart}};
   var graphend={{graphend}};

   $(document).ready(function(){
      /* Hide gesture panel */
      $('#gesture_panel').hide();

      // Also hide the button under IE (gesture don't work under it)
      if (navigator.appName == 'Microsoft Internet Explorer'){
         $('#btn_show_gesture').hide();
      }
      
      /* Look at the # part of the URI. If it match a nav name, go for it*/
      if (window.location.hash.length > 0) {
      $('.nav-tabs a[href="' + window.location.hash + '"]').tab('show');
      } else {
         $('.nav-tabs a:first').tab('show');
      }
      
      $('[data-toggle="popover"]').popover();
      
      // When a nav item is selected update the page hash
      $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
         window.location.hash = $(e.target).attr('href');
      })
    
      // Buttons tooltips
      $('button').tooltip();

      // Long text truncation
      $('.truncate_command').jTruncate({
         length: 200,
         minTrail: 0,
         moreText: "[see all]",
         lessText: "[hide extra]",
         ellipsisText: " <strong>(...)</strong>",
         moreAni: "fast",
         lessAni: 2000
      });

      $('.truncate_output').jTruncate({
         length: 200,
         minTrail: 0,
         moreText: "[see all]",
         lessText: "[hide extra]",
         ellipsisText: " <strong>(...)</strong>",
         moreAni: "fast",
         lessAni: 2000
      });

      $('.truncate_perf').jTruncate({
         length: 100,
         minTrail: 0,
         moreText: "[see all]",
         lessText: "[hide extra]",
         ellipsisText: " <strong>(...)</strong>",
         moreAni: "fast",
         lessAni: 2000
      });
  });
</script>


%# Main variables
%elt_name = elt.host_name if elt_type=='host' else elt.service_description+' on '+elt.host.host_name
%elt_display_name = elt.display_name if elt_type=='host' else elt.service_description

   <!-- First row : tags and actions ... -->
   %if elt.action_url != '' or (elt_type=='host' and len(elt.get_host_tags()) != 0) or (elt_type=='service' and len(elt.get_service_tags()) != 0) or (elt_type=='host' and len(elt.hostgroups) > 0) or (elt_type=='service' and len(elt.servicegroups) > 0):
   <div class="row">
      <div class="col-sm-12">
         %if (elt_type=='host' and len(elt.hostgroups) > 0) or (elt_type=='service' and len(elt.servicegroups) > 0):
         <div class="btn-group pull-right">
            <button class="btn btn-primary btn-xs"><i class="fa fa-sitemap"></i> Groups</button>
            <button class="btn btn-primary btn-xs dropdown-toggle" data-toggle="dropdown"><span class="caret"></span></button>
            <ul class="dropdown-menu pull-right">
            %if elt_type=='host':
               %for hg in elt.hostgroups:
               <li>
               %if 'hosts-groups' in app.menu_items:
               <a href="/hosts-group/{{hg.get_name()}}">{{hg.get_name()}} ({{hg.alias}})</a>
               %else:
               {{hg.get_name()}} ({{hg.alias}})
               %end
               </li>
               %end
            %else:
               %for sg in elt.servicegroups:
               <li>
               %if 'services-groups' in app.menu_items:
               <a href="/services-group/{{sg.get_name()}}">{{sg.get_name()}} ({{sg.alias}})</a>
               %else:
               {{sg.get_name()}} ({{sg.alias}})
               %end
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
               %action_urls = elt.action_url.split('|')
               %if len(action_urls) > 0:
                  %for triplet in action_urls:
                  %try:
                  %if len(triplet.split(',')) == 3:
                     %( action_url, icon, alt) = triplet.split(',')
                     <li><a href="{{ MacroResolver().resolve_simple_macros_in_string(action_url, elt.get_data_for_checks()) }}" target=_blank><img src={{icon}} alt="{{alt}}"></a></li>
                  %else:
                  %if len(triplet.split(',')) == 1:
                    <li><a id="action-link" href="{{ MacroResolver().resolve_simple_macros_in_string(triplet, elt.get_data_for_checks()) }}" target=_blank>{{ MacroResolver().resolve_simple_macros_in_string(triplet, elt.get_data_for_checks()) }}</a></li>
                  %end
                  %end
                  %except:
                     <li><a id="action-link" href="{{ triplet }}" target=_blank>{{ triplet }}</a></li>
                  %end
                  %end
               %end
            </ul>
         </div>
         <div class="pull-right">&nbsp;&nbsp;</div>
         %end
         %if hasattr(elt, 'get_host_tags') and len(elt.get_host_tags()) != 0:
         <div id="host_tags" class="btn-group pull-right">
            <script>
               %i=0
               %for t in sorted(elt.get_host_tags()):
                  var a{{i}} = $('<a href="/all?search=htag:{{t}}"/>').appendTo($('#host_tags'));
                  $('<img />')
                     .attr({ 'src': '{{app.share_dir}}/images/sets/{{t.lower()}}/tag.png', 'alt': '{{t.lower()}}', 'title': 'Tag: {{t.lower()}}' })
                     .css({height: "24px"})
                     .load(function() {
                     })
                     .error(function() {
                        $(this).remove();
                        $('<img />')
                           .attr({ 'src': '/static/images/tags/{{t.lower()}}.png', 'alt': '{{t.lower()}}', 'title': 'Tag: {{t.lower()}}' })
                           .css({height: "24px"})
                           .load(function() {})
                           .error(function() {
                             $(this).remove();
                             $("<span/>").attr({ 'class': 'btn btn-default btn-xs bg-host'}).append('{{t}}').appendTo(a{{i}});
                           })
                           .appendTo(a{{i}});
                     })
                     .appendTo(a{{i}});
                  var span = $("<span/>").append('&nbsp;').appendTo($('#host_tags'));
                  %i=i+1
               %end
            </script>
         </div>
         %end
         %if hasattr(elt, 'get_service_tags') and len(elt.get_service_tags()) != 0:
         <div id="service_tags" class="btn-group pull-right">
            <script>
               %j=0
               %for t in sorted(elt.get_service_tags()):
                  var b{{j}} = $('<a href="/all?search=stag:{{t}}"/>').appendTo($('#service_tags'));
                  $('<img />')
                     .attr({ 'src': '/static/images/tags/{{t.lower()}}.png', 'alt': '{{t.lower()}}', 'title': 'Tag: {{t.lower()}}' })
                     .css({height: "24px"})
                     .load(function() {
                     })
                     .error(function() {
                       $(this).remove();
                       $("<span/>").attr({ 'class': 'btn btn-default btn-xs bg-service'}).append('{{t}}').appendTo(b{{j}});
                     })
                     .appendTo(b{{j}});
                  var span = $("<span/>").append('&nbsp;').appendTo($('#service_tags'));
                  %j=j+1
               %end
            </script>
         </div>
         %end
         <div class="clearfix"></div>
      </div>
   </div>
   %end

   <!-- Second row : host/service overview ... -->
   <div class="row" style="padding: 5px;">
      <div class="panel-group" id="Overview">
         <div class="panel panel-default">
            <div class="panel-heading">
               <div class="panel-heading fitted-header cursor" data-toggle="collapse" data-parent="#Overview" href="#collapseOverview">
                  <h4 class="panel-title"><span class="caret"></span>&nbsp;Overview {{elt_name}} ({{elt.display_name if elt.display_name else elt.alias if elt.alias else 'none'}}) {{!helper.get_business_impact_text(elt.business_impact)}}
                  </h4>
               </div>
            </div>
        
            <div id="collapseOverview" class="panel-collapse collapse in">
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
                  %for hg in elt.hostgroups:
                  %if 'hosts-groups' in app.menu_items:
                  <a href="/hosts-group/{{hg.get_name()}}" class="link">{{hg.alias}} ({{hg.get_name()}})</a>
                  %else:
                  {{hg.alias}} ({{hg.get_name()}})
                  %end
                  %end
                  </dd>
                  %else:
                  <dd>(none)</dd>
                  %end

                  <dt>Notes:</dt>
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
                  %for sg in elt.servicegroups:
                  %if 'services-groups' in app.menu_items:
                  <a href="/services-group/{{sg.get_name()}}" class="link">{{sg.alias}} ({{sg.get_name()}})</a>
                  %else:
                  {{sg.alias}} ({{sg.get_name()}})
                  %end
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

               %if elt_type=='host':
                  <table class="table table-invisible">
                     <tbody>
                        <tr>
                           <td>
                              <b>{{len(elt.services)}} services:</b> 
                           </td>
          
                           <td>
                              {{!helper.get_fa_icon_state(cls='service', state='OK')}} {{sOK}} Ok
                           </td>
                           <td>
                              {{!helper.get_fa_icon_state(cls='service', state='warning')}} {{sWARNING}} Warning
                           </td>
                           <td>
                              {{!helper.get_fa_icon_state(cls='service', state='critical')}} {{sCRITICAL}} Critical
                           </td>
                           <td>
                              {{!helper.get_fa_icon_state(cls='service', state='pending')}} {{sPENDING}} Pending
                           </td>
                           <td>
                              {{!helper.get_fa_icon_state(cls='service', state='unknown')}} {{sUNKNOWN}} Unknown
                           </td>
                           <td>
                              {{!helper.get_fa_icon_state(cls='service', state='ack')}} {{sACK}} Ack
                           </td>
                           <td>
                              {{!helper.get_fa_icon_state(cls='service', state='downtime')}} {{sDOWNTIME}} Downtime
                           </td>
                        </tr>
                     </tbody>
                  </table>
               %end
            </div>
         </div>
      </div>
   </div>

   <!-- Third row : business impact alerting ... -->
   %if elt.is_problem and elt.business_impact > 2 and not elt.problem_has_been_acknowledged:
   <div class="row" style="padding: 5px;">
      <div class="col-lg-2 hidden-md"></div>
      <div class="col-lg-8 col-md-12">
         <div class="col-lg-1 font-yellow pull-left">
            <span class="medium-pulse aroundpulse">
               <span class="medium-pulse pulse"></span>
               <i class="fa fa-3x fa-bolt"></i>
            </span>
         </div>
         <div class="col-lg-11 font-white">
            %disabled_ack = '' if elt.is_problem and not elt.problem_has_been_acknowledged else 'disabled'
            %disabled_fix = '' if elt.is_problem and elt.event_handler_enabled and elt.event_handler else 'disabled'
            <p class="alert alert-critical">This element has an important impact on your business, you may <button name="bt-acknowledge" class="{{disabled_ack}} {{global_disabled}} btn btn-primary btn-xs" data-toggle="tooltip" data-placement="bottom" title="Acknowledge this {{elt_type}} problem">acknowledge it</button> or <button name="bt-event-handler" class="{{disabled_fix}} {{global_disabled}} btn btn-primary btn-xs" data-toggle="tooltip" data-placement="bottom" title="Launch the event handler for this {{elt_type}}">try to fix it</button>.</p>
         </div>
      </div>
      <div class="col-lg-2 hidden-md"></div>
   </div>
   %end
  
   <!-- Third row (bis) : business rule ... -->
   %if business_rule:
   <div class="row" style="padding: 5px;">
      <div class="col-lg-2 hidden-md"></div>
      <div class="col-lg-8 col-md-12">
         <div class="col-lg-1 pull-left">
            <span class="medium-pulse aroundpulse">
               <span class="medium-pulse pulse"></span>
               <i class="fa fa-2x fa-university"></i>
            </span>
         </div>
         <div class="col-lg-11 font-white">
            <p class="alert alert-warning">This element is a business rule.</p>
         </div>
      </div>
      <div class="col-lg-2 hidden-md"></div>
   </div>
   %end
  
   <!-- Fourth row : host/service -->
   <div class="row" style="padding: 5px;">
      <div class="col-sm-6 col-md-4 col-lg-3 tabbable verticaltabs-container">
         <ul class="nav nav-tabs">
            %if params['tab_information']=='yes':
            <li class="active"><a href="#information" data-toggle="tab">Information</a></li>
            %end
            %if params['tab_notification']=='yes':
            <li><a href="#notification" data-toggle="tab">Notification</a></li>
            %end
            %if params['tab_additional']=='yes':
            <li><a href="#additional" data-toggle="tab">Additional</a></li>
            %end
            %if params['tab_commands']=='yes' and app.manage_acl and helper.can_action(user):
            <li><a href="#commands" data-toggle="tab">Commands</a></li>
            %end
            %if params['tab_gesture']=='yes':
            <li><a href="#gesture" data-toggle="tab">Gesture</a></li>
            %end
            %if params['tab_configuration']=='yes':
            <li><a href="#configuration" data-toggle="tab">Configuration</a></li>
            %end
         </ul>

         <div class="tab-content">
            %if params['tab_information']=='yes':
            <div class="tab-pane fade in active" id="information">
               <h4>{{elt_type.capitalize()}} information:</h4>

               <table class="table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
                  <colgroup>
                     <col style="width: 40%" />
                     <col style="width: 60%" />
                  </colgroup>
                  <tbody style="font-size:small;">
                     <tr>
                        <td><strong>Status:</strong></td>
                        <td>
                           %acked = 'check' if elt.problem_has_been_acknowledged else ''
                           <button class="col-lg-12 btn trim trim-{{elt.state.lower()}}" data-toggle="tooltip" data-placement="bottom" title="since {{helper.print_duration(elt.last_state_change, just_duration=True, x_elts=2)}}">{{elt.state}} <i class='fa fa-{{acked}}'></i></button>
                        </td>
                     </tr>
                     %if elt.flap_detection_enabled:
                     <tr>
                        <td><strong>Flapping:</strong></td>
                        <td>
                           <button class="col-lg-12 btn trim trim-{{helper.yes_no(elt.is_flapping)}}" data-toggle="tooltip" data-placement="bottom" title="{{helper.print_float(elt.percent_state_change)}}% state change">{{helper.yes_no(elt.is_flapping)}}</button>
                        </td>
                     </tr>
                     %end
                     <tr>
                        <td><strong>Downtime:</strong></td>
                        <td>
                           <button class="col-lg-12 btn trim trim-{{helper.yes_no(elt.in_scheduled_downtime)}}">{{helper.yes_no(elt.in_scheduled_downtime)}}</button>
                        </td>
                     </tr>
                  </tbody>
               </table>
                     
               <table class="table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
                  <tbody style="font-size:x-small;">
                     <tr>
                        <td colspan="2"><hr/></td>
                     </tr>
                  </tbody>
               </table>
                     
               <table class="table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
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
                        <td><span class="quickinfo" data-original-title='Last check was at {{time.asctime(time.localtime(elt.last_chk))}}'>was {{helper.print_duration(elt.last_chk)}}</span></td>
                     </tr>
                     <tr>
                        <td><strong>Output:</strong></td>
                        <td class="truncate_output"><em>
                        %if len(elt.output) > app.max_output_length:
                           <div class='check-output check-output-{{elt.state.lower()}}' rel="tooltip" data-original-title="{{elt.output}}"> {{!helper.strip_html_output(elt.output[:app.max_output_length]) if app.allow_html_output else elt.output[:app.max_output_length]}}</div>
                        %else:
                           <div class='check-output check-output-{{elt.state.lower()}}'> {{!helper.strip_html_output(elt.output) if app.allow_html_output else elt.output}}</div>
                        %end
                        </em></td>
                     </tr>
                     %if elt.long_output:
                     <tr>
                        <td><strong>Long output:</strong></td>
                        <td class="truncate_output">
                           <div class='check-output check-output-{{elt.state.lower()}}'> {{elt.long_output}} </div>
                        </td>
                     </tr>
                     %end
                     <tr>
                        <td><strong>Performance data:</strong></td>
                        <td class="truncate_perf">
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
                        <td colspan="2"><hr/></td>
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
                        <td><span class="quickinfo" data-original-title='Next active check at {{time.asctime(time.localtime(elt.next_chk))}}'>{{helper.print_duration(elt.next_chk)}}</span></td>
                     </tr>
                  </tbody>
               </table>
            </div>
            %end

            %if params['tab_notification']=='yes':
            <div class="tab-pane fade" id="notification">
               <h4>{{elt_type.capitalize()}} notification:</h4>
               
               <table class="table table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
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
                        <td>{{! app.helper.get_on_off(elt.notifications_enabled, "Are notifications enabled for this element?")}}</td>
                     </tr>
                     %if elt.notifications_enabled and elt.notification_period:
                     <tr>
                        <td><strong>Notification period:</strong></td>
                        <td name="notification_period" class="popover-dismiss" data-html="true" data-toggle="popover" data-trigger="hover" title="Notification period" data-placement="bottom" data-content="...">
                        {{! app.helper.get_on_off(elt.notification_period.is_time_valid(time.time()), "Is notification period currently active?")}}
                        %if 'timeperiods' in app.menu_items:
                        <a href="/timeperiods">{{elt.notification_period.alias}}</a>
                        <script>
                           %tp=app.get_timeperiod(elt.notification_period.get_name())
                           $('td[name="notification_period"]')
                             .attr('title', '{{tp.alias if hasattr(tp, "alias") else tp.timeperiod_name}}')
                             .attr('data-content', '{{!helper.get_timeperiod_html(tp)}}')
                             .popover();
                        </script>
                        %else:
                        {{elt.notification_period.alias}}
                        %end
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
                           {{! app.helper.get_on_off(m in elt.notification_options, '', message[m]+'&nbsp;')}}
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
                        %if 'contacts' in app.menu_items:
                        %[contacts.append('<a href="/contact/'+item.contact_name+'">'+item.alias+'</a>' if item.alias else item.get_name()) for item in elt.contacts if item not in contacts]
                        %else:
                        %[contacts.append(item.alias if item.alias else item.get_name()) for item in elt.contacts if item not in contacts]
                        %end
                        <td>{{!', '.join(contacts)}}</td>
                     </tr>
                     <tr>
                        <td><strong>Contacts groups:</strong></td>
                        <td></td>
                     </tr>
                     %i=0
                     %for (group) in elt.contact_groups: 
                     <tr>
                        %cg = app.get_contactgroup(group)
                        <td style="text-align: right; font-style: italic;"><strong>{{cg.alias if cg.alias else cg.get_name()}}</strong></td>
                        %contacts=[]
                        %if 'contacts' in app.menu_items:
                        %[contacts.append('<a href="/contact/'+item.contact_name+'">'+item.alias+'</a>' if item.alias else item.get_name()) for item in cg.members if item not in contacts]
                        %else:
                        %[contacts.append(item.alias if item.alias else item.get_name()) for item in cg.members if item not in contacts]
                        %end
                        <td>{{!', '.join(contacts)}}</td>
                        %i=i+1
                     </tr>
                     %end
                     %end
                  </tbody>
               </table>
            </div>
            %end
            
            %if params['tab_additional']=='yes':
            <div class="tab-pane fade" id="additional">
               <h4>Additional information:</h4>
               
               <table class="table table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
                  <colgroup>
                     <col style="width: 40%" />
                     <col style="width: 60%" />
                  </colgroup>
                  <thead>
                     <tr>
                        <th colspan="2">Checks:</td>
                     </tr>
                  </thead>
                  <tbody style="font-size:x-small;">
                     <tr>
                        <td><strong>Check period:</strong></td>
                        %if 'timeperiods' in app.menu_items:
                        <td name="check_period" class="popover-dismiss" data-html="true" data-toggle="popover" data-trigger="hover" title="Check period" data-placement="bottom" data-content="...">
                        <a href="/timeperiods">{{elt.check_period.alias}}</a>
                        </td>
                        <script>
                           %tp=app.get_timeperiod(elt.check_period.get_name())
                           $('td[name="check_period"]')
                             .attr('title', '{{tp.alias if hasattr(tp, "alias") else tp.timeperiod_name}}')
                             .attr('data-content', '{{!helper.get_timeperiod_html(tp)}}')
                             .popover();
                        </script>
                        %else:
                        <td name="check_period" class="popover-dismiss" data-html="true" data-toggle="popover" title="Check period" data-placement="bottom" data-content="...">{{elt.check_period.alias}}</td>
                        %end
                     </tr>
                     %if elt.maintenance_period is not None:
                     <tr>
                        <td><strong>Maintenance period:</strong></td>
                        %if 'timeperiods' in app.menu_items:
                        <td name="maintenance_period" class="popover-dismiss" data-html="true" data-toggle="popover" data-trigger="hover" title="Check period" data-placement="bottom" data-content="...">
                        <a href="/timeperiods">{{elt.maintenance_period.alias}}</a>
                        </td>
                        <script>
                           %tp=app.get_timeperiod(elt.maintenance_period.get_name())
                           $('td[name="maintenance_period"]')
                             .attr('title', '{{tp.alias if hasattr(tp, "alias") else tp.timeperiod_name}}')
                             .attr('data-content', '{{!helper.get_timeperiod_html(tp)}}')
                             .popover();
                        </script>
                        %else:
                        <td name="maintenance_period" class="popover-dismiss" data-html="true" data-toggle="popover" title="Check period" data-placement="bottom" data-content="...">{{elt.maintenance_period.alias}}</td>
                        %end
                     </tr>
                     %end
                     <tr>
                        <td><strong>Check command:</strong></td>
                        <td class="truncate_command">
                        %try:
                           {{ MacroResolver().resolve_simple_macros_in_string(elt.get_check_command(), elt.get_data_for_checks()) }}
                        %except:
                           {{elt.get_check_command()}}
                        %end
                        </td>
                        <td>
                        </td>
                     </tr>
                     <tr>
                        <td><strong>Active checks:</strong></td>
                        <td>{{! app.helper.get_on_off(elt.active_checks_enabled, 'Is active checking enabled?')}}</td>
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
                        <td>{{! app.helper.get_on_off(elt.passive_checks_enabled, 'Is passive checking enabled?')}}</td>
                     </tr>
                     %if (elt.passive_checks_enabled):
                     <tr>
                        <td><strong>Freshness check:</strong></td>
                        <td>{{! app.helper.get_on_off(elt.check_freshness, 'Is freshness check enabled?')}}</td>
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
                        <td>{{! app.helper.get_on_off(elt.process_perf_data, 'Is perfdata process enabled?')}}</td>
                     </tr>
                     <tr>
                        <td><strong>Event handler enabled:</strong></td>
                        <td>{{! app.helper.get_on_off(elt.event_handler_enabled, 'Is event handler enabled?')}}</td>
                     </tr>
                     %if elt.event_handler_enabled and elt.event_handler:
                     <tr>
                        <td><strong>Event handler:</strong></td>
                        <td>
                           {{ elt.event_handler.get_name() }}
                        </td>
                     </tr>
                     %end
                  </tbody>
               </table>
          
               <table class="table table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
                  <colgroup>
                     <col style="width: 40%" />
                     <col style="width: 60%" />
                  </colgroup>
                  <thead>
                     <tr>
                        <th colspan="2">Flapping:</td>
                     </tr>
                  </thead>
                  <tbody style="font-size:x-small;">
                     <tr>
                        <td><strong>Flapping detection:</strong></td>
                        <td>{{! app.helper.get_on_off(elt.flap_detection_enabled, 'Is status flapping detection enabled?')}}</td>
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
          
            </div>
            %end

            %if params['tab_commands']=='yes' and app.manage_acl and helper.can_action(user):
            <div class="tab-pane fade" id="commands">
               <h4>Commands:</h4>
               <table class="table table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
                  <colgroup>
                     <col class="col-sm-1" />
                     <col class="col-sm-11" />
                  </colgroup>
                  <tbody style="font-size:small;">
                     <tr>
                        <td></td>
                        <td>
                           %disabled_s = ''
                           <button name="bt-add-comment" class="col-lg-12 {{disabled_s}} {{global_disabled}} btn btn-primary btn-sm" data-toggle="tooltip" data-placement="bottom" title="Add a comment for this {{elt_type}}"><i class="fa fa-check"></i> Add a comment</button>
                        </td>
                     </tr>
                     
                     <tr>
                        <td></td>
                        <td>
                           %disabled_s = '' if elt.is_problem and elt.event_handler_enabled and elt.event_handler else 'disabled'
                           <button name="bt-event-handler" class="col-lg-12 {{disabled_s}} {{global_disabled}} btn btn-primary btn-sm" data-toggle="tooltip" data-placement="bottom" title="Launch the event handler for this {{elt_type}}"><i class="fa fa-magic"></i> Try to fix problem</button>
                           <script>
                              $('button[name="bt-event-handler"]').click(function () {
                                 try_to_fix('{{elt.get_full_name()}}');
                              });
                           </script>
                        </td>
                     </tr>
                     
                     <tr>
                     %if elt.state != elt.ok_up and not elt.problem_has_been_acknowledged:
                        <td></td>
                        <td>
                           %disabled_s = '' if elt.state != elt.ok_up and not elt.problem_has_been_acknowledged else 'disabled'
                           <button id="bt-acknowledge" name="bt-acknowledge" class="col-lg-12 {{disabled_s}} {{global_disabled}} btn btn-primary btn-sm" data-toggle="tooltip" data-placement="bottom" title="Acknowledge this {{elt_type}} problem"><i class="fa fa-check"></i> Add an acknowledgement</button>
                           <script>
                              $('button[name="bt-acknowledge"]').click(function () {
                                 stop_refresh();
                                 $('#modal').modal({
                                    keyboard: true,
                                    show: true,
                                    backdrop: 'static',
                                    remote: "/forms/acknowledge/{{helper.get_uri_name(elt)}}"
                                 });
                              });
                           </script>
                        </td>
                     %else:
                        <td></td>
                        <td>
                           %disabled_s = '' if elt.problem_has_been_acknowledged else 'disabled'
                           <button id="bt-acknowledge" name="bt-acknowledge" class="col-lg-12 {{disabled_s}} {{global_disabled}} btn btn-primary btn-sm" data-toggle="tooltip" data-placement="bottom" title="Acknowledge this {{elt_type}} problem"><i class="fa fa-check"></i> Remove acknowledgement</button>
                           <script>
                              $('button[name="bt-acknowledge"]').click(function () {
                                 delete_acknowledge('{{elt.get_full_name()}}');
                              });
                           </script>
                        </td>
                     %end
                     </tr>
                     
                     <tr>
                        <td></td>
                        <td>
                           %disabled_s = '' if elt.active_checks_enabled else 'disabled'
                           <button id="bt-recheck" class="col-lg-12 {{disabled_s}} {{global_disabled}} btn btn-primary btn-sm" data-toggle="tooltip" data-placement="bottom" title="Launch a check for this {{elt_type}} now"><i class="fa fa-refresh"></i> Recheck now</button>
                           <script>
                              $('#bt-recheck').click(function () {
                                 recheck_now('{{elt.get_full_name()}}');
                              });
                           </script>
                        </td>
                     </tr>
                     
                     <tr>
                        <td></td>
                        <td>
                           %disabled_s = '' if elt.passive_checks_enabled else 'disabled'
                           <button name="bt-check-result" class="col-lg-12 {{disabled_s}} {{global_disabled}} btn btn-primary btn-sm" data-toggle="tooltip" data-placement="bottom" title="Submit a check result for this {{elt_type}}"><i class="fa fa-share"></i> Submit a check result</button>
                           <script>
                              $('button[name="bt-check-result"]').click(function () {
                                 stop_refresh();
                                 $('#modal').modal({
                                    keyboard: true,
                                    show: true,
                                    backdrop: 'static',
                                    remote: "/forms/submit_check/{{helper.get_uri_name(elt)}}"
                                 });
                              });
                           </script>
                        </td>
                     </tr>
                     
                     <!--
              <tr>
                        <td></td>
                        <td>
                           %disabled_s = 'disabled'
                           <button id="bt-custom-notification" class="col-lg-12 {{disabled_s}} {{global_disabled}} btn btn-primary btn-sm" data-toggle="tooltip" data-placement="bottom" title="Send a custom notification for this {{elt_type}}">Send a custom notification</button>
                           <script>
                              $('#bt-custom-notification').click(function () {
                              });
                           </script>
                        </td>
                     </tr>
              -->
                     <tr>
                        <td></td>
                        <td>
                           %disabled_s = ''
                           <button id="bt-custom-var" class="col-lg-12 {{disabled_s}} {{global_disabled}} btn btn-primary btn-sm" data-toggle="tooltip" data-placement="bottom" title="Change a custom variable for this {{elt_type}}"><i class="fa fa-gears"></i> Change a custom variable</button>
                           <script>
                              $('#bt-custom-var').click(function () {
                                 stop_refresh();
                                 $('#modal').modal({
                                    keyboard: true,
                                    show: true,
                                    backdrop: 'static',
                                    remote: "/forms/custom_var/{{helper.get_uri_name(elt)}}"
                                 });
                              });
                           </script>
                        </td>
                     </tr>
                     
                     <tr>
                        <td></td>
                        <td>
                           %disabled_s = ''
                           <button id="bt-schedule-downtime" name="bt-schedule-downtime" data-toggle="modal" data-target="#modal" class="col-lg-12 {{disabled_s}} {{global_disabled}} btn btn-primary btn-sm" data-toggle="tooltip" data-placement="bottom" title="Schedule a downtime for this {{elt_type}}"><i class="fa fa-ambulance"></i> Schedule a downtime</button>
                        </td>
                     </tr>
                  </tbody>
               </table>
                     
               <br/>
               <br/>
               <h4>Currently:</h4>
               <table class="table table-condensed col-sm-12" style="table-layout: fixed; word-wrap: break-word;">
                  <colgroup>
                     <col class="col-sm-6" />
                     <col class="col-sm-5" />
                  </colgroup>
                  <tbody style="font-size:small;">
                     <tr>
                        <td><strong>Active checks:</strong></td>
                        <td>
                           <input type="checkbox" id="ck-active-checks" {{'checked' if elt.active_checks_enabled else ''}} {{'readonly' if global_disabled != '' else ''}}>
                           <script>
                              $('#ck-active-checks').bootstrapSwitch();
                              $('#ck-active-checks').on('switch-change', function (e, data) {
                                 toggle_active_checks("{{elt.get_full_name()}}", !data.value);
                              });
                           </script>
                        </td>
                     </tr>
                     <tr>
                        <td><strong>Passive checks:</strong></td>
                        <td>
                           <input type="checkbox" id="ck-passive-checks" {{'checked' if elt.passive_checks_enabled else ''}} {{'readonly' if global_disabled != '' else ''}}>
                           <script>
                              $('#ck-passive-checks').bootstrapSwitch();
                              $('#ck-passive-checks').on('switch-change', function (e, data) {
                                 toggle_passive_checks("{{elt.get_full_name()}}", !data.value);
                              });
                           </script>
                        </td>
                     </tr>
                     <tr>
                        <td><strong>Check freshness:</strong></td>
                        <td>
                           <input type="checkbox" id="ck-check-freshness" {{'checked' if elt.check_freshness else ''}} {{'readonly' if global_disabled != '' else ''}}>
                           <script>
                              $('#ck-check-freshness').bootstrapSwitch();
                              $('#ck-check-freshness').on('switch-change', function (e, data) {
                                 toggle_freshness_check("{{elt.get_full_name()}}", !data.value);
                              });
                           </script>
                        </td>
                     </tr>
                     
                     <tr>
                        <td><strong>Notifications:</strong></td>
                        <td>
                           <input type="checkbox" id="ck-notifications" {{'checked' if elt.notifications_enabled else ''}} {{'readonly' if global_disabled != '' else ''}}>
                           <script>
                              $('#ck-notifications').bootstrapSwitch();
                              $('#ck-notifications').on('switch-change', function (e, data) {
                                 toggle_notifications("{{elt.get_full_name()}}", !data.value);
                              });
                           </script>
                        </td>
                     </tr>
                     <tr>
                        <td><strong>Event handler:</strong></td>
                        <td>
                           <input type="checkbox" id="ck-event-handler" {{'checked' if elt.event_handler_enabled else ''}} {{'readonly' if global_disabled != '' else ''}}>
                           <script>
                              $('#ck-event-handler').bootstrapSwitch();
                              $('#ck-event-handler').on('switch-change', function (e, data) {
                                 toggle_event_handlers("{{elt.get_full_name()}}", !data.value);
                              });
                           </script>
                        </td>
                     </tr>
                     <tr>
                        <td><strong>Flap detection:</strong></td>
                        <td>
                           <input type="checkbox" id="ck-flap-detection" {{'checked' if elt.flap_detection_enabled else ''}} {{'readonly' if global_disabled != '' else ''}}>
                           <script>
                              $('#ck-flap-detection').bootstrapSwitch();
                              $('#ck-flap-detection').on('switch-change', function (e, data) {
                                 toggle_flap_detection("{{elt.get_full_name()}}", !data.value);
                              });
                           </script>
                        </td>
                     </tr>
                  </tbody>
               </table>
            </div>
            %end

            %if params['tab_gesture']=='yes':
            <div class="tab-pane fade" id="gesture">
               <h4>Gesture</h4>
               <canvas id="gestureCanvas" width="200" height="200" class="" style="border: 3px solid black;"></canvas>
               <div class="gesture_button">
                  <img title="By keeping a left click pressed and drawing a check, you will launch an acknowledgement." alt="gesture acknowledge" src="/static/eltdetail/images/gesture-check.png"/> Acknowledge
               </div>
               <div class="gesture_button">
                  <img title="By keeping a left click pressed and drawing a circle, you will launch an recheck." alt="gesture recheck" src="/static/eltdetail/images/gesture-circle.png"/> Recheck
               </div>
               <div class="gesture_button">
                  <img title="By keeping a left click pressed and drawing a check, you will launch a try to fix command." alt="gesture fix" src="/static/eltdetail/images/gesture-zigzag.png"/> Fix
               </div>
            </div>
            %end

            %if params['tab_configuration']=='yes':
            <div class="tab-pane fade" id="configuration">
               <h4>{{elt_type.capitalize()}} configuration:</h4>

               %if len(elt.customs) > 0:
               <table class="table table-condensed col-sm-12 table-bordered" style="table-layout: fixed; word-wrap: break-word;">
                  <colgroup>
                     <col style="width: 50%" />
                     <col style="width: 50%" />
                  </colgroup>
                  <thead>
                     <tr>
                        <th colspan="2">Customs:</td>
                     </tr>
                  </thead>
                  <tbody style="font-size:x-small;">
                  %for p in sorted(elt.customs):
                     <tr>
                        <td>{{p}}</td>
                        <td>{{elt.customs[p]}}</td>
                     </tr>
                  %end
                  </tbody>
               </table>
               %end
            </div>
            %end
         </div>
      </div>

      <!-- Detail info box start -->
      <div class="col-sm-6 col-md-8 col-lg-9 tabbable">
         <ul class="nav nav-tabs">
            %_go_active = 'active'
            %if params['tab_custom_views']=='yes':
            %for cvname in elt.custom_views:
            <li class="{{_go_active}} cv_pane" data-cv-name="{{cvname}}" data-elt-name='{{elt.get_full_name()}}' id='tab-cv-{{cvname}}'><a class='link_to_tab' href="#cv{{cvname}}" data-toggle="tab">{{cvname.capitalize()}}</a></li>
               %_go_active = ''
            %_go_active = ''
            %end
            %end

            %if params['tab_impacts']=='yes':
            <li class="{{_go_active}}"><a class='link_to_tab' href="#impacts" data-toggle="tab">Services</a></li>
            %end
            %if params['tab_comments']=='yes':
             <li><a class='link_to_tab' href="#comments" data-toggle="tab">Comments</a></li>
            %end
            %if params['tab_downtimes']=='yes':
            <li><a class='link_to_tab' href="#downtimes" data-toggle="tab">Downtimes</a></li>
            %end
            %if params['tab_timeline']=='yes':
            <li class="timeline_pane"><a class="link_to_tab" href="#timeline" data-toggle="tab" id="tab_to_timeline">Timeline</a></li>
            %end
            %if params['tab_graphs']=='yes':
            <li><a class="link_to_tab" href="#graphs" data-toggle="tab" id="tab_to_graphs">Graphs</a></li>
            %end
            %if params['tab_depgraph']=='yes':
            <li><a class="link_to_tab" href="#depgraph" data-toggle="tab" id="tab_to_depgraph">Impact graph</a></li>
            %end
            %if params['tab_history']=='yes':
            <li class="history_pane"><a class="link_to_tab" href="#history" data-toggle="tab" id="tab_to_history">History</a></li>
            %end
         </ul>
         
         <div class="tab-content">
            <!-- Tab custom views -->
            %if params['tab_custom_views']=='yes':
            %_go_active = 'active'
            %_go_fadein = 'in'
            %cvs = []
            %[cvs.append(item) for item in elt.custom_views if item not in cvs]
            %for cvname in cvs:
            <div class="tab-pane fade {{_go_active}} {{_go_fadein}}" data-cv-name="{{cvname}}" data-elt-name='{{elt.get_full_name()}}' id="cv{{cvname}}">
               Cannot load the pane {{cvname}}.
            </div>
            %_go_active = ''
            %_go_fadein = ''
            %end
            %end
            <!-- Tab custom views end -->

            <!-- Tab Summary Start-->
            %if params['tab_impacts']=='yes':
            <div class="tab-pane fade {{_go_active}} {{_go_fadein}}" id="impacts">
               <div class='row-fluid well col-lg-12'>
               
                  <div class="row-fluid">
                     <div class="col-lg-12">
                        <!-- Show our father dependencies if we got some -->
                        %if len(elt.parent_dependencies) > 0:
                        <h4>Root cause:</h4>
                        <button name="togglelink-{{elt.get_dbg_name()}}" class="col-lg-2 btn" data-toggle="tooltip" data-placement="bottom" title="Show dependency tree">{{elt.state}} <i class='fa fa-plus'></i> Show dependency tree</button>
                        <script>
                           $('button[name="togglelink-{{elt.get_dbg_name()}}"]').click(function () {
                              toggleBusinessElt('{{elt.get_dbg_name()}}');
                           });
                        </script>

                        <!--
                        <a id="togglelink-{{elt.get_dbg_name()}}" href="javascript:toggleBusinessElt('{{elt.get_dbg_name()}}')"> {{!helper.get_button('Show dependency tree', img='/static/images/expand.png')}}</a>
                        -->
                        <div class="clear"></div>
                        {{!helper.print_business_rules(datamgr.get_business_parents(elt), source_problems=elt.source_problems)}}
                        %end

                        <!-- If we are an host and not a problem, show our services -->
                        %if elt_type=='host' and not elt.is_problem:
                        %if len(elt.services) > 0:
                        %if len(elt.parent_dependencies) > 0:
                        <!-- Only if we displayed parent's dependencies ... -->
                        <hr/>
                        %end
                        <h4>My services:</h4>
                        <div class="host-services">
                           <div class='pull-left'>
                              {{!helper.print_aggregation_tree(helper.get_host_service_aggregation_tree(elt, app), helper.get_html_id(elt))}}
                           </div>
                        </div>
                        %elif len(elt.parent_dependencies) == 0:
                        <div class="alert alert-info">
                           <p class="font-blue">No services available</p>
                        </div>
                        %end
                        %end #of the only host part

                        <!-- If we are a root problem and got real impacts, show them! -->
                        %if elt.is_problem and len(elt.impacts) != 0:
                        %if len(elt.parent_dependencies) > 0:
                        <!-- Only if we displayed parent's dependencies ... -->
                        <hr/>
                        %end
                        <h4>My impacts:</h4>
                        <div class='host-services'>
                           %max_impacts_displayed = int(params['cfg_nb_impacts'])
                           %nb = 0
                           %for i in helper.get_impacts_sorted(elt):
                              %nb += 1
                              %if nb == max_impacts_displayed+1:
                              <div class="pull-right" id="hidden_impacts_or_services_button">
%###
%### To be replaced !
!helper.get_button('Show dependency tree', img='/static/images/expand.png')
%###
%###
                                 <a href="javascript:show_hidden_impacts_or_services()"> {{!helper.get_button('Show all impacts', img='/static/images/expand.png')}}</a>
                              </div>
                              %end
                              <div class=" {{"hidden_impacts_services" if nb > max_impacts_displayed else ""}}">
                                 <div>
                                    <img style="width:16px; height:16px" alt="icon state" src="{{helper.get_icon_state(i)}}">
                                    <span class='alert-small alert-{{i.state.lower()}}' style="font-size:110%">{{i.state}}</span> for <span style="font-size:110%">{{!helper.get_link(i, short=True)}}</span> since {{helper.print_duration(i.last_state_change, just_duration=True, x_elts=2)}}
                                    {{!helper.get_business_impact_text(i.business_impact)}}
                                 </div>
                              </div>
                           %end
                        </div>
                        %# end of the 'is problem' if
                        %end
                     </div>
                  </div>
               </div>
            </div>
            %end
            <!-- Tab Summary End-->

            <!-- Tab Comments Start -->
            %if params['tab_comments']=='yes':
            <div class="tab-pane fade" id="comments">
               <div class='row-fluid well col-lg-12'>
                  <div class="row-fluid">
                     %if len(elt.comments) > 0:
                     <table class="table table-condensed table-hover">
                        <thead>
                           <tr>
                              <th class="col-lg-2">Author</th>
                              <th class="col-lg-6">Comment</th>
                              <th class="col-lg-3">Date</th>
                              <th class="col-lg-1"></th>
                           </tr>
                        </thead>
                        <tbody>
                        %for c in elt.comments:
                           <tr>
                              <td>{{c.author}}</td>
                              <td>{{c.comment}}</td>
                              <td>{{helper.print_date(c.entry_time)}} - {{helper.print_date(c.expire_time)}}</td>
                              <td><a class="fa fa-trash-o {{global_disabled}} font-red" href="javascript:delete_comment('{{elt.get_full_name()}}', {{c.id}})"></a></td>
                           </tr>
                        %end
                        </tbody>
                     </table>

                     %else:
                     <div class="alert alert-info">
                        <p class="font-blue">No comments available.</p>
                     </div>
                     %end
                  </div>
                  
                  <button name="bt-add-comment" data-toggle="modal" data-target="#modal" class="btn btn-primary btn-sm"><i class="fa fa-plus"></i> Add a comment</button>
                  <button name="bt-delete-comments" data-toggle="modal" data-target="#modal" class="btn btn-primary btn-sm"><i class="fa fa-minus"></i> Delete all comments</button>
                  <script>
                    $('button[name="bt-add-comment"]').click(function () {
                      stop_refresh();
                      $('#modal').modal({
                        keyboard: true,
                        show: true,
                        backdrop: 'static',
                        remote: "/forms/comment/{{helper.get_uri_name(elt)}}"
                      });
                    });
                    $('button[name="bt-delete-comments"]').click(function () {
                      stop_refresh();
                      $('#modal').modal({
                        keyboard: true,
                        show: true,
                        backdrop: 'static',
                        remote: "/forms/comment_delete/{{helper.get_uri_name(elt)}}"
                      });
                    });
                  </script>
               </div>
            </div>
            %end
            <!-- Tab Comments End -->

            <!-- Tab Downtimes Start -->
            %if params['tab_downtimes']=='yes':
            <div class="tab-pane fade" id="downtimes">
               <div class='row-fluid well col-lg-12'>
                  <div class="row-fluid">
                     %if len(elt.downtimes) > 0:
                     <table class="table table-condensed table-bordered">
                       <thead>
                        <tr>
                          <th class="col-lg-2">Author</th>
                          <th class="col-lg-5">Reason</th>
                          <th class="col-lg-5">Period</th>
                          <th class="col-lg-1"></th>
                        </tr>
                       </thead>
                       <tbody>
                        %for dt in elt.downtimes:
                        <tr>
                          <td>{{dt.author}}</td>
                          <td>{{dt.comment}}</td>
                          <td>{{helper.print_date(dt.start_time)}} - {{helper.print_date(dt.end_time)}}</td>
                          <td><a class="fa fa-trash-o {{global_disabled}} font-red" href="javascript:delete_downtime('{{elt.get_full_name()}}', {{dt.id}})"></a></td>
                        </tr>
                        %end
                       </tbody>
                     </table>
                     %else:
                     <div class="alert alert-info">
                        <p class="font-blue">No downtimes available.</p>
                     </div>
                     %end
                  </div>
                  
                  <button name="bt-schedule-downtime" data-toggle="modal" data-target="#modal" class="btn btn-primary btn-sm"><i class="fa fa-plus"></i> Add a downtime</button>
                  <button name="bt-delete-downtimes" data-toggle="modal" data-target="#modal" class="btn btn-primary btn-sm"><i class="fa fa-minus"></i> Delete all downtimes</button>
                  <script>
                    $('button[name="bt-schedule-downtime"]').click(function () {
                      stop_refresh();
                      $('#modal').modal({
                        keyboard: true,
                        show: true,
                        backdrop: 'static',
                        remote: "/forms/downtime/{{helper.get_uri_name(elt)}}"
                      });
                    });
                    $('button[name="bt-delete-downtimes"]').click(function () {
                      stop_refresh();
                      $('#modal').modal({
                        keyboard: true,
                        show: true,
                        backdrop: 'static',
                        remote: "/forms/downtime_delete/{{helper.get_uri_name(elt)}}"
                      });
                    });
                  </script>
               </div>
            </div>
            %end
            <!-- Tab Downtimes End -->

            <!-- Tab Timeline Start -->
            %if params['tab_timeline']=='yes':
            <div class="tab-pane fade" id="timeline">
               <div class="row-fluid well col-lg-12">
                  <div id="inner_timeline" data-elt-name='{{elt.get_full_name()}}'>
                     <span class="alert alert-error">Sorry, I cannot load the timeline graph!</span>
                  </div>
               </div>
            </div>
            %end
            <!-- Tab Graph End -->

            <!-- Tab Graph Start -->
            %if params['tab_graphs']=='yes':
            <div class="tab-pane fade" id="graphs">
               %# Set source as '' or module ui-graphite will try to fetch templates from default 'detail'
               %uris = app.get_graph_uris(elt, graphstart, graphend, '')
               %if len(uris) == 0:
               <div class="alert alert-info">
                   <div class="font-blue"><strong>Oh snap!</strong> No graphs available!</div>
               </div>
               <script language="javascript">
                  $('#tab_to_graphs').hide();
               </script>
               %else:
               <!-- <h4>Graphs</h4> -->
               <div class='row-fluid well col-lg-12'>
                  <!-- Get the uris for the 5 standard time ranges in advance  -->
                  %now = int(time.time())
                  %fourhours = now - 3600*4
                  %lastday =   now - 86400
                  %lastweek =  now - 86400*7
                  %lastmonth = now - 86400*31
                  %lastyear =  now - 86400*365

                  %# Let's get all the uris at once.
                  %# Set source as '' or module ui-graphite will trye to fetch from default 'detail'
                  %uris_4h = app.get_graph_uris(elt, fourhours, now, '')
                  %uris_1d = app.get_graph_uris(elt, lastday, now, '')
                  %uris_1w = app.get_graph_uris(elt, lastweek, now, '')
                  %uris_1m = app.get_graph_uris(elt, lastmonth, now, '')
                  %uris_1y = app.get_graph_uris(elt, lastyear, now, '')

                  <!-- Use of javascript to change the content of a div!-->
                  <div class='col-lg-2 cursor'><a onclick="setHTML(html_4h,{{fourhours}});" > 4 hours</a></div>
                  <div class='col-lg-2 cursor'><a onclick="setHTML(html_1d,{{lastday}});" > 1 day</a></div>
                  <div class='col-lg-2 cursor'><a onclick="setHTML(html_1w,{{lastweek}});" > 1 week</a></div>
                  <div class='col-lg-2 cursor'><a onclick="setHTML(html_1m,{{lastmonth}});" > 1 month</a></div>
                  <div class='col-lg-2 cursor'><a onclick="setHTML(html_1y,{{lastyear}});" > 1 year</a></div>
               </div>

               <script language="javascript">
               function setHTML(html,start) {
                  <!-- change the content of the div --!>
                  $("real_graphs").innerHTML=html;

                  <!-- and call the jcrop javascript --!>
                  $('.jcropelt').Jcrop({
                     onSelect: update_coords,
                     onChange: update_coords
                  });
                  graphstart=start;
                  get_range();
               }

               <!-- let's create the html content for each time range --!>
               <!-- This is quite ugly here. I do the same thing 4 times --!->
               <!-- someone said "function" ? You're right.--!>
               <!-- but the mix between python and javascript is not a easy thing for me --!>
               html_4h='<p>';
               html_1d='<p>';
               html_1w='<p>';
               html_1m='<p>';
               html_1y='<p>';

               %for g in uris_4h:
               %(img_src, link) = app.get_graph_img_src( g['img_src'], g['link'])
               var img_src="{{img_src}}";
               html_4h = html_4h + '<img src="'+ img_src.replace("'","\'") +'" class="jcropelt"/>';
               html_4h = html_4h + '<a href="{{link}}" class="btn"><i class="fa fa-plus"></i> Show more</a>';
               html_4h = html_4h + '<a href="javascript:graph_zoom(\'/{{elt_type}}/{{elt.get_full_name()}}?\')" class="btn"><i class="icon-zoom-in"></i> Zoom</a>';
               html_4h = html_4h + '<br>';
               %end
               html_4h=html_4h+'</p>';

               %for g in uris_1d:
               %(img_src, link) = app.get_graph_img_src( g['img_src'], g['link'])
               var img_src="{{img_src}}";
               html_1d = html_1d +'<img src="'+ img_src.replace("'","\'") +'" class="jcropelt"/>';
               html_1d = html_1d + '<a href={{link}}" class="btn"><i class="fa fa-plus"></i> Show more</a>';
               html_1d = html_1d + '<a href="javascript:graph_zoom(\'/{{elt_type}}/{{elt.get_full_name()}}?\')" class="btn"><i class="icon-zoom-in"></i> Zoom</a>';
               html_1d = html_1d + '<br>';
               %end
               html_1d=html_1d+'</p>';

               %for g in uris_1w:
               %(img_src, link) = app.get_graph_img_src( g['img_src'], g['link'])
               var img_src="{{img_src}}";
               html_1w = html_1w + '<img src="'+ img_src.replace("'","\'") +'" class="jcropelt"/>';
               html_1w = html_1w + '<a href="{{link}}" class="btn"><i class="fa fa-plus"></i> Show more</a>';
               html_1w = html_1w + '<a href="javascript:graph_zoom(\'/{{elt_type}}/{{elt.get_full_name()}}?\')" class="btn"><i class="icon-zoom-in"></i> Zoom</a>';
               html_1w = html_1w + '<br>';
               %end

               %for g in uris_1m:
               %(img_src, link) = app.get_graph_img_src( g['img_src'], g['link'])
               var img_src="{{img_src}}";
               html_1m = html_1m + '<img src="'+ img_src.replace("'","\'") +'" class="jcropelt"/>';
               html_1m = html_1m + '<a href="{{link}}" class="btn"><i class="fa fa-plus"></i> Show more</a>';
               html_1m = html_1m + '<a href="javascript:graph_zoom(\'/{{elt_type}}/{{elt.get_full_name()}}?\')" class="btn"><i class="icon-zoom-in"></i> Zoom</a>';
               html_1m = html_1m + '<br>';
               %end

               %for g in uris_1y:
               %(img_src, link) = app.get_graph_img_src( g['img_src'], g['link'])
               var img_src="{{img_src}}";
               html_1y = html_1y + '<img src="'+ img_src.replace("'","\'") +'" class="jcropelt"/>';
               html_1y = html_1y + '<a href="{{link}}" class="btn"><i class="fa fa-plus"></i> Show more</a>';
               html_1y = html_1y + '<a href="javascript:graph_zoom(\'/{{elt_type}}/{{elt.get_full_name()}}?\')" class="btn"><i class="icon-zoom-in"></i> Zoom</a>';
               html_1y = html_1y + '<br>';
               %end
               </script>

               <div class='row-fluid well col-lg-12 jcrop'>
                  <div id='real_graphs'>
                  <!-- Let's keep this part visible. This is the custom and default range -->
                  %for g in uris:
                     %(img_src, link) = app.get_graph_img_src( g['img_src'], g['link'])
                     <p>
                        <img src="{{img_src}}" class="jcropelt"/>
                        <a href="{{link}}" class="btn"><i class="fa fa-plus"></i> Show more</a>
                        <a href="javascript:graph_zoom('/{{elt_type}}/{{elt.get_full_name()}}?')" class="btn"><i class="icon-zoom-in"></i> Zoom</a>
                     </p>
                  %end      
                  </div>
               </div>
               %end
            </div>
            %end
            <!-- Tab Graph End -->

            <!-- Tab Dep graph Start -->
            %if params['tab_depgraph']=='yes':
            <script>
            $(function() {
               $('#supported').text('Supported/allowed: ' + !!screenfull.enabled);
               if (!screenfull.enabled) {
                  return false;
               }

               $('#fullscreen-request').click(function() {
                  screenfull.request($('#inner_depgraph')[0]);
               });

               // Trigger the onchange() to set the initial values
               screenfull.onchange();
            });
            </script>
            <div class="tab-pane fade" id="depgraph" class="col-lg-12">
               <div class='row-fluid well col-lg-12 jcrop'>
                  <div class="btn-group btn-group-sm pull-right">
                     <button id="fullscreen-request" class="btn btn-primary"><i class="fa fa-plus"></i> Fullscreen</button>
                  </div>
                  <div id="inner_depgraph" data-elt-name='{{elt.get_full_name()}}'>
                     <span class="alert alert-error">Sorry, I cannot load the dependency graph!</span>
                  </div>
               </div>
            </div>
            %end
            <!-- Tab Dep graph End -->
        
            <!-- Tab History Start -->
            %if params['tab_history']=='yes':
            <div class="tab-pane fade" id="history">
               <div class="row-fluid well col-lg-12">
                  <div id="inner_history" data-elt-name='{{elt.get_full_name()}}'>
                     <div class="alert alert-danger">
                        <p class="font-red">Sorry, I cannot load the {{elt_type}} history!</p>
                     </div>
                  </div>
               </div>
            </div>
            %end
            <!-- Tab History End -->
         </div>
      <!-- Detail info box end -->
      </div>
   </div>


%#End of the element exist or not case
%end
