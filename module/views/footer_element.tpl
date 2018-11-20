<!-- Footer -->
<footer>
   <nav class="navbar navbar-default navbar-fixed-bottom">
      <div class="container-fluid">
         <div onclick="display_modal('/modal/about')">
            <small><em class="text-muted">
               {{fmwk}} {{VERSION}} &mdash; Web User Interface {{app.app_version}}, &copy;{{app.app_copyright if app is not None else ''}}
            </em></small>
         </div>
      </div>
   </nav>
</footer>
