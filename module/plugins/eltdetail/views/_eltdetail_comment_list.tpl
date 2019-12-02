%for daterange, comments in helper.group_by_daterange(sorted(elt.comments, key=lambda x: x.entry_time, reverse=True), key=lambda x: x['time']).items():
%if comments:
{{ daterange }}
<dl class="comment-list">
  %for c in comments:
  <dt>{{ c.author }}
    <span class="comment-time">
      commented
      {{!helper.print_duration_and_date(c.entry_time)}},
      %if c.expires:
      | expires
      {{!helper.print_duration_and_date(c.expire_time)}},
      %end
    </span>
    <span class="pull-right">
      %if c.persistent:
      <i class="fas fa-flag-o" title="This comment is persistent"></i>
      %end
      %if app.can_action():
      <a class="{{'disabled' if not app.can_action() else ''}} js-delete-comment text-danger"
        title="Delete this comment"
        data-element="{{helper.get_uri_name(c.ref)}}" data-comment="{{c.id}}"
        style="cursor: pointer;"
        >
        <i class="fas fa-remove"></i>
      </a>
      %end
    </span>
  </dt>
  <dd>{{ c.comment }}</dd>
  %end
</dl>
%end
%end
