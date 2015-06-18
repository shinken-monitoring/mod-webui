%rebase("layout", title='Shinken Web UI Login', print_header=False, print_menu=False, print_title=False, js=['login/js/capslock.js'], css=['login/css/login.css'])

%from shinken.bin import VERSION

<div class="row page-header">
   <h1 class="col-sm-12 col-md-6">Shinken <small>version {{VERSION}}</small></h1>
   <div class="col-sm-12 col-md-6"> <img src="/static/logo/{{company_logo}}" alt="Company logo" /> </div>
</div>

<div class="row">
   <div class="col-sm-12 col-md-6">
      <noscript>
         <div class="row alert">
            <button type="button" class="close" data-dismiss="alert">×</button>
            <div class="font-red"><strong>Warning!</strong> Please enable Java Script in your browser and retry.</div>
         </div>
      </noscript>

      %if login_text:
      <p class="lead">{{login_text}}</p>
      %end

      <img src="/static/images/shinken.png" />
   </div>

   <div class="col-sm-12 col-md-6">
      <div class="panel panel-default">
         <div class="panel-heading">
            <h2 class="panel-title">Login</h2>
         </div>
         <div class="panel-body">
            <form method="post" id="loginform" role="form" action="/user/auth">
               <fieldset>
                  <div class="form-group">
                     <label>Name</label>
                     <div>
                        <input class="form-control" name="login" type="text">
                     </div>
                  </div>
                  <div class="form-group">
                     <label>Password</label>
                     <div>
                        <input id="password" class="form-control" name="password" type="password" onkeypress="capsCheck(event,this);">
                     </div>
                  </div>
                  <div class="form-group pull-right">
                     <button class=" btn btn-default" type="submit" href="javascript: submitform()"><i class="fa fa-sign-in"></i> Login</button>
                  </div>
               </fieldset>
            </form>
         </div>
      </div>
      %if error:
      <div class="alert alert-danger" role="alert">
         <strong>Warning!</strong>
         {{error}}
      </div>
      %end
   </div>
</div>

