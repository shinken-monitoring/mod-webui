%setdefault('div_class', "")
%setdefault('div_style', "margin-top:0; margin-bottom:0;")

<nav class="{{div_class}}" style="{{div_style}}">
      %if elts_per_page is not None:
      <div class="col-sm-2" id="elts_per_page">
         <div class="input-group">
            <div class="input-group-btn">
               <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-expanded="false">#<span class="caret"></span></button>
               <ul class="dropdown-menu" role="menu">
                  <li><a href="#" data-elts="5">5 elements</a></li>
                  <li><a href="#" data-elts="10">10 elements</a></li>
                  <li><a href="#" data-elts="20">20 elements</a></li>
                  <li><a href="#" data-elts="50">50 elements</a></li>
                  <li><a href="#" data-elts="100">100 elements</a></li>
               </ul>
            </div>
            <input type="text" class="form-control" aria-label="Elements per page" placeholder="Elements per page ..." value="{{elts_per_page}}" style="max-width: 100px;">
         </div>
      </div>
      <script>
         $("#elts_per_page li a").click(function(e){
            // Update input field
            $('#elts_per_page input').val($(this).data('elts'));
            save_user_preference('elts_per_page', $(this).data('elts'));
            
            e.preventDefault();
         });
      </script>
      %end
      %if navi is not None:
         <ul class="col-sm-10 pagination" style="margin-top:0; margin-bottom: 0;" >
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
</nav>
