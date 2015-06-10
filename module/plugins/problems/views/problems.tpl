%helper = app.helper
%datamgr = app.datamgr

%rebase("layout", title='All problems', js=['problems/js/problems.js', 'problems/js/filters.js', 'problems/js/bookmarks.js'], css=['problems/css/problems.css', 'problems/css/filters.css'], refresh=True, user=user, navi=navi, app=app, page="/all")

%# Look for actions if we must show them or not
%actions_allowed = True
%if app.manage_acl and not helper.can_action(user):
%actions_allowed = False
%end
<script type="text/javascript">
   var actions_enabled = {{'true' if actions_allowed else 'false'}};
   var toolbar = '{{toolbar}}';

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
    } else {
       return true;
    }
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
    // $('span').tooltip();

    // Open the first host collapsable element
    // $('.host-panel:first').addClass('in');
    
      // Buttons tooltips
      // $('span').tooltip();

      // Open the first host collapsable element
      // $('.host-panel:first').addClass('in');
      
      // Hide the toolbar
      if (toolbar=='show') 
         show_toolbar();
   });
</script>

<!-- Buttons and page navigation -->
<div class="row">

 <div class='col-lg-5 col-md-4 col-sm-2 pull-left'>
    <a id='show_toolbar_btn' href="javascript:show_toolbar(true)" class="btn btn-default btn-sm"><i class="fa fa-plus"></i> Show toolbar</a>      
    <a id="hide_toolbar_btn" href="javascript:hide_toolbar(true)" class="btn btn-default btn-sm" style="display:none;"><i class="fa fa-minus"></i> Hide toolbar</a>
    <a id='select_all_btn' href="javascript:select_all_problems()" class="btn btn-default btn-sm"><i class="fa fa-check"></i> Select all</a>
    <a id='unselect_all_btn' href="javascript:unselect_all_problems()" class="btn btn-default btn-sm" style="display:none;"><i class="fa fa-minus"></i> Unselect all</a>
 </div>

</div>

<hr>

%if len(app.get_all_problems()) and app.play_sound:
 <EMBED src="/static/sound/alert.wav" autostart=true loop=false volume=100 hidden=true>
%end

<!-- Problems filtering and display -->
<div class="row">
 <!-- Left panel, toolbar and active filters -->
 <div id="toolbar" class="col-lg-3 col-md-4 col-sm-4" style="display:none;">

   %if actions_allowed:
   %include("_panel_actions.tpl")
   %end

   %include("_panel_filters.tpl", filters=filters)

    <!-- Bookmarks panel -->
    <div class="panel panel-info">
       <div class="panel-heading">Bookmarks</div>
       <div class="panel-body">
          <div id='bookmarks'></div>
          <div id='bookmarksro'></div>
       </div>
    </div>
 </div>

 <!-- Right panel, with all problems -->
 <div id="problems" class="col-lg-12 col-md-12 col-sm-12">

   %include("_problems_synthesis.tpl", pbs=pbs)

   %from itertools import groupby
   %pbs = sorted(pbs, key=lambda x: x.business_impact, reverse=True)
   %for business_impact, bi_pbs in groupby(pbs, key=lambda x: x.business_impact):
 <div class="panel panel-default">
   <!--<div class="panel-heading">-->
   <!--</div>-->
    <div class="panel-body">
     <h3 class="text-center">Business impact: {{!helper.get_business_impact_text(business_impact, text=True)}}</strong></h3>
    <table class="table table-condensed">
      <thead><tr>
          <th width="16px"></th>
          <th width="16px"></th>
          <th width="200px">Host</th>
          <th width="200px">Service</th>
          <th width="90px">State</th>
          <th width="90px">Duration</th>
          <th>Output</th>
      </tr></thead>

      <tbody>
      %# Sort problems, hosts first, then orders by state_id and by host
      %bi_pbs = sorted(sorted(sorted(bi_pbs, key=lambda x: x.host_name), key=lambda x: x.state_id, reverse=True), key=lambda x: x.__class__.my_type)
      %hosts = groupby(bi_pbs, key=lambda x: x.host_name)
      %for host_name, host_pbs in hosts:
      %for i, pb in enumerate(host_pbs):
          
       %# Host information ...
       <tr data-toggle="collapse" data-target="#details-{{helper.get_html_id(pb)}}" class="accordion-toggle">
          <td>
            <input type="checkbox" id="selector-{{helper.get_html_id(pb)}}">
          </td>
          <td align=center>
            {{!helper.get_fa_icon_state(pb)}}
          </td>
          <td>
            %if i == 0:
            <a href="/host/{{pb.host_name}}">{{pb.host_name}}</a>
            %end
          </td>
          <td>
            %if pb.__class__.my_type == 'service':
            {{!helper.get_link(pb, short=True)}}
            %end
            %# Impacts
            %if len(pb.impacts) > 0:
            <button class="btn btn-danger btn-xs"><i class="fa fa-plus"></i> {{ len(pb.impacts) }} impacts</button>
            %end
          </td>
          <td align="center" class="font-{{pb.state.lower()}}"><strong>{{ pb.state }}</strong></td>
          <td align="center">{{!helper.print_duration(pb.last_state_change, just_duration=True, x_elts=2)}}</td>
          <td class="row">
            <div class="pull-right">
              %# Graphs
              %import time
              %now = time.time()
              %graphs = app.get_graph_uris(pb, now-4*3600, now, 'dashboard')
              %if len(graphs) > 0:
                <a role="button" tabindex="0" data-toggle="popover" title="{{ pb.get_full_name() }}" data-content="<img src={{ graphs[0]['img_src'] }} width='600px' height='200px'>" data-placement="left">{{!helper.get_perfometer(pb)}}</a>
              %end
            </div>
            <div class="">
              {{ pb.output }}
            </div>
          </td>
        </tr>
         <tr class="detail" id="{{helper.get_html_id(pb)}}" data-raw-obj-name='{{pb.get_full_name()}}'>
           <td colspan="8" class="hiddenRow">
             <div class="accordion-body collapse" id="details-{{helper.get_html_id(pb)}}">
               <table class="table table-condensed" style="margin:0;">
                 <tr>
                   <td align="center">Realm {{pb.get_realm()}}</td>
                   %if pb.passive_checks_enabled:
                   <td>
                      <i class="fa fa-arrow-left" title="Passive checks are enabled."></i>
                      %if (pb.check_freshness):
                         <i title="Freshness check is enabled">(Freshness threshold: {{pb.freshness_threshold}} seconds)</i>
                      %end
                   </td>
                   %end
                   %if pb.active_checks_enabled:
                   <td align="center">
                      <i class="fa fa-arrow-right" title="Active checks are enabled."></i>
                      <i>Last check <strong>{{!helper.print_duration(pb.last_chk, just_duration=True, x_elts=2)}} ago</strong>, next check in <strong>{{!helper.print_duration(pb.next_chk, just_duration=True, x_elts=2)}}</strong>, attempt <strong>{{pb.attempt}}/{{pb.max_check_attempts}}</strong></i>
                    </td>
                   %end
                   %if actions_allowed:
                   <td align="right">
                     <div class="btn-group" role="group" aria-label="...">
                       %if pb.event_handler_enabled and pb.event_handler:
                       <button type="button" class="btn btn-default btn-xs" title="Try to fix (launch event handler if defined)" onClick="try_to_fix_one('{{ pb.get_full_name() }}');">
                         <i class="fa fa-magic"></i> Try to fix
                       </button>
                       %end
                       <button type="button" class="btn btn-default btn-xs" title="Launch the check command " onClick="recheck_now_one('{{ pb.get_full_name() }}');">
                         <i class="fa fa-refresh"></i> Refresh
                       </button>
                       <button type="button" class="btn btn-default btn-xs" title="Force service to be considered as Ok" onClick="submit_check_ok_one('{{ pb.get_full_name() }}', '{{ user.get_name() }}');">
                         <i class="fa fa-share"></i> OK
                       </button>
                       <button type="button" id="btn-acknowledge-{{helper.get_html_id(pb)}}" class="btn btn-default btn-xs" title="Acknowledge the problem">
                         <i class="fa fa-check"></i> ACK
                       </button>
                       <script>
                         $('button[id="btn-acknowledge-{{helper.get_html_id(pb)}}"]').click(function () {
                           stop_refresh();
                           $('#modal').modal({
                             keyboard: true,
                             show: true,
                             backdrop: 'static',
                             remote: "/forms/acknowledge/{{helper.get_uri_name(pb)}}"
                           });
                         });
                       </script>
                       <button type="button" id="btn-downtime-{{helper.get_html_id(pb)}}" class="btn btn-default btn-xs" title="Schedule a one day downtime for the problem">
                         <i class="fa fa-ambulance"></i> Downtime
                       </button>
                       <script>
                         $('button[id="btn-downtime-{{helper.get_html_id(pb)}}"]').click(function () {
                           stop_refresh();
                           $('#modal').modal({
                             keyboard: true,
                             show: true,
                             backdrop: 'static',
                             remote: "/forms/downtime/{{helper.get_uri_name(pb)}}"
                           });
                         });
                       </script>
                         <button type="button" class="btn btn-default btn-xs" title="Ignore checks for the service (disable checks, notifications, event handlers and force Ok)" onClick="remove_one('{{ pb.get_full_name() }}', '{{ user.get_name() }}');">
                           <i class="fa fa-eraser"></i> Remove
                         </button>
                       </div>
                     </td>
                     %end
                   </tr>
                 </table>
                 %if len(pb.impacts) > 0:
                 <h4 style="margin-left: 20px;">{{ len(pb.impacts) }} impacts</h4>
                 <table class="table table-condensed" style="margin:0;">
                   <tr>
                      %for i in helper.get_impacts_sorted(pb):
                      %if i.state_id != 0:
                      <tr>
                        <td align=center>
                          {{!helper.get_fa_icon_state(i)}}
                        </td>
                        <td width="200px"></td>
                        <td width="200px">{{!helper.get_link(i, short=True)}}</td>
                        <td width="90px" align="center" class="font-{{i.state.lower()}}"><strong>{{ i.state }}</strong></td>
                        <td width="90px">{{!helper.print_duration(i.last_state_change, just_duration=True, x_elts=2)}}</td>
                        <td width="100px">{{!helper.print_duration(i.last_chk, just_duration=True, x_elts=2)}} ago</td>
                        <td>
                          {{ i.output }}
                        </td>
                      </tr>
                      %end
                      %end
                 </table>
                 %end
               </div>
             </td>
           </tr>

        %# End for pb in pbs:
        %end
        %end
        </tbody>
      </table>
   </div>
   </div>
      %end
         
      %# Close problems div ...
   </div>

</div>

<script>
  $(function () {
    $('[data-toggle="popover"]').popover({
      html: true,
      template: '<div class="popover img-popover"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>',
      trigger: "hover",
    })
  })
</script>
