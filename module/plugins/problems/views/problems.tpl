%import time
%user = app.get_user()
%helper = app.helper
%datamgr = app.datamgr
%search_string = app.get_search_string()

%rebase("layout", title=title, js=['js/jquery.sparkline.min.js', 'js/shinken-charts.js', 'problems/js/problems.js'], css=['problems/css/problems.css', 'eltdetail/css/eltdetail.css'], page="/all")

<script type="text/javascript">
   var actions_enabled = {{'true' if app.can_action() else 'false'}};
</script>

<!-- Problems filtering and display -->
<div id="problems">

   %if not pbs:
   <center>
     <div class="page-header">
       %if problems_search:
       <h3>Great! Everything is under control</h3>
       <h3><small>No problems are currently unhandled on your monitored system.</small></h3>
       %else:
       %if search_string:
       <h3>{{ search_error or "What a bummer! We couldn't find anything." }}</h3>
       <h3><small>Use the filters, the bookmarks, click on the links above, or try a new search query to find what you are looking for.</small></h3>
       %else:
       <h3>No host or service.</h3>
       %end
       %end
     </div>
   </center>

   %else:

   %from itertools import groupby
   %pbs = sorted(pbs, key=lambda x: x.business_impact, reverse=True)
   %for business_impact, bi_pbs in groupby(helper.sort_elements(pbs), key=lambda x: x.business_impact):
   %bi_pbs = list(bi_pbs)

   <h4 class="table-title">
     <a class="js-select-all" data-business-impact="{{ business_impact }}" data-state="off">
       <span class="original-label">
         <span class="hidden-xs">Business impact: </span>
         {{!helper.get_business_impact_text(business_impact, text=True)}}
       </span>
       <span class="onhover-label">
         <i class="fas fa-check"></i> Select all {{len(bi_pbs)}} elements
       </span>
     </a>
   </h4>

   %include("_problems.tpl", pbs=bi_pbs)

   %end

</div>

%include('_problems_actions-navbar.tpl')

%include("_problems_synthesis.tpl", pbs=pbs, search_string=app.get_search_string())

