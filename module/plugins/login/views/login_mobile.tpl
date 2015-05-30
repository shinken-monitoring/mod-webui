%rebase("layout", title='Shinken UI login', print_header=False, js=['login/js/pass_shark.js'])

%from shinken.bin import VERSION

<script type="text/javascript">
	function submitform() {
		document.forms["loginform"].submit();
	}

	/* Catch the key ENTER and launch the form
	 Will be link in the password field
	*/
	function submitenter(myfield,e) {
		var keycode;
		if (window.event) keycode = window.event.keyCode;
		else if (e) keycode = e.which;
		else return true;

		if (keycode == 13) {
			submitform();
			return false;
		} else
			return true;
	}
</script>

<div class="page-header">
	<h1 class="col-sm-12 col-md-6">Shinken <small>v {{VERSION}}</small></h1>
	%if company_logo:
	<div class="col-sm-12 col-md-6"> <img src="/static/images/logo/{{company_logo}}" /></div>
	%end
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
    <img src="/static/images/logo/logo_small.png" />
	</div>

	<div class="col-sm-12 col-md-6">
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
                <input id="password" class="form-control" name="password" type="password" onkeypress="return submitenter(this,event);">
              </div>
            </div>
            <div class="form-group pull-right">
              <button class=" btn btn-default" type="submit" href="javascript: submitform()"><i class="fa fa-sign-in"></i> Login</button>
            </div>
          </fieldset>
        </form>
      </div>
    </div>
  </div>
</div>
