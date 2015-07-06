%rebase("layout", title='Shinken Web UI Login', print_header=False, print_menu=False, print_title=False)

%from shinken.bin import VERSION

<div class="container">
   <div class="row">
      <div class="col-md-4 col-md-offset-4">
         <div class="login-panel panel panel-default">
            <div class="panel-heading">
               <h2>Shinken <small>version {{VERSION}}</small></h2>
                  <img src="/static/logo/{{company_logo}}" alt="Company logo" style="width: 100%"/>
            </div>
            <div class="panel-body">
               <form role="form" method="post" action="/user/auth">
                  <fieldset>
                     <div class="form-group">
                        <input class="form-control" placeholder="username" name="login" type="text" autofocus>
                     </div>
                     <div class="form-group">
                        <input class="form-control" placeholder="Password" name="password" type="password" value="">
                     </div>
                     <!--
                     <div class="checkbox">
                        <label>
                           <input name="remember" type="checkbox" value="Remember Me">Remember Me
                        </label>
                     </div>
                     -->
                     
                     <button class="btn btn-lg btn-success btn-block" type="submit"><i class="fa fa-sign-in"></i> Login</button>
                  </fieldset>
               </form>
            </div>
            <div class="panel-footer">
               <div style="min-height: 70px;">
                  <img src="/static/images/shinken.png" style="position: relative; top:-30px; left:-12px; height: 48px" class="pull-left"/>
                  %if login_text:
                  <h3>{{login_text}}</h3>
                  %end
               </div>
               %if error:
               <div class="alert alert-danger" role="alert">
                  <strong>Warning!</strong>
                  {{error}}
               </div>
               %end
            </div>
         </div>
      </div>
   </div>
</div>
