%import time
%now = time.time()
%helper = app.helper
%datamgr = app.datamgr

%rebase layout globals(), title='All problems', js=['problems/js/img_hovering.js', 'problems/js/problems.js', 'problems/js/filters.js', 'problems/js/bookmarks.js'], css=['problems/css/problems.css', 'problems/css/perfometer.css', 'problems/css/img_hovering.css', 'problems/css/filters.css'], refresh=True, user=user

%# Look for actions if we must show them or not
%global_disabled = ''
%if app.manage_acl and not helper.can_action(user):
%global_disabled = 'disabled-link'
%end
<script type="text/javascript">
  var actions_enabled = {{'true' if global_disabled == '' else 'false'}};

  var toolbar_hide = {{'true' if toolbar=='hide' else 'false'}};

	function submitform() {
	   document.forms["search_form"].submit();
	}

	/* Catch the key ENTER and launch the form
	 Will be link in the password field
	*/
	function submitenter(myfield,e){
	  var keycode;
	  if (window.event) keycode = window.event.keyCode;
	  else if (e) keycode = e.which;
	  else return true;

	  if (keycode == 13){
	    submitform();
	    return false;
	  }else
	   return true;
	}

  // Typeahead: builds suggestion engine
  var hosts = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {
      url: '/lookup/%QUERY',
      filter: function (hosts) {
        return $.map(hosts, function (host) { return { value: host }; });
      }
    }
  });
  hosts.initialize();


	var active_filters = [];

	// List of the bookmarks
	var bookmarks = [];
	var bookmarksro = [];

	%for b in bookmarks:
    declare_bookmark("{{!b['name']}}","{{!b['uri']}}");
	%end
	%for b in bookmarksro:
    declare_bookmarksro("{{!b['name']}}","{{!b['uri']}}");
  %end

  // We will create here our new filter options
  // This should be outside the "pageslide" div. I don't know why
  new_filters = [];
  current_filters = [];

  // On page loaded ...
  $(function(){
    // We prevent the dropdown to close when we go on a form into it.
    $('.form_in_dropdown').on('click', function (e) {
      e.stopPropagation()
    });

    // Typeahead: activation
    $('#filtering .typeahead').typeahead({
      hint: true,
      highlight: true,
      minLength: 1
    },
    {
      name: 'hosts',
      displayKey: 'value',
      source: hosts.ttAdapter(),
    });

    // Buttons tooltips
    $('span').tooltip();
  });
</script>

<!-- Filtering modal dialog box -->
<div class="modal fade" id="filtering">
  <div class="modal-dialog" role="dialog" aria-labelledby="Filtering options" aria-hidden="true">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
        <h3 class="modal-title">Filtering options</h4>
      </div>
      <div class="modal-body">
        <form class="form-horizontal" role="form" name='namefilter'>
          <div class="form-group">
            <label for="search" class="col-sm-3 control-label">Name</label>
            <div class="col-sm-7">
              <input class="form-control typeahead" name="search" autofocus autocomplete="off" placeholder="...">
            </div>
            <a class='btn btn-default col-sm-1' href="javascript:save_name_filter();"> <i class="fa fa-plus"></i> </a>
          </div>
        </form>

        <form class="form-horizontal" role="form" name='hgfilter'>
          <div class="form-group">
            <label for="hg" class="col-sm-3 control-label">Hostgroups</label>
            <div class="col-sm-7">
              <select class="form-control" name='hg'>
                <option value='None'> None</option>
                %for hg in datamgr.get_hostgroups_sorted():
                <option value='{{hg.get_name()}}'> {{hg.get_name()}} ({{len(hg.members)}})</option>
                %end
              </select>
            </div>
            <a class='btn btn-default col-sm-1' href="javascript:save_hg_filter();"> <i class="fa fa-plus"></i> </a>
          </div>
        </form>

        <form class="form-horizontal" role="form" name='htagfilter'>
          <div class="form-group">
            <label for="htag" class="col-sm-3 control-label">Tags</label>
            <div class="col-sm-7">
              <select class="form-control" name='htag'>
                <option value='None'> None</option>
                %for (t, n) in datamgr.get_host_tags_sorted():
                <option value='{{t}}'> {{t}} ({{n}})</option>
                %end
              </select>
            </div>
            <a class='btn btn-default col-sm-1' href="javascript:save_htag_filter();"> <i class="fa fa-plus"></i> </a>
          </div>
        </form>

        <form class="form-horizontal" role="form" name='stagfilter'>
          <div class="form-group">
            <label for="stag" class="col-sm-3 control-label">Tags</label>
            <div class="col-sm-7">
              <select class="form-control" name='stag'>
                <option value='None'> None</option>
                %for (t, n) in datamgr.get_service_tags_sorted():
                <option value='{{t}}'> {{t}} ({{n}})</option>
                %end
              </select>
            </div>
            <a class='btn btn-default col-sm-1' href="javascript:save_stag_filter();"> <i class="fa fa-plus"></i> </a>
          </div>
        </form>

        <form class="form-horizontal" role="form" name='realmfilter'>
          <div class="form-group">
            <label for="realm" class="col-sm-3 control-label">Realms</label>
            <div class="col-sm-7">
              <select class="form-control" name='realm'>
                %for r in datamgr.get_realms():
                <option value='{{r}}'> {{r}}</option>
                %end
              </select>
            </div>
            <a class='btn btn-default col-sm-1' href="javascript:save_realm_filter();"> <i class="fa fa-plus"></i> </a>
          </div>
        </form>

        <hr/>

        <h4>States</h4>
        <form class="form-horizontal" role="form" name='ack_filter'>
          <div class="form-group">
            <div class="col-sm-offset-1 col-sm-9">
              <div class="pull-left">
                <div class="checkbox">
                  <label>
                    %if page=='problems':
                    <input name="show_ack" type="checkbox" >
                    %else:
                    <input name="show_ack" type="checkbox" checked>
                    %end
                     Ack
                  </label>
                </div>
                <div class="checkbox">
                  <label>
                    <input name="show_both_ack" type="checkbox"> Both ack states
                  </label>
                </div>
              </div>

            </div>
            <a class='btn btn-default col-sm-1' href="javascript:save_state_ack_filter();"> <i class="fa fa-plus"></i> </a>
          </div>
        </form>

        <form class="form-horizontal" role="form" name='downtime_filter'>
          <div class="form-group">
            <div class="col-sm-offset-1 col-sm-9">
              <div class="pull-left">
                <div class="checkbox">
                  <label>
                    %if page=='problems':
                    <input name="show_downtime" type="checkbox" >
                    %else:
                    <input name="show_downtime" type="checkbox" checked>
                    %end
                     Downtime
                  </label>
                </div>
                <div class="checkbox">
                  <label>
                    <input name="show_both_downtime" type="checkbox"> Both downtime states
                  </label>
                </div>
              </div>

            </div>
            <a class='btn btn-default col-sm-1' href="javascript:save_state_downtime_filter();"> <i class="fa fa-plus"></i> </a>
          </div>
        </form>

        <form class="form-horizontal" role="form" name='criticity_filter'>
          <div class="form-group">
            <div class="col-sm-offset-1 col-sm-9">
              <div class="pull-left">
                <div class="checkbox">
                  <label>
                    %if page=='problems':
                    <input name="show_critical" type="checkbox" >
                    %else:
                    <input name="show_critical" type="checkbox" checked>
                    %end
                     Critical only
                  </label>
                </div>
              </div>
            </div>
            <a class='btn btn-default col-sm-1' href="javascript:save_state_criticity_filter();"> <i class="fa fa-plus"></i> </a>
          </div>
        </form>
      </div>
      <div class="modal-footer">
        <div id='new_search'></div>

        <a id='remove_all_filters' class='btn btn-danger pull-left' href="javascript:clean_new_search();"> <i class="fa fa-eject"></i> Remove all filters</a>
        <a id='launch_the_search' class='btn btn-primary pull-right' href="javascript:launch_new_search('/{{page}}');"> <i class="fa fa-play"></i> Launch the search!</a>
      </div>
    </div>
  </div>
</div>


<!-- Buttons and page navigation -->
<div class="row" style="padding: 0px;">
  <div class='col-md-4 pull-left'>
    <a id="hide_toolbar_btn" href="javascript:hide_toolbar()" class="btn btn-default"><i class="fa fa-minus"></i> Hide toolbar</a>
    <a id='show_toolbar_btn' href="javascript:show_toolbar()" class="btn btn-default"><i class="fa fa-plus"></i> Show toolbar</a>
    <a id='select_all_btn' href="javascript:select_all_problems()" class="btn btn-default"><i class="fa fa-check"></i> Select all</a>
    <a id='unselect_all_btn' href="javascript:unselect_all_problems()" class="btn btn-default"><i class="fa fa-minus"></i> Unselect all</a>
    <a id='expand_all' href="javascript:expand_all_block()" class="btn btn-default"><i class="fa fa-plus"></i> Expand all</a>
    <a id='collapse_all' href="javascript:collapse_all_block()" class="btn btn-default"><i class="fa fa-minus"></i> Collapse all</a>
  </div>
  <div class='col-md-8 pull-right'>
  %include pagination_element navi=navi, app=app, page=page, div_class="pull-right"
  </div>
</div>

  <!-- Problems filtering and display -->
  <div class="row" style="padding: 0px;">
    <!-- Left panel, toolbar and active filters -->
    <div id="toolbar" class="col-lg-3 col-md-4 col-sm-4">
      <div class="panel panel-info" id="image_panel">
        <div class="panel-heading">Perfdatas</div>
        <div class="panel-body">
          <div id="img_hover"></div>
        </div>
      </div>

      <div class="panel panel-info" id="actions">
        <div class="panel-heading">Actions</div>
        <div class="panel-body">
          <ul class="list-group">
            <li class="list-group-item"><a href="javascript:try_to_fix_all();"><i class="fa fa-ambulance"></i> Try to fix</a></li>
            <li class="list-group-item"><a href="javascript:recheck_now_all()"><i class="fa fa-refresh"></i> Recheck</a></li>
            <li class="list-group-item"><a href="javascript:submit_check_ok_all()"><i class="fa fa-share"></i> Submit Result OK</a></li>
            <li class="list-group-item"><a href="javascript:acknowledge_all('{{user.get_name()}}')"><i class="fa fa-check"></i> Acknowledge</a></li>
            <li class="list-group-item"><a href="javascript:remove_all('{{user.get_name()}}')"><i class="fa fa-eraser"></i> Delete</a></li>
          </ul>
        </div>
      </div>

      <div class="panel panel-info">
        <div class="panel-heading">Filtering</div>
        <div class="panel-body">
          <div class="btn-group btn-group-justified">
            <a href="#filtering" data-toggle="modal" data-target="#filtering" class="btn btn-success"><i class="fa fa-plus"></i> </a>
            <a id='remove_all_filters2' href='javascript:remove_all_current_filter("/{{page}}");' class="btn btn-danger"><i class="fa fa-minus"></i> </a>
          </div>
          <script>
          $(function(){
            clean_new_search();
          });
          </script>

          %got_filters = sum([len(v) for (k,v) in filters.iteritems()]) > 0
          %if got_filters:
            <br/>
            <ul class="list-group">
              Active filters:
              %for n in filters['hst_srv']:
              <li class="list-group-item">
                <span class="filter_color hst_srv_filter_color">&nbsp;</span>
                <span class="hst_srv_filter_name">Name: {{n}}</span>
                <span class="filter_delete"><a href='javascript:remove_current_filter("hst_srv", "{{n}}", "/{{page}}");' class="close">&times;</a></span>
              </li>
              <script>add_active_hst_srv_filter('{{n}}');</script>
              %end

              %for hg in filters['hg']:
              <li class="list-group-item">
                <span class="filter_color hg_filter_color">&nbsp;</span>
                <span class="hg_filter_name">Group: {{hg}}</span>
                <span class="filter_delete"><a href='javascript:remove_current_filter("hg", "{{hg}}", "/{{page}}");' class="close">&times;</a></span>
              </li>
              <script>add_active_hg_filter('{{hg}}');</script>
              %end

              %for r in filters['realm']:
              <li class="list-group-item">
                <span class="filter_color realm_filter_color">&nbsp;</span>
                <span class="realm_filter_name">Realm: {{r}}</span>
                <span class="filter_delete"><a href='javascript:remove_current_filter("realm", "{{r}}", "/{{page}}");' class="close">&times;</a></span>
              </li>
              <script>add_active_realm_filter('{{r}}');</script>
              %end

              %for r in filters['htag']:
              <li class="list-group-item">
                <span class="filter_color tag_filter_color">&nbsp;</span>
                <span class="tag_filter_name">Tag: {{r}}</span>
                <span class="filter_delete"><a href='javascript:remove_current_filter("htag", "{{r}}", "/{{page}}");' class="close">&times;</a></span>
              </li>
              <script>add_active_htag_filter('{{r}}');</script>
              %end

              %for r in filters['stag']:
              <li class="list-group-item">
                <span class="filter_color stag_filter_color">&nbsp;</span>
                <span class="stag_filter_name">Tag: {{r}}</span>
                <span class="filter_delete"><a href='javascript:remove_current_filter("stag", "{{r}}", "/{{page}}");' class="close">&times;</a></span>
              </li>
              <script>add_active_stag_filter('{{r}}');</script>
              %end

              %for r in filters['ack']:
              <li class="list-group-item">
                <span class="filter_color ack_filter_color">&nbsp;</span>
                <span class="ack_filter_name">Ack: {{r}}</span>
                <span class="filter_delete"><a href='javascript:remove_current_filter("ack", "{{r}}", "/{{page}}");' class="close">&times;</a></span>
              </li>
              <script>add_active_state_ack_filter('{{r}}');</script>
              %end

              %for r in filters['downtime']:
              <li class="list-group-item">
                <span class="filter_color downtime_filter_color">&nbsp;</span>
                <span class="downtime_filter_name">Downtime: {{r}}</span>
                <span class="filter_delete"><a href='javascript:remove_current_filter("downtime", "{{r}}", "/{{page}}");' class="close">&times;</a></span>
              </li>
              <script>add_active_state_downtime_filter('{{r}}');</script>
              %end

              %for r in filters['crit']:
              <li class="list-group-item">
                <span class="filter_color criticity_filter_color">&nbsp;</span>
                <span class="criticity_filter_name">Criticity: {{r}}</span>
                <span class="filter_delete"><a href='javascript:remove_current_filter("crit", "{{r}}", "/{{page}}");' class="close">&times;</a></span>
              </li>
              <script>add_active_state_criticity_filter('{{r}}');</script>
              %end
            </ul>

            <br/>
            <div class="btn-group">
              <button class="btn btn-primary active dropdown-toggle" data-toggle="dropdown"> <i class="fa fa-tags"></i> Bookmark</button>
              <ul class="dropdown-menu" role="menu">
                <li role="presentation">
                  <div style="padding: 15px; padding-bottom: 0px;">
                    <form class="form_in_dropdown" role="form" name='bookmark_save' id='bookmark_save'>
                      <div class="form-group">
                        <label for="bookmark_name" class="control-label">Bookmark name</label>
                        <div>
                          <input class="form-control" name="bookmark_name" placeholder="...">
                        </div>
                        <a class='btn btn-success' href='javascript:add_new_bookmark("/{{page}}");'> <i class="fa fa-save"></i> Save</a>
                      </div>
                    </form>
                  </div>
                </li>
              </ul>
            </div>
          %end
        </div>
      </div>

      <div class="panel panel-info">
        <div class="panel-heading">Bookmarks</div>
        <div class="panel-body">
          <div id='bookmarks'></div>
          <div id='bookmarksro'></div>
          <script>
            $(function(){
              refresh_bookmarks(); refresh_bookmarksro();
            });
          </script>
        </div>
      </div>
    </div>

    <!-- Right panel, with all problems -->
    <div id="problems" class="col-lg-9 col-md-8 col-sm-8">
      <div class="panel-group" id="accordion">

      %# " We will print Business impact level of course"
      %imp_level = 10

      %# " We remember the last hname so see if we print or not the host for a 2nd service"
      %last_hname = ''

      %# " We try to make only importants things shown on same output "
      %last_output = ''
      %nb_same_output = 0
      %if app.datamgr.get_nb_problems() > 0 and page == 'problems' and app.play_sound:
         <EMBED src="/static/sound/alert.wav" autostart=true loop=false volume=100 hidden=true>
      %end

      %for pb in pbs:
        %if pb.business_impact != imp_level:
          %if imp_level != 10:
            %# Close last panel group  ...
                  </div>
                </div>
              </div>
            </div>
          %end
          %# Business level title ...
          <h3> Business impact: {{!helper.get_business_impact_text(pb)}} </h3>
          %# "We reset the last_hname so we won't overlap this feature across tables"
          %last_hname = 'first'
          %last_output = ''
          %nb_same_output = 0
        %end
        %imp_level = pb.business_impact

        %# " We check for the same output and the same host. If we got more than 3 of same, make them opacity effect"
        %if pb.output == last_output and pb.host_name == last_hname:
          %nb_same_output += 1
        %else:
          %nb_same_output = 0
        %end
        %last_output = pb.output

        %if pb.host_name != last_hname:
          %if last_hname != '' and last_hname != 'first':
            %# Close last panel group  ...
                  </div>
                </div>
              </div>
            </div>
          %end
          <div class="panel panel-default" style="margin: 0">
            <div class="panel-heading">
              <h4 class="panel-title table-responsive" data-toggle="collapse" data-parent="#accordion" href="#group_{{pb.current_problem_id}}">
                {{pb.host_name}}
                <a class="pull-right">
                  <i class="fa fa-chevron-down pull-right"></i>
                </a>
              </h4>
            </div>
            <div id="group_{{pb.current_problem_id}}" class="panel-collapse collapse host-panel">
              <div class="panel-body">
                <div class="panel-group" id="problems_{{pb.current_problem_id}}">
            %last_hname = pb.host_name
        %end

        %# Panel for an host and all its services ...
        %div_class = ''
        %div_style = ''
        <div class="panel panel-default" style="margin: 0">
          <div class="panel-heading">
            <h4 class="panel-title table-responsive">
              <table class="table table-condensed" style="margin:0;"><thead style="border: none;"><tr class="background-{{pb.state.lower()}}" data-toggle="collapse" data-parent="#problems_{{pb.current_problem_id}}" href="#{{helper.get_html_id(pb)}}">
                <th style="font-size: small; font-weight: normal;" class="col-md-1">
                  <div class='tick' style="cursor:pointer;" onmouseover="hovering_selection('{{helper.get_html_id(pb)}}')" onclick="add_remove_elements('{{helper.get_html_id(pb)}}')">
                    <img class='img_tick' id='selector-{{helper.get_html_id(pb)}}' src='/static/images/tick.png' />
                  </div>
                </th>

                <th style="font-size: small; font-weight: normal;" class="col-md-1">
                  <div class='img_status'>
                  <span class="medium-pulse aroundpulse pull-left">
                    %# " We put a 'pulse' around the elements if it's an important one "
                    %if pb.business_impact > 2 and pb.state_id in [1, 2, 3]:
                      <span class="medium-pulse pulse"></span>
                    %end
                    <img src="{{helper.get_icon_state(pb)}}" />
                  </span>
                  </div>
                </th>

                <th style="font-size: small; font-weight: normal;" class="col-md-5">
                  <span class="cut_long">{{!helper.get_link(pb, short=True)}}</span>
                </th>

                <th style="font-size: small; font-weight: normal;" class="col-md-1">
                  <span class='txt_status'> {{pb.state}}</span>
                </th>

                <th style="font-size: small; font-weight: normal;" class="col-lg-2 hidden-md">
                  %if len(pb.output) > 100:
                    %if app.allow_html_output:
                      <span class='output' rel="tooltip" data-original-title="{{pb.output}}"> {{!helper.strip_html_output(pb.output[:app.max_output_length])}}</span>
                    %else:
                      <span class='output' rel="tooltip" data-original-title="{{pb.output}}"> {{pb.output[:app.max_output_length]}}</span>
                    %end
                  %else:
                    %if app.allow_html_output:
                      <span class='output'> {{!helper.strip_html_output(pb.output)}} </span>
                    %else:
                      <span class='output'> {{pb.output}} </span>
                    %end
                  %end
                </th>

                <th style="font-size: small; font-weight: normal;" class="col-lg-4 hidden-md">
                  %graphs = app.get_graph_uris(pb, now-4*3600, now, 'dashboard')
                  %onmouse_code = ''
                  %if len(graphs) > 0:
                    %onmouse_code = 'onmouseover="display_hover_img(\'%s\',\'\');" onmouseout="hide_hover_img();" ' % graphs[0]['img_src']
                  %end
                  <span class="perfometer" {{!onmouse_code}}>{{!helper.get_perfometer(pb)}}</span>
                </th>

                <th style="font-size: small; font-weight: normal;" class="col-sm-1">
                  <a class="pull-right"><i class="fa fa-chevron-down pull-right"></i></a>
                </th>
              </tr></thead></table>
            </h4>
          </div>
          <div id="{{helper.get_html_id(pb)}}" data-raw-obj-name='{{pb.get_full_name()}}' class="detail panel-collapse collapse">
            <div class="panel-body">
              <table class="table table-bordered">
                <thead><tr>
                  <td>Host</td>
                  %if pb.__class__.my_type == 'service':
                  <td>Service</td>
                  %end
                  <td>Realm</td>
                  <td>State</td>
                  <td>Since</td>
                  <td>Last check</td>
                  <td>Next check</td>
                  <td >Actions</td>
                </tr></thead>
                <tbody>
                  <tr>
                    <td><a href="/host/{{pb.host_name}}">{{pb.host_name}}</a></td>
                    %if pb.__class__.my_type == 'service':
                    <td>{{!helper.get_link(pb, short=True)}}</td>
                    %end
                    <td>{{pb.get_realm()}}</td>
                    <td><span class='txt_status state_{{pb.state.lower()}} '> {{pb.state}}</span></td>
                    <td>{{helper.print_duration(pb.last_state_change, just_duration=True, x_elts=2)}}</td>
                    <td>{{helper.print_duration(pb.last_chk, just_duration=True, x_elts=2)}} ago</td>
                    <td>in {{helper.print_duration(pb.next_chk, just_duration=True, x_elts=2)}}</td>
                    <td >
                      <button type="button" id="bt-recheck-{{helper.get_html_id(pb)}}" class="{{global_disabled}} btn btn-primary btn-sm">Recheck</button>
                      <script>
                        $('#bt-recheck-{{helper.get_html_id(pb)}}').click(function () {
                          recheck_now('{{pb.get_full_name()}}');
                        });
                      </script>
                    </td>
                  </tr>
                  <tr>
                    <td colspan="{{8 if pb.__class__.my_type == 'service' else 7}}">
                    %if len(pb.output) > 100:
                      %if app.allow_html_output:
                        <span class='output' rel="tooltip" data-original-title="{{pb.output}}"> {{!helper.strip_html_output(pb.output[:app.max_output_length])}}</span>
                      %else:
                        <span class='output' rel="tooltip" data-original-title="{{pb.output}}"> {{pb.output[:app.max_output_length]}}</span>
                      %end
                    %else:
                      %if app.allow_html_output:
                        <span class='output'> {{!helper.strip_html_output(pb.output)}} </span>
                      %else:
                        <span class='output'> {{pb.output}} </span>
                      %end
                    %end
                    </td>
                  </tr>
                </tbody>
              </table>

              <div>
                %if len(pb.impacts) > 0:
                  <hr />
                  <h4>Impacts:</h4>
                  %end
                  %for i in helper.get_impacts_sorted(pb):
                  <div>
                    <p><img style="width: 16px; height: 16px;" src="{{helper.get_icon_state(i)}}" />
                      <span class="alert-small alert-{{i.state.lower()}}">{{i.state}}</span> for {{!helper.get_link(i)}}
                    </p>
                  </div>
                %end
              </div>
            </div>
          </div>
        </div>
      %end
      %# Close last panel group  ...
              </div>
            </div>
          </div>
        </div>
    %# Close accordion and problems div ...
      </div>
    </div>

    <script type="text/javascript">
      // Open the first host collapsable element
      $('.host-panel:first').addClass('in');
    </script>
    %include pagination_element navi=navi, app=app, page=page, div_class="pull-right"
  </div>
