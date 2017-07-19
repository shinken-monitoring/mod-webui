<div class="tab-pane fade" id="comments">
  <div class="panel panel-default" style="border-top:none; border-radius:0;">
    <div class="panel-body">
      %if elt.comments:
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
          %for c in sorted(elt.comments, key=lambda x: x.entry_time, reverse=True):
          <tr>
            <td>{{c.author}}</td>
            <td>{{c.comment}}</td>
            <td>{{helper.print_date(c.entry_time)}}</td>
            <td>
              <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm js-delete-comment"
                title="Delete this comment"
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

      <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm js-add-comment"
        title="Add a comment for this {{elt_type}}"
        data-element="{{helper.get_uri_name(elt)}}"
        >
        <i class="fa fa-plus"></i> Add a comment
      </button>
      %if elt.comments:
      <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm js-delete-all-comments"
        title="Delete all the comments of this {{elt_type}}"
        data-element="{{helper.get_uri_name(elt)}}"
        >
        <i class="fa fa-minus"></i> Delete all comments
      </button>
      %end
      %if elt_type=='host' and elt.services:
      <br/><br/>
      <h4>Current host services comments:</h4>
      <table class="table table-condensed table-hover">
        <thead>
          <tr>
            <th>Service</th>
            <th>Author</th>
            <th>Comment</th>
            <th>Date</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          %setdefault('servicecomments', None)
          %servicecomments = [c for sublist in [s.comments for s in elt.services] for c in sublist]
          %for c in sorted(servicecomments, key=lambda x: x.entry_time, reverse=True):
          <tr>
            <td>{{s.get_name()}}</td>
            <td>{{c.author}}</td>
            <td>{{c.comment}}</td>
            <td>{{helper.print_date(c.entry_time)}}</td>
            <td>
              <button class="{{'disabled' if not app.can_action() else ''}} btn btn-primary btn-sm js-delete-comment"
                title="Delete this comment"
                data-element="{{helper.get_uri_name(elt)}}" data-comment="{{c.id}}"
                >
                <i class="fa fa-trash-o"></i>
              </button>
            </td>
          </tr>
          %end
        </tbody>
      </table>
      %end
    </div>

  </div>
</div>
