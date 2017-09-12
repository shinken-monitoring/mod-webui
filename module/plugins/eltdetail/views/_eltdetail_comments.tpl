<div class="tab-pane fade" id="comments">
  <div class="panel panel-default" style="border-top:none; border-radius:0;">
    <div class="panel-body">
      %if elt.comments:

      %include("_eltdetail_comment_table.tpl", comments=elt.comments)

      %else:
      <div class="page-header">
        <h3>No comment available on this {{ elt_type }}</h3>
      </div>

      <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm js-add-comment"
        title="Add a comment for this {{elt_type}}"
        data-element="{{helper.get_uri_name(elt)}}"
        >
        <i class="fa fa-plus"></i> Add a comment
      </button>
      %end


      %if elt.comments:
      <div class="text-right">
        <button class="{{'disabled' if not app.can_action() else ''}} btn btn-default btn-sm js-delete-all-comments"
          title="Delete all the comments of this {{elt_type}}"
          data-element="{{helper.get_uri_name(elt)}}"
          >
          <i class="fa fa-minus"></i> Delete all comments
        </button>
      </div>
      %end

      %if elt_type=='host' and elt.services:
      <br/><br/>
      <h4 class="page-header">Comments on {{ elt.get_name() }} services</h4>

      %setdefault('servicecomments', None)
      %servicecomments = [c for sublist in [s.comments for s in elt.services] for c in sublist]
      %include("_eltdetail_comment_table.tpl", comments=servicecomments, with_service_name=True)

      %end
    </div>

  </div>
</div>
