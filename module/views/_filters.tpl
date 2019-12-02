%setdefault("search_id", "search")
%setdefault("common_bookmarks", app.prefs_module.get_common_bookmarks())
%setdefault("user_bookmarks", app.prefs_module.get_user_bookmarks(user))

%search_action = '/all'
%if 'search_engine' in app.request.route.config and app.request.route.config['search_engine']:
%search_action = app.request.fullpath
%end
<form id="{{ search_id }}-form" class="navbar-form form-inline" method="get" action="{{ search_action }}">

   <div class="input-group input-group-sm">
      <input class="form-control" type="search" id="{{ search_id }}" name="{{ search_id }}" value="{{ app.get_search_string() or '' }}" aria-label="Monitoring items search engine">

      <div class="input-group-btn">
         <div class="btn-group btn-group-sm">
            <button id="{{ search_id }}_filters" class="btn btn-ico dropdown-toggle" data-toggle="dropdown" aria-expanded="false" title="Filters">
               <i class="fas fa-filter"></i>
            </button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="{{ search_id }}_filters">
               <li role="presentation"><a role="menuitem" href="/all?search=&title=All resources">All resources</a></li>
               <li role="presentation"><a role="menuitem" href="/all?search=type:host&title=All hosts">All hosts</a></li>
               <li role="presentation"><a role="menuitem" href="/all?search=type:service&title=All services">All services</a></li>
               <li role="presentation" class="divider"></li>
               <li role="presentation"><a role="menuitem" href="/all?search=isnot:0 is:hard isnot:ack isnot:downtime&title=New problems">New problems</a></li>
               <li role="presentation"><a role="menuitem" href="/all?search=isnot:0 is:soft isnot:ack isnot:downtime&title=Potential problems">Potential problems</a></li>
               <li role="presentation"><a role="menuitem" href="/all?search=is:ack&title=Acknowledged problems">Acknowledged problems</a></li>
               <li role="presentation"><a role="menuitem" href="/all?search=is:downtime&title=Scheduled downtimes">Scheduled downtimes</a></li>
               <li role="presentation" class="divider"></li>
               <li role="presentation"><a role="menuitem" href="?search=bi:>=5">Impact : {{!helper.get_business_impact_text(5, text=True)}}</a></li>
               <li role="presentation"><a role="menuitem" href="?search=bi:>=4">Impact : {{!helper.get_business_impact_text(4, text=True)}}</a></li>
               <li role="presentation"><a role="menuitem" href="?search=bi:>=3">Impact : {{!helper.get_business_impact_text(3, text=True)}}</a></li>
               <li role="presentation"><a role="menuitem" href="?search=bi:>=2">Impact : {{!helper.get_business_impact_text(2, text=True)}}</a></li>
               <li role="presentation"><a role="menuitem" href="?search=bi:>=1">Impact : {{!helper.get_business_impact_text(1, text=True)}}</a></li>
               <li role="presentation"><a role="menuitem" href="?search=bi:>=0">Impact : {{!helper.get_business_impact_text(0, text=True)}}</a></li>
               <li role="presentation" class="divider"></li>
               <li role="presentation"><a role="menuitem" onclick="display_modal('/modal/helpsearch')"><strong><i class="fas fa-question-circle"></i> Search syntax</strong></a></li>
            </ul>
         </div>

         <div class="btn-group btn-group-sm">
            <button id="bookmarks_menu" class="btn btn-ico dropdown-toggle" data-toggle="dropdown" aria-expanded="false" title="Bookmarks">
               <i class="fas fa-bookmark"></i>
            </button>
            <ul class="dropdown-menu" role="menu" aria-labelledby="bookmarks_menu">
               <script type="text/javascript">
               %for b in user_bookmarks:
               declare_bookmark("{{!b['name']}}","{{!b['uri']}}");
               %end
               %for b in common_bookmarks:
               declare_bookmarksro("{{!b['name']}}","{{!b['uri']}}");
               %end
               </script>
            </ul>
         </div>

         <div class="btn-group btn-group-sm">
            <button class="btn btn-ico" type="submit">
               <i class="fas fa-search"></i>
            </button>
         </div>
      </div>
   </div>
</form>

<script>
   // Hack for BS that selects the dropdown rather than submitting the form on Enter key...
   // $('#{{ search_id }}').focus();
   $('#{{ search_id }}-form').keypress(function(event) {
      if (event.keyCode == 13) {
         event.preventDefault();
         $('#{{ search_id }}-form button[type="submit"]').click();
      }
   });
</script>
