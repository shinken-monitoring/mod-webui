<div class="tab-pane fade" id="impacts">
  <div class="panel panel-default" style="border-top:none; border-radius:0;">
    <div class="panel-body">
      <div class="{{'col-lg-6'}} if elt_type =='host' else 'col-lg-12'">
        %displayed_services=False
        %if elt.got_business_rule:
        <div class="alert alert-warning"><i class="fas fa-warning"></i> This element is a business rule.</div>
        {{!helper.print_business_rules(app.datamgr.get_business_parents(user, elt))}}
        %end

        <!-- Show our father dependencies if we got some -->
        %if elt.parent_dependencies:
        <h4>Root cause:</h4>
        {{!helper.print_business_rules(app.datamgr.get_business_parents(user, elt), source_problems=elt.source_problems)}}
        %end

        <!-- If we are an host and not a problem, show our services -->
        %if elt_type=='host' and not elt.is_problem:
        %if elt.services:
        %displayed_services=True
        <h4>My services:</h4>
        <div class="services-tree">
          {{!helper.print_aggregation_tree(helper.get_host_service_aggregation_tree(elt, app), helper.get_html_id(elt), expanded=False, max_sons=3)}}
        </div>
        %elif not elt.parent_dependencies:
        <h4>No services!</h4>
        %end
        %end #of the only host part

        <!-- If we are a root problem and got real impacts, show them! -->
        %if elt.is_problem and elt.impacts:
        <h4>My impacts:</h4>
        <div class='host-services'>
          %s = ""
          <ul>
            %for svc in helper.sort_elements(elt.impacts):
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
        %if not displayed_services and elt.services:
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
