%from shinken.misc.perfdata import PerfDatas

%groupname = 'all'
%groupalias = 'All hosts'
%title = 'Technical for all hosts'

%helper = app.helper

%search_string = app.get_search_string()

%rebase("layout", title='Technical for hosts/services', css=['technical/css/technical.css'], js=['technical/js/technical.js'], breadcrumb=[ ['All hosts', '/technical'] ])


<div id="technical">

%for h in items:
<div class="row">

<div class="col-md-2">
<div><a class="font-{{ h.state.lower() }}" href="/cpe/{{ h.get_name() }}">{{ h.get_name() }} - {{ h.state }}</a></div>
</div>
<div class="col-md-2">
%for s in h.services:
<div><a  class="font-{{ s.state.lower() }}" href="/service/{{ h.get_name() }}/{{ s.get_name() }}">{{ s.state }} - {{ s.get_name() }}</a></div>
%end
</div>
<div class="col-md-8">
%for s in h.services:
%perfdatas = PerfDatas(s.perf_data)
<div class="row">
  %if len(perfdatas) > 0:
   %for m in perfdatas:
   <div style="float:left; width: outline: 1px solid black">
   <a href="/service/{{ h.get_name() }}/{{ s.get_name() }}#metrics">{{m.value}}</a> |
   </div>
   %end
  %else:
  <div style="float:left; width: outline: 1px solid black">-</div>
  %end
</div>
%end
</div>


</div>

%end

<div>
