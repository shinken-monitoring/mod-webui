%import time
%import re
%now = int(time.time())

%if app.request.GET.get('modal','false') == 'true':
%modal=True
<script type="text/javascript">
  // :TODO:maethor:240908: Move ths JS in dedicated JS file
  var listOfURL = [];
  $('#problems .selected').each(function(entry) {
    listOfURL.push($(this).data('link'));
  });
  if (listOfURL.length == 0) {
    $('#problems .js-select-elt').each(function(entry) {
      listOfURL.push($(this).data('link'));
    });
  }
  currentItem = $('#modal').data('link').replace('?modal=true','');

  index = listOfURL.indexOf(currentItem);
  nextItem = listOfURL[index + 1];
  previousItem = listOfURL[index - 1];
  if (typeof previousItem == 'undefined') {
    previousItem = listOfURL[listOfURL.length - 1]
  }
  if (typeof nextItem == 'undefined') {
    nextItem = listOfURL[0]
  }
  if (nextItem != currentItem) {
    $('#modal-previous-elt').attr('href', previousItem);
    $('#modal-next-elt').attr('href', nextItem);
  } else {
    $('#modal-previous-elt').hide();
    $('#modal-next-elt').hide();
  }
</script>
%else:
%modal=False
%end

%if not elt:
%if not modal:
%rebase("layout", title='Invalid element name')
%end

Invalid element name

%else:
%user = app.get_user()
%helper = app.helper

%from shinken.macroresolver import MacroResolver

%elt_type = elt.__class__.my_type

%if elt_type == 'host':
%breadcrumb = [[elt.display_name if elt.display_name else elt.get_name(), '/host/'+elt.host_name]]
%search_string = 'host:' + elt.host_name
%elif elt_type == 'service':
%breadcrumb = [[elt.host.display_name if elt.host.display_name else elt.host.get_name(), '/host/'+elt.host_name]]
%breadcrumb += [[elt.display_name, '/service/'+helper.get_uri_name(elt)]]
%search_string = 'host:%s service:%s' % (elt.host_name, elt.display_name)
%end

%js=['js/jquery.sparkline.min.js', 'js/shinken-charts.js', 'cv_host/js/flot/jquery.flot.min.js', 'cv_host/js/flot/jquery.flot.tickrotor.js', 'cv_host/js/flot/jquery.flot.resize.min.js', 'cv_host/js/flot/jquery.flot.pie.min.js', 'cv_host/js/flot/jquery.flot.categories.min.js', 'cv_host/js/flot/jquery.flot.time.min.js', 'cv_host/js/flot/jquery.flot.stack.min.js', 'cv_host/js/flot/jquery.flot.valuelabels.js', 'eltdetail/js/custom_views.js', 'eltdetail/js/eltdetail.js', 'logs/js/history.js']
%if app.logs_module.is_available():
%js=js + ['availability/js/justgage.js', 'availability/js/raphael-2.1.4.min.js']
%end
%css=['eltdetail/css/eltdetail.css', 'cv_host/css/cv_host.css', 'problems/css/problems.css']

%if not modal:
%rebase("layout", js=js, css=css, breadcrumb=breadcrumb, title=elt_type.title()+' detail: ' + elt.get_full_name())
%end

<div class="modal-header">

  <div class="row">
    <div class="col-xs-8 col-sm-9 col-md-10">
      <div class="status-lead" style="margin-left: 10px;">
        <table>
          <tr>
            <td class="text-center" style="min-width: 50px;">
              {{!helper.get_fa_icon_state(elt)}}
            </td>
            <td>
              <h4 style="padding-left: 20px;">
                %if elt_type == 'service':
                <a onclick="display_modal('/host/{{ elt.host_name }}?modal=true', 'xl')">{{ elt.host.display_name if elt.host.display_name else elt.host.get_name() }}</a>:
                %end
                {{ elt.display_name }}
                %if elt_type == 'host':
                ({{ elt.address }})
                %end
              </h4>
            </td>
          </tr>
          <tr>
            <td class="font-{{elt.state.lower()}} text-center" style="vertical-align: top !important;">
              <strong>{{ elt.state }}</strong><br>
              <span title="Since {{time.strftime("%d %b %Y %H:%M:%S", time.localtime(elt.last_state_change))}}">
                <small>
                  %if elt.state_type == 'HARD':
                  {{!helper.print_duration(elt.last_state_change, just_duration=True, x_elts=2)}}
                  %else:
                  attempt {{elt.attempt}}/{{elt.max_check_attempts}}
                  <!--soft state-->
                  %end
                </small>
              </span>
            </td>
            <td style="vertical-align: top !important; padding-left: 20px;">
              <samp>{{elt.output}}{{! '<br/>'+elt.long_output.replace('\n', '<br/>') if elt.long_output else ''}}</samp>
              <div>
                %if elt.problem_has_been_acknowledged:
                <p style="margin-top: 10px;"><samp><i class="fas fa-check"></i> {{ helper.get_acknowledge_comment(elt) }}</samp></p>
                %end
                %if elt.in_scheduled_downtime:
                <p style="margin-top: 10px;">
                  %for d in helper.get_downtime_comments(elt):
                  <samp><i class="far fa-clock"></i> {{! d }}</samp><br>
                  %end
                </p>
                %end
              </div>
            </td>
          </tr>
        </table>
      </div>
    </div>

    <div class="col-xs-4 col-sm-3 col-md-2">
      <div class="pull-right pb_detail-action-buttons">
        %if modal:
        <div>
        <a id="modal-previous-elt" class="btn btn-lg btn-ico btn-action js-open-elt" title="Previous element" href=""><i class="fas fa-backward"></i></a>
        <a id="modal-next-elt" class="btn btn-lg btn-ico btn-action js-open-elt" title="Next element" href=""><i class="fas fa-forward"></i></a>
        <button class="btn btn-lg btn-ico btn-action" data-dismiss="modal" aria-label="Close" title="Close this window"><i class="fas fa-times"></i></button>
        </div>
        %end
        <div>
        %if app.can_action():
        <button class="btn btn-lg btn-ico btn-action js-recheck"
          title="Recheck"
          data-element="{{helper.get_uri_name(elt)}}">
          <i class="fas fa-sync"></i>
        </button>
        %if elt.state != elt.ok_up and not elt.problem_has_been_acknowledged:
        <button class="btn btn-lg btn-ico btn-action js-add-acknowledge"
          title="Acknowledge this problem"
          data-element="{{helper.get_uri_name(elt)}}">
          <i class="fas fa-check"></i>
        </button>
        %end
        <div class="dropdown" style="display: inline;">
          <button class="btn btn-lg btn-ico btn-action dropdown-toggle" type="button" id="dropdown-downtime-{{ helper.get_html_id(elt) }}" data-toggle="dropdown"
            title="Schedule a downtime for this element"
            data-element="{{helper.get_uri_name(elt)}}">
            <i class="far fa-clock"></i>
          </button>
          <ul class="dropdown-menu dropdown-menu-right" aria-labelledby="dropdown-downtime-{{ helper.get_html_id(elt) }}" style="margin-top: 15px;">
            <li class="dropdown-header">Set a downtime for…</li>
            <li role="separator" class="divider"></li>
            <li><a href="#" class="js-schedule-downtime" data-element="{{helper.get_uri_name(elt)}}" data-duration="60">1 hour</a></li>
            <li><a href="#" class="js-schedule-downtime" data-element="{{helper.get_uri_name(elt)}}" data-duration="180">3 hours</a></li>
            <li><a href="#" class="js-schedule-downtime" data-element="{{helper.get_uri_name(elt)}}" data-duration="720">12 hours</a></li>
            <li><a href="#" class="js-schedule-downtime" data-element="{{helper.get_uri_name(elt)}}" data-duration="1440">24 hours</a></li>
            <li><a href="#" class="js-schedule-downtime" data-element="{{helper.get_uri_name(elt)}}" data-duration="2880">3 days</a></li>
            <li><a href="#" class="js-schedule-downtime" data-element="{{helper.get_uri_name(elt)}}" data-duration="10080">7 days</a></li>
            <li><a href="#" class="js-schedule-downtime" data-element="{{helper.get_uri_name(elt)}}" data-duration="43200">30 days</a></li>
            <li role="separator" class="divider"></li>
            <li><a href="#" class="js-schedule-downtime" data-element="{{helper.get_uri_name(elt)}}">Custom timeperiod</a></li>
          </ul>
        </div>
        %if elt.event_handler_enabled and elt.event_handler:
        <button class="btn btn-lg btn-ico btn-action js-try-to-fix"
          title="Try to fix (launch event handler)"
          data-element="{{helper.get_uri_name(elt)}}">
          <i class="fas fa-magic"></i>
        </button>
        %end
        <button class="btn btn-lg btn-ico btn-action js-submit-ok"
          title="Submit a check result"
          data-element="{{helper.get_uri_name(elt)}}">
          <i class="fas fa-share"></i>
        </button>
        %end
        </div>
      </div>
      <div class="clearfix">
      </div>
    </div>

  </div>

  <!--<h3 class="modal-title">{{ elt.get_full_name() }}</h3>-->


%if modal:
<div class="modal-body">
%end

<div id="element" class="row container-fluid">

  %for dep in elt.child_dependencies:
  <!--{{ dep.host_name }}/{{ dep.get_name() }}<br>-->
  %end

   %setdefault('debug', False)
   %if debug:
   <div class="panel-group">
      <div class="panel panel-default">
         <div class="panel-heading">
            <h4 class="panel-title">
               <a data-toggle="collapse" href="#collapse_{{elt.id}}"><i class="fas fa-bug"></i> Host as dictionary</a>
            </h4>
         </div>
         <div id="collapse_{{elt.id}}" class="panel-collapse collapse">
            <dl class="dl-horizontal" style="height: 200px; overflow-y: scroll;">
               %for k in sorted(elt.__slots__):
                  %v=getattr(elt, k, 'unset')
                  <dt>{{k}}</dt>
                  <dd>{{v}}</dd>
               %end
            </dl>
            <dl class="dl-horizontal" style="height: 100px; overflow-y: scroll;">
               %for k,v in sorted(elt.__dict__.items()):
                  <dt>{{k}}</dt>
                  <dd>{{v}}</dd>
               %end
            </dl>
         </div>
      </div>
      %if elt_type == 'host':
      <div class="panel panel-default">
         <div class="panel-heading">
            <h4 class="panel-title">
               <a data-toggle="collapse" href="#collapse_{{elt.id}}_services"><i class="fas fa-bug"></i> Host services as dictionary</a>
            </h4>
         </div>
         <div id="collapse_{{elt.id}}_services" class="panel-collapse collapse" style="height: 200px; margin-left:20px;">
            %for service in elt.services:
            <div class="panel panel-default">
               <div class="panel-heading">
                  <h4 class="panel-title">
                     <a data-toggle="collapse" href="#collapse{{service.id}}_services"><i class="fas fa-bug"></i> Service: {{service.get_name()}}</a>
                  </h4>
               </div>
               <div id="collapse{{service.id}}_services" class="panel-collapse collapse" style="height: 200px;">
                  <dl class="dl-horizontal" style="height: 200px; overflow-y: scroll;">
                     %for k in sorted(service.__slots__):
                        %v=getattr(elt, k, 'unset')
                        <dt>{{k}}</dt>
                        <dd>{{v}}</dd>
                     %end
                  </dl>
                  <dl class="dl-horizontal" style="height: 100px; overflow-y: scroll;">
                     %for k,v in sorted(service.__dict__.items()):
                        <dt>{{k}}</dt>
                        <dd>{{v}}</dd>
                     %end
                  </dl>
               </div>
            </div>
            %end
         </div>
      </div>
      %end
   </div>
   %end


   %if not modal and app.can_action() and elt.is_problem and elt.business_impact >= app.important_problems_business_impact and not elt.problem_has_been_acknowledged:
   %disabled_ack = '' if not elt.problem_has_been_acknowledged else 'disabled'
   %disabled_fix = '' if elt.event_handler_enabled and elt.event_handler else 'disabled'
   <div class="alert alert-danger">
      <i class="fas fa-warning"></i> This element has an important impact on your business, you may
      <a href="#" class="{{disabled_ack}} btn btn-primary btn-xs js-add-acknowledge"
         title="Acknowledge this {{elt_type}} problem" data-element="{{helper.get_uri_name(elt)}}">
         <i class="fas fa-check"></i> acknowledge it</a>
      or
      <a href="#" class="{{disabled_fix}} btn btn-primary btn-xs js-try-to-fix"
         title="Launch the event handler for this {{elt_type}}" data-element="{{helper.get_uri_name(elt)}}">
         <i class="fas fa-magic"></i> try to fix it</a>.
   </div>
   %end

   %if elt.got_business_rule:
   <div class="alert alert-warning"><i class="fas fa-warning"></i> This element is a business rule.</div>
   %end

   %if elt_type=='host':
   %s = app.datamgr.get_services_synthesis(elt.services, user)
   <div class="panel panel-default">
     <div class="panel-body">
       <table class="table table-invisible table-condensed">
         <tbody>
           <tr>
             <td>
               <a role="menuitem" href="/all?search=type:service {{ elt.host_name }}">
                  <b>{{s['nb_elts']}} services:&nbsp;</b>
               </a>
             </td>

             %for state in 'ok', 'warning', 'critical', 'pending', 'unknown', 'ack', 'downtime':
             <td>
               %if s['nb_' + state]>0:
               <a role="menuitem" href="/all?search=type:service is:{{state}} {{ elt.host_name }}">
               %end
                  %label = "<span title='%s%%'>%s" % (s['pct_' + state], s['nb_' + state])
                  {{!helper.get_fa_icon_state_and_label(cls='service', state=state, label=label, disabled=(not s['nb_' + state]))}}
               %if s['nb_' + state]>0:
               </a>
               %end
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
            %if app.graphs_module.is_available():
            <li id="tab-graphs"><a href="#graphs" data-toggle="tab">Graphs</a></li>
            %_go_active = ''
            %end
            <li id="tab-information"><a href="#information" data-toggle="tab">Information</a></li>
            <li><a href="#impacts" data-toggle="tab">{{'Services' if elt_type == 'host' else 'Impacts'}}</a></li>
            %if elt.customs:
            <li><a href="#configuration" data-toggle="tab">Configuration</a></li>
            %end
            <li><a href="#comments" data-toggle="tab">Comments</a></li>
            <li><a href="#downtimes" data-toggle="tab">Downtimes</a></li>
            %if app.logs_module.is_available():
            %if not modal:
            <li><a href="#history" data-toggle="tab">History</a></li>
            %else:
            <li><a href="{{ helper.get_link_dest(elt) }}#history"><i class="fas fa-arrow-right"></i> History</a></li>
            %end
            <!--%if app.logs_module.is_available() and elt_type=='host':-->
            <!--%if not modal:-->
            <!--<li><a href="#availability" data-toggle="tab">Availability</a></li>-->
            <!--%else:-->
            <!--<li><a href="{{ helper.get_link_dest(elt) }}#availability"><i class="fas fa-arrow-right"></i> Availability</a></li>-->
            <!--%end-->
            <!--%end-->
            %if app.helpdesk_module.is_available():
            %if not modal:
            <li><a href="#helpdesk" data-toggle="tab">Helpdesk</a></li>
            %else:
            <li><a href="{{ helper.get_link_dest(elt) }}#helpdesk"><i class="fas fa-arrow-right"></i> Helpdesk</a></li>
            %end
            %end
         </ul>

         <div class="tab-content">
            %if app.graphs_module.is_available():
            %# Set source as '' or module ui-graphite will try to fetch templates from default 'detail'
            %graph_uris = app.graphs_module.get_graph_uris(elt, graphstart=graphstart, graphend=graphend)
            %include("_eltdetail_graphs.tpl")
            %end
            %include("_eltdetail_information.tpl")
            %include("_eltdetail_impacts.tpl")
            %if elt.customs:
            %include("_eltdetail_configuration.tpl")
            %end
            %include("_eltdetail_comments.tpl")
            %include("_eltdetail_downtimes.tpl")
            %if app.logs_module.is_available():
            %include("_eltdetail_history.tpl")
            %end
            %if app.logs_module.is_available() and elt_type=='host':
            %include("_eltdetail_availability.tpl")
            %end
            %if app.helpdesk_module.is_available():
            %include("_eltdetail_helpdesk.tpl")
            %end

            %if app.graphs_module.is_available() and graph_uris:
            <script>
              $("#tab-graphs").addClass('active');
              $("#graphs").addClass('active in');
            </script> 
            %else:
            <script>
              $("#tab-information").addClass('active');
              $("#information").addClass('active in');
            </script> 
            %end

         </div>
      <!-- Detail info box end -->
   </div>
</div>

%if modal:
</div>
%end

%end
