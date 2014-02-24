%rebase layout title='Shinken UI login', print_header=False, js=['login/js/pass_shark.js']

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
	<h1>Shinken <small>v {{VERSION}}</small></h1>
</div>

<div class="row">

	%if login_text:
	<p class="lead">{{login_text}}</p>
	%end
	<img src="/static/img/logo_small.png" />
	<!-- <img src="/static/img/mascot.png" /> -->
	
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
						<button class=" btn btn-success" type="submit" href="javascript: submitform()"><i class="icon-signin"></i> Login</button>
					</div>
				</fieldset>
			</form>
		</div>
	</div>
</div>
