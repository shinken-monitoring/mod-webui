%import time
%import re
%now = int(time.time())

%# If got no element, bailout
%if not cpe:
%rebase("layout", title='Invalid element name')

Invalid element name

%else:

%helper = app.helper

%from shinken.macroresolver import MacroResolver

%# Main variables
%cpe_type = cpe.__class__.my_type
%cpe_host = cpe if cpe_type=='host' else cpe.host
%cpe_service = cpe if cpe_type=='service' else None
%cpe_name = cpe.host_name if cpe_type=='host' else cpe.host.host_name+'/'+cpe.service_description
%cpe_display_name = cpe_host.display_name if cpe_type=='host' else cpe_service.display_name+' on '+cpe_host.display_name

%# Replace MACROS in display name ...
%if hasattr(cpe, 'get_data_for_checks'):
    %cpe_display_name = MacroResolver().resolve_simple_macros_in_string(cpe_display_name, cpe.get_data_for_checks())
%end

%business_rule = False
%if cpe.get_check_command().startswith('bp_rule'):
%business_rule = True
%end

%breadcrumb = [ ['All '+cpe_type.title()+'s', '/'+cpe_type+'s-groups'], [cpe_host.display_name, '/host/'+cpe_host.host_name] ]
%title = cpe_type.title()+' detail: ' + cpe_display_name
%if cpe_service:
%breadcrumb += [[cpe_service.display_name, '/service/'+cpe_name] ]
%end

%js=['availability/js/justgage.js', 'availability/js/raphael-2.1.4.min.js', 'cv_host/js/flot/jquery.flot.min.js', 'cv_host/js/flot/jquery.flot.tickrotor.js', 'cv_host/js/flot/jquery.flot.resize.min.js', 'cv_host/js/flot/jquery.flot.pie.min.js', 'cv_host/js/flot/jquery.flot.categories.min.js', 'cv_host/js/flot/jquery.flot.time.min.js', 'cv_host/js/flot/jquery.flot.stack.min.js', 'cv_host/js/flot/jquery.flot.valuelabels.js',  'cpe/js/jquery.color.js', 'cpe/js/bootstrap-switch.min.js', 'cpe/js/custom_views.js', 'cpe/js/cpe.js']
%css=['cpe/css/bootstrap-switch.min.css', 'cpe/css/cpe.css', 'cv_host/css/cv_host.css']
%rebase("layout", js=js, css=css, breadcrumb=breadcrumb, title=title)

<div id="element" class="row container-fluid">

   %groups = cpe_service.servicegroups if cpe_service else cpe_host.hostgroups
   %groups = sorted(groups, key=lambda x:x.level)
   %tags = cpe_service.get_service_tags() if cpe_service else cpe_host.get_host_tags()


   <!-- Second row : host/service overview ... -->
   <div class="panel panel-default">
      <div class="panel-heading fitted-header cursor" data-toggle="collapse" data-parent="#Overview" href="#collapseOverview">
         <h4 class="panel-title"><span class="caret"></span>&nbsp;Overview {{cpe_display_name}} {{!helper.get_business_impact_text(cpe.business_impact)}}</h4>
      </div>

      <div id="collapseOverview" class="panel-body panel-collapse collapse">
         <div class="row">
	 <h2>CPE Info</h2>
	 <dl class="col-sm-12 dl-horizontal">
            <dt>CPE alias:</dt>
	    <dd>{{cpe_host.address}}</dd>
	    <dt>Model</dd>
	    <dd>{{cpe.customs['_CPE_MODEL']}}</dd>
	    <dt>Serial Number</dt>
	    <dd>{{cpe.customs['_SN']}}</dd>
	    <dd>MAC Address</dd>
	    <dt>{{cpe.customs['_MAC']}}</dd>
            <dt>CPE IP Address:</dt>
	    <dd>{{cpe.cpe_address}}</dd>
	    <dt>Registration host:</dt>
	    <dd>{{cpe.cpe_registration_host}}</dt>
	    <dt>Registration ID:</dt>
	    <dd>{{cpe.cpe_registration_id}}</dd>
	    <dt>Registration state</dt>
	    <dd>{{cpe.cpe_registration_state}}</dd>
	    <dt>Registration tags</dt>
	    <dd>{{cpe.cpe_registration_tags}}</dd>
	    <dt>Configuration URL:</dt>
	    <dd>{{cpe.cpe_connection_request_url}}</dd>
            %if cpe.cpe_ipleases:
            %try:
            %cpe_ipleases = ast.literal_eval(cpe.cpe_ipleases) or {'foo': 'bar'}
            %for ip,lease in cpe_ipleases.iteritems():
            <dt>Leased IP: {{ip}}</dt>
            <dd>{{lease}}</dd>
            %end
            %except Exception, exc:
            <dt>{{cpe.cpe_ipleases}}</dt>
            <dd>{{exc}}</dd>
            %end
            %else:
            <dt>cpe_ipleases</dt>
            <dd>empty!</dd>
            %end

	 </dl>
	 </div>
         <div class="row">
	 <h2>Customer info</h2>
         <dl class="col-sm-6 dl-horizontal">
	   <dt>Name</dt>
	   <dd>{{cpe.customs['_CUSTOMER_NAME']}}</dd>
	   <dt>Surname</dt>
	   <dd>{{cpe.customs['_CUSTOMER_SURNAME']}}</dd>
	   <dt>Address</dt>
	   <dd>{{cpe.customs['_CUSTOMER_ADDRESS']}}</dd>
	   <dt>City</dt>
	   <dd>{{cpe.customs['_CUSTOMER_CITY']}}</dd>

         </dl>
         </div>
      </div>
   </div>
</div>
%#End of the element exist or not case
%end
