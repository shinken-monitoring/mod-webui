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
  <div id="loading" class="pull-left"> <img src='/static/images/spinner.gif'> Loading widgets</div>
  %# If we got no widget, we should put the button at the center fo the screen
  %small_show_panel_s = ''
  %if len(widgets) == 0:
  %small_show_panel_s = 'hide'
  %end
  <a data-toggle="modal" href="#widgets" class="btn btn-small btn-success pull-right"><i class="icon-plus"></i> Add a new widget</a>
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

