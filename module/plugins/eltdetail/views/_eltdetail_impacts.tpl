<div class="tab-pane fade" id="impacts">
  <div class="panel panel-default" style="border-top:none; border-radius:0;">
    <div class="panel-body">
      %if elt_type=='host':
      <div class="col-lg-6">
        <!-- Show our own services  -->
        %from itertools import groupby
        %pbs = sorted(elt.services, key=lambda x: x.business_impact, reverse=True)
        %for business_impact, bi_pbs in groupby(helper.sort_elements(pbs), key=lambda x: x.business_impact):
        %bi_pbs = list(bi_pbs)

        <h4 class="table-title">
          <span class="hidden-xs">Business impact: </span>
          {{!helper.get_business_impact_text(business_impact, text=True)}}
        </h4>

        %include("_problems_table.tpl", pbs=bi_pbs)
        %end
      </div>
      %end

      <div class="col-lg-6">
        %if elt.got_business_rule:
        <div class="alert alert-warning"><i class="fas fa-warning"></i> This element is a business rule.</div>
        {{!helper.print_business_rules(app.datamgr.get_business_parents(user, elt))}}
        %end

        %if elt.parent_dependencies:
        <h4 class="table-title">Parents:</h4>
        %include("_problems_table.tpl", pbs=elt.parent_dependencies)
        %end

        %if elt_type == 'host':
        %child_dependencies = [ s for s in elt.child_dependencies if str(s.host_name) != elt.host_name ]
        %else:
        %child_dependencies = elt.child_dependencies
        %end
        %if child_dependencies:
        <h4 class="table-title">Impacts:</h4>
        %include("_problems_table.tpl", pbs=child_dependencies)
        %end
      </div>
    </div>
  </div>
</div>
