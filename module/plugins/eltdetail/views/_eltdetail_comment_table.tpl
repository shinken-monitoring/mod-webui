%setdefault('with_service_name', False)

%for daterange, dr_comments in helper.group_by_daterange(sorted(comments, key=lambda x: x.entry_time, reverse=True), key=lambda x: x.entry_time).items():
%if dr_comments:
<div class="daterange-title">{{ daterange }}</div>
<table class="table table-hover comment-table">
  %for c in dr_comments:
  <tr>
    <td width="30px" class="text-center" style="vertical-align: middle;">
      %setdefault('comment_icon', 'fa-comment')
      %setdefault('comment_title', 'User comment')
      %if c.entry_type == 2:
      %comment_title = 'Downtime'
      %comment_icon = "fa-ambulance"
      %elif c.entry_type == 3:
      %comment_title = 'Flapping'
      %comment_icon = "fa-cog"
      %elif c.entry_type == 4:
      %comment_title = 'Acknowledgement'
      %comment_icon = "fa-check"
      %end
      <i title="{{ comment_title }}" class="text-muted fa {{ comment_icon }} fa-2x"></i>
    </td>
    <td>
      %if with_service_name:
      {{!helper.get_link(c.ref, short=True)}}
      %else:
      {{ !helper.get_contact_avatar(c.author) }}
      %end
      <span class="comment-time">
        %if with_service_name:
        by 
        {{ !helper.get_contact_avatar(c.author) }}
        %else:
        commented
        %end
        {{!helper.print_duration_and_date(c.entry_time)}},
        %if c.expires:
        | expires
        {{!helper.print_duration_and_date(c.expires_time)}},
        %end
      </span>
      <span class="pull-right">
        %if c.persistent:
        <i class="fa fa-flag-o" title="This comment is persistent"></i>&nbsp;
        %end
        %if app.can_action():
        <a class="{{'disabled' if not app.can_action() else ''}} js-delete-comment text-danger"
          title="Delete this comment"
          data-element="{{helper.get_uri_name(c.ref)}}" data-comment="{{c.id}}"
          style="cursor: pointer;"
          >
          <i class="fa fa-remove"></i>
        </a>
        %end
      </span><br>
      {{ c.comment }}
    </td>
  </tr>
  %end
</table>
%end
%end
