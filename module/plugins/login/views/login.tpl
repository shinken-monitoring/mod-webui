%rebase layout title='Shinken UI login', print_header=False, js=['login/js/detectmobilebrowser.js','login/js/capslock.js'], css=['login/css/login.css']

<script type="text/javascript">
// If we are a mobile device, go in the /mobile part :)
$(document).ready(function(){
  // jQuery.browser.mobile is filled by login/js/detectmobilebrowser.js
  if($.browser.mobile){
    window.location = '/mobile/';
  }
});
</script>

<div id="login_container" class="col-lg-9">

  %if login_text:
  <p><span id="login-text"> {{login_text}}</span></p>
  %end
  <noscript>
    <div class="row alert">
      <button type="button" class="close" data-dismiss="alert">×</button>
      <div class="font-red"><strong>Warning!</strong> Please enable Java Script in your browser and retry.</div>
    </div>
  </noscript>
  <div class="row well">
    <div >
    	<img class="col-lg-5" src="/static/img/logo.png" alt="Shinken is awesome!">
    </div>
    <div class="col-lg-6">
      %if error:
      <div class="alert alert-error">
        <strong>Warning!</strong>
        {{error}}
      </div>
      %end

      <form method="post" id="loginform" class="form-horizontal" action="/user/auth">
        <fieldset>
          <div class="form-group">
            <label class="col-lg-2 control-label">Name</label>
            <div class="col-lg-10">
              <input class="form-control" name="login" type="text">
            </div>
          </div>
          <div class="form-group">
            <label class="col-lg-2 control-label">Password</label>
            <div class="col-lg-10">
              <input id="password" class="form-control" name="password" type="password" onkeypress="capsCheck(event,this);">
            </div>         
          </div>
          <div class="form-group col-lg-10 pull-right" style="margin-left: 0; padding-left: 0">
            <button class=" btn btn-success btn-block" type="submit" href="javascript: submitform()"><i class="icon-signin"></i> Login</button>
          </div>
        </fieldset>
      </form>
    </div>
  </div>
</div>
