<a id="action-btn" class="btn" data-toggle="collapse" href="#action-menu">Widgets selector</a>

<nav id="action-menu" class="collapse navbar navbar-default navbar-element hidden-xs" role="navigation">
  <ul class="nav">
    %for w in app.get_widgets_for('dashboard'):
    %if not w['deprecated']:
    <li style="height: 1.5em; line-height: 1.5em">
      <a href="#"
        title="Add widget {{w['widget_alias']}} to the dashboard"
        data-placement="right"
        class="dashboard-widget"
        data-widget-title="
        <button href='#' role='button'
          action='add-widget'
          data-widget='{{w['widget_name']}}'
          data-wuri='{{w['base_uri']}}'
          class='btn btn-sm btn-success'>
          <span class='fa fa-plus'></span>
          Add this widget to your dashboard
        </button>"
        data-widget-description='{{!w["widget_desc"]}} <hr/> <div class="center-block"><img class="text-center" src="{{w["widget_picture"]}}"/></div>'
        >
        <span class="fa fa-plus"></span> {{w['widget_alias'] if 'widget_alias' in w else w['widget_name']}}
      </a>
    </li>
    %end
    %end
  </ul>
</nav>
