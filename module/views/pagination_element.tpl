%setdefault('display_steps_form', False)
%setdefault('div_class', "pull-right")
%setdefault('ul_class', "")
%setdefault('div_style', "margin-top:-24px;")
%setdefault('drop', "dropup")

%from urllib import urlencode

<div class="{{ div_class }}" style="{{ div_style }}">
  %if display_steps_form:
  <ul class="pagination {{ ul_class }}" >
    <li>
      <form id="elts_per_page" method="get" action="javascript:void(0);">
       <div class="input-group" style="width:120px">
         <div class="input-group-btn {{drop}}">
           <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-expanded="false">#&nbsp;<span class="caret"></span></button>
           <ul class="dropdown-menu" role="menu">
             <li><a href="#" data-elts="5">5 elements</a></li>
             <li><a href="#" data-elts="10">10 elements</a></li>
             <li><a href="#" data-elts="25">25 elements</a></li>
             <li><a href="#" data-elts="50">50 elements</a></li>
             <li><a href="#" data-elts="100">100 elements</a></li>
           </ul>
         </div>
         <input id="step" name="step" type="number" class="form-control" aria-label="Elements per page" placeholder="Elements per page ..." value="{{pagination['step']}}">
       </div>
      </form>
    </li>
    <script>
    var current_elts_per_page = {{pagination['step']}};
    $("#elts_per_page li a").click(function(e){
      var value = $(this).data('elts');

      // Save user preference
      save_user_preference('elts_per_page', value);

      // Update input field
      $('#elts_per_page input').val(value);

      current_elts_per_page = value;

      location.reload();
    });
    $('#elts_per_page form').submit(function(e){
      var value = $('#elts_per_page input').val();
      console.log("Submit: ", value);

      if (value == parseInt(value)) {
         // Update input field
         save_user_preference('elts_per_page', value);
         current_elts_per_page = value;
      } else {
         $('#elts_per_page input').val(current_elts_per_page);
      }

      location.reload();
      e.preventDefault();
    });
    $('#elts_per_page input').blur(function(e){
      var value = $('#elts_per_page input').val();
      console.log("Blur: ", value);

      if (value == parseInt(value)) {
         // Update input field
         save_user_preference('elts_per_page', value);
         current_elts_per_page = value;
      } else {
         $('#elts_per_page input').val(current_elts_per_page);
      }

      location.reload();
    });
    </script>
  </ul>
  %end

  %if pagination and (pagination['start'] != 0 or pagination['end'] <= pagination['total']):
  %query = app.request.query
  <ul class="pagination {{ ul_class }}">
    %if pagination['start'] != 0:
    <!--First page-->
    %query['start'] = 0
    %query['end'] = pagination['step']
    <li class=""><a href="{{ page }}?{{ urlencode(query) }}" title="First page: {{ query['start'] }} - {{ query['end'] }}"><i class="fa fa-angle-double-left"></i></a></li>
    <!--Previous page-->
    %if pagination['start'] > pagination['step']:
    %query['start'] = pagination['start'] - pagination['step']
    %query['end'] = pagination['start']
    <li class=""><a href="{{ page }}?{{ urlencode(query) }}" title="Previous page: {{ query['start'] }} - {{ query['end'] }}"><i class="fa fa-angle-left"></i></a></li>
    %end
    %end

    <!--current-->
    <li class="disabled"><a href="#">{{ pagination['start'] }} - {{ pagination['end'] }} over {{ pagination['total'] }}</a></li>

    %if pagination['end'] != pagination['total']:
    <!--Next page-->
    %if pagination['end'] <= pagination['total'] - pagination['step']:
    %query['start'] = pagination['end']
    %query['end'] = pagination['end'] + pagination['step']
    <li class=""><a href="{{ page }}?{{ urlencode(query) }}" title="Next page: {{ query['start'] }} - {{ query['end'] }}"><i class="fa fa-angle-right"></i></a></li>
    %end
    <!--Last page-->
    %query['start'] = pagination['total'] - (pagination['total'] % pagination['step'])
    %query['end'] = pagination['total']
    <li class=""><a href="{{ page }}?{{ urlencode(query) }}" title="Last page: {{ query['start'] }} - {{ query['end'] }}"><i class="fa fa-angle-double-right"></i></a></li>
    %end
  </ul>
  %end
</div>
