%import time
%import re
%import ast
%now = int(time.time())

%if not elt:
%rebase("layout", title='Invalid element name')

Invalid element name

%else:

%helper = app.helper

%from shinken.macroresolver import MacroResolver

%elt_type = elt.__class__.my_type

%elt_host = elt if elt_type=='host' else elt.host
%elt_service = elt if elt_type=='service' else None
%elt_display_name = elt_host.display_name if elt_type=='host' else elt_service.display_name+' on '+elt_host.display_name

%breadcrumb = [['All '+elt_type.title()+'s', '/'+elt_type+'s-groups']]
%if elt_type == 'host':
%breadcrumb += [[elt.display_name if elt.display_name else elt.get_name(), '/host/'+elt.host_name]]
%elif elt_type == 'service':
%breadcrumb += [[elt.host.display_name if elt.host.display_name else elt.host.get_name(), '/host/'+elt.host_name]]
%breadcrumb += [[elt.display_name, '/service/'+helper.get_uri_name(elt)]]
%end

%js=['js/shinken-actions.js', 'availability/js/justgage.js', 'availability/js/raphael-2.1.4.min.js', 'cv_host/js/flot/jquery.flot.min.js', 'cv_host/js/flot/jquery.flot.tickrotor.js', 'cv_host/js/flot/jquery.flot.resize.min.js', 'cv_host/js/flot/jquery.flot.pie.min.js', 'cv_host/js/flot/jquery.flot.categories.min.js', 'cv_host/js/flot/jquery.flot.time.min.js', 'cv_host/js/flot/jquery.flot.stack.min.js', 'cv_host/js/flot/jquery.flot.valuelabels.js',  'eltdetail/js/jquery.color.js', 'eltdetail/js/bootstrap-switch.min.js', 'eltdetail/js/custom_views.js', 'eltdetail/js/eltdetail.js']
%css=['eltdetail/css/bootstrap-switch.min.css', 'eltdetail/css/eltdetail.css', 'cv_host/css/cv_host.css']
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


   %groups = elt_service.servicegroups if elt_service else elt_host.hostgroups
   %groups = sorted(groups, key=lambda x:x.level)
   %tags = elt_service.get_service_tags() if elt_service else elt_host.get_host_tags()
   <!-- First row : tags and actions ... -->
   %if elt.action_url or tags or groups:
   <div>
      %if groups:
      <div class="btn-group pull-right">
         <button class="btn btn-primary btn-xs"><i class="fa fa-sitemap"></i> Groups</button>
         <button class="btn btn-primary btn-xs dropdown-toggle" data-toggle="dropdown"><span class="caret"></span></button>
         <ul class="dropdown-menu pull-right">
         %for g in groups:
            <li>
            <a href="/{{elt_type}}s-group/{{g.get_name()}}">{{g.level if g.level else '0'}} - {{g.alias if g.alias else g.get_name()}}</a>
            </li>
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
         <ul class="dropdown-menu pull-right">
            %for action_url in helper.get_element_actions_url(elt, default_title="Url", default_icon="globe", popover=True):
            <li>{{!action_url}}</li>
            %end
         </ul>
      </div>
      <div class="pull-right">&nbsp;&nbsp;</div>
      %end
      %if tags:
      %tag=elt_type[0]+'tag'
      <div class="btn-group pull-right">
         %for t in sorted(tags):
            <a href="/all?search={{tag}}:{{t}}">
               %if app.tag_as_image:
               <img src="/tag/{{t.lower()}}" alt="{{t.lower()}}" =title="Tag: {{t.lower()}}" style="height: 24px"></img>
               %else:
               <button class="btn btn-default btn-xs"><i class="fa fa-tag"></i> {{t.lower()}}</button>
               %end
            </a>
         %end
      </div>
      %end
         <div class="pull-right">&nbsp;&nbsp;</div>
      <div class="btn-group pull-right">
         <a role="button" class="btn btn-primary btn-xs" href="/cpe/{{elt_host.host_name}}"/>Ficha</a>
      </div>
   </div>
   %end

   <!-- Second row : host/service overview ... -->
   <div class="panel panel-default">
      <div class="panel-heading fitted-header cursor" data-toggle="collapse" data-parent="#Overview" href="#collapseOverview">
         <h4 class="panel-title"><span class="caret"></span>&nbsp;Overview {{elt_display_name}} {{!helper.get_business_impact_text(elt.business_impact)}}</h4>
      </div>

      <div id="collapseOverview" class="panel-body panel-collapse collapse">
         %if elt.customs:
         <div class="row">
         <dl class="col-sm-6 dl-horizontal">
            %if elt_type=='host':
            <dt>cpe_address:</dt>
            <dd>{{elt.cpe_address}}</dd>
            <dt>cpe_registration_host:</dt>
            <dd>{{elt.cpe_registration_host}}</dd>
            <dt>cpe_registration_id:</dt>
            <dd>{{elt.cpe_registration_id}}</dd>
            <dt>cpe_registration_state:</dt>
            <dd>{{elt.cpe_registration_state}}</dd>
            <dt>cpe_registration_tags:</dt>
            <dd>{{elt.cpe_registration_tags}}</dd>
            <dt>cpe_connection_request_url:</dt>
            <dd>{{elt.cpe_connection_request_url}}</dd>
            %if elt.cpe_ipleases:
            %try:
            %cpe_ipleases = ast.literal_eval(elt.cpe_ipleases) or {'foo': 'bar'}
            %for ip,lease in cpe_ipleases.iteritems():
            <dt>{{ip}}</dt>
            <dd>{{lease}}</dd>
            %end
            %except Exception, exc:
            <dt>{{elt.cpe_ipleases}}</dt>
            <dd>{{exc}}</dd>
            %end
            %else:
            <dt>cpe_ipleases</dt>
            <dd>empty!</dd>
            %end
            %end

            %if '_DETAILLEDESC' in elt.customs:
            <dt>Description:</dt>
            <dd>{{elt.customs['_DETAILLEDESC']}}</dd>
            %end
            %if '_IMPACT' in elt.customs:
            <dt>Impact:</dt>
            <dd>{{elt.customs['_IMPACT']}}</dd>
            %end
            %if '_FIXACTIONS' in elt.customs:
            <dt>Fix actions:</dt>
            <dd>{{elt.customs['_FIXACTIONS']}}</dd>
            %end
         </dl>
         </div>
         %end
         %if elt_type=='host':
         <dl class="col-sm-6 dl-horizontal">
            <dt>Alias:</dt>
            <dd>{{elt_host.alias}}</dd>

            <dt>Address:</dt>
            <dd>{{elt_host.address}}</dd>

            <dt>Importance:</dt>
            <dd>{{!helper.get_business_impact_text(elt.business_impact, True)}}</dd>
         </dl>

         <dl class="col-sm-6 dl-horizontal">
            <dt>Depends upon:</dt>
            %if elt_host.parent_dependencies:
            <dd>
            %parents=['<a href="/host/'+parent.host_name+'" class="link">'+parent.display_name+'</a>' for parent in sorted(elt_host.parent_dependencies,key=lambda x:x.display_name)]
            {{!','.join(parents)}}
            </dd>
            %else:
            <dd>(none)</dd>
            %end

            <dt>Parents:</dt>
            %if elt_host.parents:
            <dd>
            %parents=['<a href="/host/'+parent.host_name+'" class="link">'+parent.display_name+'</a>' for parent in sorted(elt_host.parents,key=lambda x:x.display_name)]
            {{!','.join(parents)}}
            </dd>
            %else:
            <dd>(none)</dd>
            %end

            <dt>Depends upon me:</dt>
            %if elt_host.child_dependencies:
            <dd>
            %children=['<a href="/host/'+child.host_name+'" class="link">'+child.display_name+'</a>' for child in sorted(elt_host.child_dependencies,key=lambda x:x.display_name) if child.__class__.my_type=='host']
            {{!','.join(children)}}
            </dd>
            %else:
            <dd>(none)</dd>
            %end

            <dt>Children:</dt>
            %if elt_host.childs:
            <dd>
            %children=['<a href="/host/'+child.host_name+'" class="link">'+child.display_name+'</a>' for child in sorted(elt_host.childs,key=lambda x:x.display_name)]
            {{!','.join(children)}}
            </dd>
            %else:
            <dd>(none)</dd>
            %end
         </dl>

         <dl class="col-sm-6 dl-horizontal">
            <dt>Member of:</dt>
            %if elt_host.hostgroups:
            <dd>
            %for hg in elt_host.hostgroups:
            <a href="/hosts-group/{{hg.get_name()}}" class="link">{{hg.alias if hg.alias else hg.get_name()}}</a>
            %end
            </dd>
            %else:
            <dd>(none)</dd>
            %end

         </dl>
         %else:
         <dl class="col-sm-6 dl-horizontal">
            <dt>Host:</dt>
            <dd>
               <a href="/host/{{elt_host.host_name}}" class="link">{{elt_host.display_name}}</a>
            </dd>

            <dt>Importance:</dt>
            <dd>{{!helper.get_business_impact_text(elt.business_impact, True)}}</dd>
         </dl>

         <dl class="col-sm-6 dl-horizontal">
            <dt>Member of:</dt>
            %if elt_service.servicegroups:
            <dd>
            %for sg in elt_service.servicegroups:
            <a href="/services-group/{{sg.get_name()}}" class="link">{{sg.alias}} ({{sg.get_name()}})</a>
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
            <li><a href="#metrics" data-toggle="tab">Metrics</a></li>
            %if app.graphs_module.is_available():
            <li><a href="#graphs" data-toggle="tab">Graphs</a></li>
            %end
            <li><a href="#depgraph" data-toggle="tab">Impact graph</a></li>
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
            %include("_eltdetail_metrics.tpl")
            %include("_eltdetail_graphs.tpl")
            %#include("_eltdetail_timeline.tpl")
            %include("_eltdetail_history.tpl")
            %include("_eltdetail_depgraph.tpl")
            %include("_eltdetail_availability.tpl")
            %include("_eltdetail_helpdesk.tpl")

         </div>
      <!-- Detail info box end -->
   </div>
</div>

%include("_eltdetail_action-menu.tpl")

%end
