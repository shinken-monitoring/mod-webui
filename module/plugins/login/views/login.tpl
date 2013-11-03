%rebase layout title='Shinken UI Login', print_header=False, js=['login/js/detectmobilebrowser.js','login/js/capslock.js'], css=['login/css/login.css']

%from shinken.bin import VERSION

<script type="text/javascript">
// If we are a mobile device, go in the /mobile part :)
$(document).ready(function(){
  // jQuery.browser.mobile is filled by login/js/detectmobilebrowser.js
  if($.browser.mobile){
    window.location = '/mobile/';
  }
});
</script>

<div class="page-header">
  <h1>Shinken <small>v {{VERSION}}</small></h1>
</div>

<div class="row">
  <div class="col-xs-6 col-sm-8 col-md-8">
    <noscript>
      <div class="row alert">
        <button type="button" class="close" data-dismiss="alert">×</button>
        <div class="font-red"><strong>Warning!</strong> Please enable Java Script in your browser and retry.</div>
      </div>
    </noscript>


    %if login_text:
    <p class="lead">{{login_text}}</p>
    %end

    %if error:
    <div class="alert alert-error">
      <strong>Warning!</strong>
      {{error}}
    </div>
    %end

    <!-- <div>
      <h2>Maintance News</h2>
        <p>Todo import script?</p>
    </div> -->

  </div>

  <div class="col-xs-6 col-sm-4 col-md-4">
    <div class="panel panel-default">
      <div class="panel-heading">
        <h4 class="panel-title">Login</h4>
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
              <button class=" btn btn-success" type="submit" href="javascript: submitform()"><i class="icon-signin"></i> Login</button>
            </div>
          </fieldset>
        </form>
      </div>
    </div>
  </div>
</div>

