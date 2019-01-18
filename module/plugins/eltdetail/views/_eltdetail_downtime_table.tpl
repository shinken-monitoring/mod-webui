%setdefault('with_service_name', False)

<table class="table table-hover comment-table">
  %for d in sorted(downtimes, key=lambda x: x.entry_time, reverse=True):
  <tr>
    <td width="150px" class="text-center" style="vertical-align: middle; border-left: 5px solid {{!helper.get_html_color(d.ref.state)}} !important;" title="This element is currently {{ d.ref.state }}">
      %if d.is_in_effect:
      EXPIRES<br>
      {{!helper.print_duration_and_date(d.end_time) }}
      %else:
      STARTS<br>
      {{!helper.print_duration_and_date(d.start_time) }}
      %end
    </td>
    <td>
      %if with_service_name:
      {{!helper.get_link(d.ref, short=True)}}
      %else:
      {{ !helper.get_contact_avatar(d.author) }}
      %end
      <span class="comment-time">
        %if with_service_name:
        by
        {{ !helper.get_contact_avatar(d.author) }}
        %else:
        created
        %end
        {{!helper.print_duration_and_date(d.entry_time)}}
        |
        %if not d.is_in_effect:
        scheduled
        %else:
        started
        %end
        {{!helper.print_duration_and_date(d.start_time)}},
        expires in
        {{!helper.print_duration_and_date(d.end_time, just_duration=True)}}
      </span>
      <span class="pull-right">
        %if not d.is_in_effect:
        <i class="fas fa-calendar" title="This downtime is scheduled but not in effect at the moment"></i>&nbsp;
        %end
        %if app.can_action():
        <a class="{{'disabled' if not app.can_action() else ''}} js-delete-downtime text-danger"
          title="Delete this downtime"
          data-element="{{helper.get_uri_name(d.ref)}}" data-downtime="{{d.id}}"
          style="cursor: pointer;"
          >
          <i class="fas fa-remove"></i>
        </a>
        %end
      </span><br>
      {{ d.comment }}
    </td>
  </tr>
  %end
</table>
