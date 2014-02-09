%rebase layout globals(), js=['dashboard/js/widgets.js', 'dashboard/js/jquery.easywidgets.js'], css=['dashboard/css/widget.css', 'dashboard/css/dashboard.css'], title='Dashboard', menu_part='/dashboard', refresh=True

%from shinken.bin import VERSION
%helper = app.helper

<script>
  /* We are saving the global context for theses widgets */
  widget_context = 'dashboard';
</script>

<!-- Maybe the admin didn't add a user preference module, or the module is dead, if so, warn about it -->
%if not has_user_pref_mod:
<div id="warn-pref" class="hero-unit alert-critical">
  <h2>Warning:</h2>
  <p>You didn't define a WebUI module for saving user preferences like the MongoDB one. You won't be able to use this page!</p>
  <p><a href="http://www.shinken-monitoring.org/wiki/shinken_10min_start" class="btn btn-success">Learn more <i class="icon-hand-right"></i></a></p>
</div>
%end

<div class="row">
  <div id="" class="col-sm-10">
    <div class="col-sm-2">
      %if app:
      %service_state = app.datamgr.get_per_hosts_state()
      %if service_state <= 0:
      <span class="dash-big critical">{{app.datamgr.get_per_hosts_state()}}%</span>
      %elif service_state <= 33:
      <span class="dash-big critical">{{app.datamgr.get_per_hosts_state()}}%</span>
      %elif service_state <= 66:
      <span class="dash-big warning">{{app.datamgr.get_per_hosts_state()}}%</span>
      %elif service_state <= 100:
      <span class="dash-big ok">{{app.datamgr.get_per_hosts_state()}}%</span>
      %end
      %end
      <span>Hosts UP</span>
    </div>
    <div class="col-sm-2">
      %if app:
      %service_state = app.datamgr.get_per_service_state()
      %if service_state <= 0:
      <span class="dash-big critical">{{app.datamgr.get_per_service_state()}}%</span>
      %elif service_state <= 33:
      <span class="dash-big critical">{{app.datamgr.get_per_service_state()}}%</span>
      %elif service_state <= 66:
      <span class="dash-big warning">{{app.datamgr.get_per_service_state()}}%</span>
      %elif service_state <= 100:
      <span class="dash-big ok">{{app.datamgr.get_per_service_state()}}%</span>
      %end
      %end
      <span>Services UP</span>
    </div>
    <div class="col-sm-2">
      %if app:
      %overall_itproblem = app.datamgr.get_overall_it_state()
      %if overall_itproblem == 0:
      <span class="dash-big ok">OK!</span>
      %elif overall_itproblem == 1:
      <span class="dash-big warning">{{app.datamgr.get_nb_all_problems(app.get_user_auth())}}</span>
      %elif overall_itproblem == 2:
      <span class="dash-big critical">{{app.datamgr.get_nb_all_problems(app.get_user_auth())}}</span>
      %end
      %end
      <span>Problems</span>
    </div>
    <div class="col-sm-2">
      %if app:
      %overall_state = app.datamgr.get_overall_state()
      %if overall_state == 0:
      <span class="dash-big critical">OK!</span>
      %elif overall_state == 2:
      <span class="dash-big critical">{{app.datamgr.get_len_overall_state()}}</span>
      %elif overall_state == 1:
      <span class="dash-big critical">{{app.datamgr.get_len_overall_state()}}</span>
      %end
      %end
      <span>Impacts</span>
    </div>
  </div>
  %# If we got no widget, we should put the button at the center fo the screen
  %small_show_panel_s = ''
  %if len(widgets) == 0:
  %small_show_panel_s = 'hide'
  %end
  <a data-toggle="modal" href="#widgets" class="btn btn-sm btn-success pull-right topmmargin" style="margin-right: 25px;"><i class="icon-plus"></i> Add a new widget</a>
  %# Go in the center of the page!
  <span id="center-button" class="col-sm-4 col-sm-offset-4 page-center" >
    <h3>You don't have any widget yet?</h3>
    <!-- Button trigger widgets modal -->
    <a data-toggle="modal" href="#widgets" class="btn btn-block btn-success btn-lg"><i class="icon-plus"></i> Add a new widget</a>
  </span>
</div>

<script >$(function(){
  $(".slidelink").pageslide({ direction: "left", modal: true});
});
</script>

<script>
  // Now load all widgets
  $(function(){
    %for w in widgets:
    %if 'base_url' in w and 'position' in w:
    %uri = w['base_url'] + "?" + w['options_uri']
    AddWidget("{{!uri}}", "{{w['position']}}");
    %end
    %end
  });
</script>

<div class="modal fade" id="widgets" tabindex="-1" role="dialog" aria-labelledby="Widgets" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
        <h4 class="modal-title">Widgets available</h4>
      </div>
      <div class="modal-body">

        <div class="row">
          %for w in app.get_widgets_for('dashboard'):
          <div class='widget_desc' style="position: relative;">
            <div class='row'>
              <span class="col-sm-4" style="margin-top:10px;">
                <img class="img-rounded" style="width:64px;height:64px" src="{{w['widget_picture']}}" id="widget_desc_{{w['widget_name']}}"/>
              </span>
              <span>
                {{!w['widget_desc']}}
              </span>
            </div>
            <p class="add_button"><a class="btn btn-mini btn-success" href="javascript:AddNewWidget('{{w['base_uri']}}', 'widget-place-1');"> <i class="icon-chevron-left"></i> Add {{w['widget_name']}} widget</a></p>
          </div>
          %end
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
      </div>
    </div><!-- /.modal-content -->
  </div><!-- /.modal-dialog -->
</div><!-- /.modal -->

<div class="widget-place" id="widget-place-1"> </div>
<!-- /place-1 -->

<div class="widget-place" id="widget-place-2"> </div>
<!-- /place-2 -->

<div class="widget-place" id="widget-place-3"> </div>
<!-- /place-3 -->


<!-- End Easy Widgets plugin HTML markup -->

<!-- Bellow code not is part of the Easy Widgets plugin HTML markup -->

