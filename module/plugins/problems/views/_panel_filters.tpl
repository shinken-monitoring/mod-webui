<!-- Filters panel -->
%page=all
<div class="panel panel-info">
  <div class="panel-heading">Filtering</div>
  <div class="panel-body">
    <div class="btn-group btn-group-justified">
      <a href="#filtering" data-toggle="modal" data-target="#filtering" class="btn btn-success"><i class="fa fa-plus"></i> </a>
      <a id='remove_all_filters2' href='javascript:remove_all_current_filter("/{{page}}");' class="btn btn-danger"><i class="fa fa-minus"></i> </a>
    </div>

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
    <!-- Bookmarks creation -->
    <div class="btn-group btn-group-justified" role="group">
      <div class="btn-group btn-group-sm" role="group">
        <button type="button" class="btn btn-primary btn-lg btn-block dropdown-toggle" data-toggle="dropdown" aria-expanded="true" id="dropdownMenu1"> <i class="fa fa-tags"></i> Bookmark the current filter</button>
        <ul class="dropdown-menu" role="menu" aria-labelledby="dropdownMenu1">
          <li role="presentation">
            <div style="padding: 15px; padding-bottom: 0px;">
              <form class="form_in_dropdown" role="form" name='bookmark_save' id='bookmark_save'>
                <div class="form-group">
                  <label for="bookmark_name" class="control-label">Bookmark name</label>
                  <input class="form-control input-sm" id="bookmark_name" name="bookmark_name" placeholder="..." aria-describedby="help_bookmark_name">
                  <span id="help_bookmark_name" class="help-block">Use an identifier to create a bookmark referencing the current applied filters.</span>
                </div>
                <a class='btn btn-success' href='javascript:add_new_bookmark("/{{page}}");'> <i class="fa fa-save"></i> Save</a>
              </form>
            </div>
          </li>
        </ul>
      </div>
    </div>
    %end
  </div>
</div>


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
            <label for="htag" class="col-sm-3 control-label">Hosts tags</label>
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
            <label for="stag" class="col-sm-3 control-label">Services tags</label>
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
