%import time
%import re
%now = int(time.time())

%if not elt:
%rebase("layout", title='Invalid element name')

Invalid element name

%else:
%user = app.get_user()
%helper = app.helper

%from shinken.macroresolver import MacroResolver

%elt_type = elt.__class__.my_type

%breadcrumb = [['All '+elt_type.title()+'s', '/'+elt_type+'s-groups']]
%if elt_type == 'host':
%breadcrumb += [[elt.display_name if elt.display_name else elt.get_name(), '/host/'+elt.host_name]]
%elif elt_type == 'service':
%breadcrumb += [[elt.host.display_name if elt.host.display_name else elt.host.get_name(), '/host/'+elt.host_name]]
%breadcrumb += [[elt.display_name, '/service/'+helper.get_uri_name(elt)]]
%end

%js=['js/shinken-actions.js', 'js/jquery.sparkline.min.js', 'js/shinken-charts.js', 'availability/js/justgage.js', 'availability/js/raphael-2.1.4.min.js', 'cv_host/js/flot/jquery.flot.min.js', 'cv_host/js/flot/jquery.flot.tickrotor.js', 'cv_host/js/flot/jquery.flot.resize.min.js', 'cv_host/js/flot/jquery.flot.pie.min.js', 'cv_host/js/flot/jquery.flot.categories.min.js', 'cv_host/js/flot/jquery.flot.time.min.js', 'cv_host/js/flot/jquery.flot.stack.min.js', 'cv_host/js/flot/jquery.flot.valuelabels.js', 'eltdetail/js/custom_views.js', 'eltdetail/js/eltdetail.js']
%css=['eltdetail/css/eltdetail.css', 'cv_host/css/cv_host.css']

%rebase("layout", js=js, css=css, breadcrumb=breadcrumb, title=elt_type.title()+' detail: ' + elt.get_full_name())

<div id="element" class="row container-fluid">
   %if app.can_action() and elt.is_problem and elt.business_impact > 2 and not elt.problem_has_been_acknowledged:
   %disabled_ack = '' if not elt.problem_has_been_acknowledged else 'disabled'
   %disabled_fix = '' if elt.event_handler_enabled and elt.event_handler else 'disabled'
   <div class="alert alert-danger"><i class="fa fa-warning"></i> This element has an important impact on your business, you may
     <a href="#" class="{{disabled_ack}} btn btn-primary btn-xs js-add-acknowledge" title="Acknowledge this {{elt_type}} problem" data-element="{{helper.get_uri_name(elt)}}"><i class="fa fa-check"></i> acknowledge it</a>
     or
     <a href="#" class="{{disabled_fix}} btn btn-primary btn-xs js-try-to-fix" title="Launch the event handler for this {{elt_type}}" data-element="{{helper.get_uri_name(elt)}}"><i class="fa fa-magic"></i> try to fix it</a>.</div>
   %end

   %if elt.get_check_command().startswith('bp_rule'):
   <div class="alert alert-warning"><i class="fa fa-warning"></i> This element is a business rule.</div>
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
                  %label = "%s <i>(%s%%)</i>" % (s['nb_' + state], s['pct_' + state])
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
            %_go_active = 'active'
            %for cvname in elt.custom_views:
               %cvconf = 'default'
               %if '/' in cvname:
                  %cvconf = cvname.split('/')[1]
                  %cvname = cvname.split('/')[0]
               %end
               <li class="{{_go_active}} cv_pane" data-name="{{cvname}}" data-conf="{{cvconf}}" data-element='{{elt.get_full_name()}}' id='tab-cv-{{cvname}}-{{cvconf}}'><a href="#cv{{cvname}}_{{cvconf}}" data-toggle="tab">{{cvname.capitalize()}}{{'/'+cvconf.capitalize() if cvconf!='default' else ''}}</a></li>
               %_go_active = ''
            %end

            <li class="{{_go_active}}"><a href="#information" data-toggle="tab">Information</a></li>
            <li><a href="#impacts" data-toggle="tab">{{'Services' if elt_type == 'host' else 'Impacts'}}</a></li>
            %if user.is_administrator() and elt.customs:
            <li><a href="#configuration" data-toggle="tab">Configuration</a></li>
            %end
            <li><a href="#comments" data-toggle="tab">Comments</a></li>
            <li><a href="#downtimes" data-toggle="tab">Downtimes</a></li>
            <!--<li class="timeline_pane"><a href="#timeline" data-toggle="tab">Timeline</a></li>-->
            %if app.graphs_module.is_available():
            <li><a href="#graphs" data-toggle="tab">Graphs</a></li>
            %end
            <!--<li><a href="#depgraph" data-toggle="tab">Impact graph</a></li>-->
            %if app.logs_module.is_available():
            <li><a href="#history" data-toggle="tab">History</a></li>
            %end
            %if app.logs_module.is_available() and elt_type=='host':
            <li><a href="#availability" data-toggle="tab">Availability</a></li>
            %end
            %if app.helpdesk_module.is_available():
            <li><a href="#helpdesk" data-toggle="tab">Helpdesk</a></li>
            %end
         </ul>

         <div class="tab-content">
            <!-- Tab custom views -->
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
                        <!--<span class="alert alert-error">Sorry, I cannot load the {{cvname}}/{{cvconf}} view!</span>-->
                     </div>
                  </div>
               </div>
               %_go_active = ''
               %_go_fadein = ''
            %end
            <!-- Tab custom views end -->

            %include("_eltdetail_information.tpl")
            %include("_eltdetail_impacts.tpl")
            %include("_eltdetail_configuration.tpl")
            %include("_eltdetail_comments.tpl")
            %include("_eltdetail_downtimes.tpl")
            %include("_eltdetail_graphs.tpl")
            %#include("_eltdetail_timeline.tpl")
            %include("_eltdetail_history.tpl")
            <!--%include("_eltdetail_depgraph.tpl")-->
            %include("_eltdetail_availability.tpl")
            %include("_eltdetail_helpdesk.tpl")

         </div>
      <!-- Detail info box end -->
   </div>
</div>

%include("_eltdetail_action-menu.tpl")

%end
