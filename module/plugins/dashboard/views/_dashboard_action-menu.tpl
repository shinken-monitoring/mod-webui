<a id="action-btn" class="btn" data-toggle="collapse" href="#action-menu">Widgets selector</a>
<nav id="action-menu" class="collapse navbar navbar-default sidebar dropup" role="navigation">
  <ul class="nav">
    %for w in app.widgets.get('dashboard', []):
    %if not w['deprecated']:
    <li >
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
          <span class='fas fa-plus'></span>
          Add this widget to your dashboard
        </button>"
        data-widget-description='{{!w["widget_desc"]}} <hr/> <div class="center-block"><img class="text-center" src="{{w["widget_picture"]}}"/></div>'
        >
        <span class="fas fa-fw fa-globe fa-{{w.get('widget_icon', 'plus')}}"></span> {{w.get('widget_alias', w.get('widget_name', ''))}}
      </a>
    </li>
    %end
    %end
  </ul>
</nav>
