%from shinken.bin import VERSION
%setdefault('elt', None)
%setdefault('user', None)
%setdefault('all_pbs', None)

%username = 'anonymous'
<!-- Footer -->
<footer>
   <nav class="navbar navbar-default navbar-fixed-bottom">
      <div class="container-fluid">
         <div onclick="display_modal('/modal/about')">
            <img src="/static/images/default_company_xxs.png" alt="Shinken Logo"/>
            <small><em class="text-muted">
               Shinken {{VERSION}} &mdash; Web User Interface {{app.app_version}}, &copy;2011-2016
            </em></small>
         </div>
      </div>
   </nav>
</footer>
