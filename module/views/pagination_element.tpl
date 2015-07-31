%setdefault('display_steps_form', False)
%setdefault('div_class', "pull-right")
%setdefault('ul_class', "")
%setdefault('div_style', "margin-top:-15px;")

<div class="{{ div_class }}" style="{{ div_style }}">
  %if display_steps_form and elts_per_page is not None:
  <ul class="pagination {{ ul_class }}" >
    <li>
      <form id="elts_per_page" class="pull-left">
       <div class="input-group" style="width:120px">
         <div class="input-group-btn">
           <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-expanded="false">#&nbsp;<span class="caret"></span></button>
           <ul class="dropdown-menu" role="menu">
             <li><a href="#" data-elts="5">5 elements</a></li>
             <li><a href="#" data-elts="10">10 elements</a></li>
             <li><a href="#" data-elts="25">25 elements</a></li>
             <li><a href="#" data-elts="50">50 elements</a></li>
             <li><a href="#" data-elts="100">100 elements</a></li>
           </ul>
         </div>
         <input type="number" class="form-control" aria-label="Elements per page" placeholder="Elements per page ..." value="{{elts_per_page}}" style="max-width: 100px;">
       </div>
      </form>
    </li>
    <script>
    var current_elts_per_page = {{elts_per_page}};
    $("#elts_per_page li a").click(function(e){
      var value = $(this).data('elts');
      
      // Save user preference
      save_user_preference('elts_per_page', value);
      
      // Update input field
      $('#elts_per_page input').val(value);
      
      current_elts_per_page = value;

      e.preventDefault();
    });
    $('#elts_per_page form').submit(function(e){
      var value = $('#elts_per_page input').val();

      if (value == parseInt(value)) {
         // Update input field
         save_user_preference('elts_per_page', value);
         current_elts_per_page = value;
      } else {
         $('#elts_per_page input').val(current_elts_per_page);
      }

      e.preventDefault();
    });
    $('#elts_per_page input').blur(function(e){
      var value = $('#elts_per_page input').val();

      if (value == parseInt(value)) {
         // Update input field
         save_user_preference('elts_per_page', value);
         current_elts_per_page = value;
      } else {
         $('#elts_per_page input').val(current_elts_per_page);
      }

      e.preventDefault();
    });
    </script>
  </ul>
  %end
  
  %if navi and len(navi) > 1:
  <ul class="pagination {{ ul_class }}" >
    
    %from urllib import urlencode

    %for name, start, end, is_current in navi:
    %if is_current:
    <li class="active"><a href="#">{{name}}</a></li>
    %elif start == None or end == None:
    <li class="disabled"> <a href="#">...</a> </li>
    %else:
    %# Include other query parameters like search and global_search
    %query = app.request.query
    %query['start'] = start
    %query['end'] = end
    %query_string = urlencode(query)
    <li><a href="{{page}}?{{query_string}}">{{name}}</a></li>
    %end
    %end
  </ul>
  %end
</div>
