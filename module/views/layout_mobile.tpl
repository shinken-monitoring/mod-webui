<!DOCTYPE html>
%#Set default values
%setdefault('title', 'No title')
%setdefault('js', [])
%setdefault('css', [])
%setdefault('print_menu', True)
%setdefault('print_header', True)
%setdefault('refresh', False)
%setdefault('user', None)
%setdefault('app', None)
%setdefault('menu_part', '')
%setdefault('back_hide', False)

%print "APP is", app
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>{{title or 'No title'}}</title>
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <link rel="stylesheet" href="/static/css/jquery.mobile-1.4.4.min.css" />
    <link rel="stylesheet" href="/static/css/shinken-mobile.min.css" />
    <script src="/static/js/jquery-1.11.1.min.js"></script>
    <script src="/static/js/jquery.mobile-1.4.4.min.js"></script>
  </head>

<body>
 	%include("header_element_mobile")
  <div data-role="content">
    %include
  </div>

  	%include("footer_element_mobile")

  </body>
  	<script type="text/javascript" >
		$('[data-role=page]').live('swipeleft', function(event) {
			$.mobile.changePage($('#right_link').attr('href'));
		});

		$('[data-role=page]').live('swiperight', function(event) {
			$.mobile.changePage($('#left_link').attr('href'), {transition:'slide', reverse:true});
		});
	</script>
</html>
