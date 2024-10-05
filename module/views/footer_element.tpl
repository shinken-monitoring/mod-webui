<!-- Footer -->
%import time
<footer>
   <nav class="navbar navbar-default">
      <div class="container-fluid">
         <div onclick="display_modal('/modal/about')">
            <small><em class="text-muted">
                {{fmwk}} {{VERSION}} &mdash; Web User Interface {{app.app_version}}, &copy;{{app.app_copyright if app is not None else ''}} &mdash; Rendered in {{ int((time.time() - app.request.start_time) * 1000) }}ms
            </em></small>
         </div>
      </div>
   </nav>
</footer>
