<div class="tab-pane fade" id="comments">
  <div class="panel panel-default" style="border-top:none; border-radius:0;">
    <div class="panel-body">

      %if not elt.comments:
         <div class="text-center">
           <h3>No comment available on this {{ elt_type }}</h3>
         </div>
      %end

      %include("_eltdetail_comment_table.tpl", comments=elt.comments)

      %if elt_type=='host' and elt.services:
      %servicecomments = [c for sublist in [s.comments for s in elt.services] for c in sublist]
      %if servicecomments:
      <br/><br/>
      <h4 class="page-header">Comments for {{ elt.get_name() }} services</h4>
      %include("_eltdetail_comment_table.tpl", comments=servicecomments, with_service_name=True, with_contact_form=False)
      %end
      %end
    </div>

  </div>
</div>
