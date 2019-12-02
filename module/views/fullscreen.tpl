%# Default is to consider that the underlying framework is not Alignak (hence Shinken)
%setdefault('alignak', False)
%setdefault('fmwk', 'Shinken')

%setdefault('auto_refresh', 0)
%setdefault('css_body', '')

%if alignak:
%from alignak.version import VERSION
%fmwk="Alignak"
%else:
%from shinken.bin import VERSION
%end

<!DOCTYPE html>
%#Set default values
%#if not 'js' in locals(): js = []
%#if not 'css' in locals(): css = []
%#if not 'title' in locals(): title = 'Untitled ...'
%setdefault('js', [])
%setdefault('css', [])
%setdefault('title', 'Untitled ...')

%setdefault('user', None)
%setdefault('app', None)

%if app is not None:
%helper = app.helper
%refresh = app.refresh
%end

<html lang="en">
   <head>
      <meta charset="utf-8">
      <meta http-equiv="X-UA-Compatible" content="IE=edge">
      <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
      %if auto_refresh:
      <meta http-equiv="refresh" content="{{auto_refresh}}" >
      %end
      <title>{{title or 'No title'}}</title>

      <!--
         This file is a part of Shinken WebUI.

         Shinken is free software: you can redistribute it and/or modify it under the terms of the
         GNU Affero General Public License as published by the Free Software Foundation, either
         version 3 of the License, or (at your option) any later version.

         WebUI Version: {{app.app_version if app is not None and app.app_version is not None else ''}}
         {{fmwk}} Framework Version: {{VERSION}}
      -->

      <link href="/favicon.ico" rel="shortcut icon">

      <!--[if lt IE 9]>
      <script src="/static/js/ie9/html5.js"></script>
      <script src="/static/js/ie9/json2.js"></script>
      <![endif]-->

      <!-- Stylesheets
      ================================================== -->
      <link href="/static/css/bootstrap.min.css?v={{app.app_version}}" rel="stylesheet">
      <link href="/static/css/font-awesome-all.min.css?v={{app.app_version}}" rel="stylesheet">
      <link href="/static/css/metisMenu.min.css?v={{app.app_version}}" rel="stylesheet">

      <link href="/static/css/shinken-layout.css?v={{app.app_version}}" rel="stylesheet">
      <link href="/static/css/alertify.css?v={{app.app_version}}" rel="stylesheet">

      %# And now for css files
      %for p in css:
      <link rel="stylesheet" type="text/css" href="/static/{{p}}?v={{app.app_version}}">
      %end

      <!-- Scripts
      ================================================== -->
      <script src="/static/js/jquery-1.12.0.min.js?v={{app.app_version}}"></script>
      <script src="/static/js/jquery-ui-1.11.4.min.js?v={{app.app_version}}"></script>
      <script src="/static/js/bootstrap.min.js?v={{app.app_version}}"></script>
      <script src="/static/js/metisMenu.min.js?v={{app.app_version}}"></script>

      <script src="/static/js/moment.min.js?v={{app.app_version}}"></script>

      <script src="/static/js/jquery.jclock.js?v={{app.app_version}}"></script>
      <script src="/static/js/alertify.js?v={{app.app_version}}"></script>

      <!--
       WebUI globals ...
      -->
      <script>
      var dashboard_currently = false;
      </script>

      <!--WebUI ones : refresh pages -->
      %if refresh:
      <script>
      var app_refresh_period = {{app.refresh_period}};
      </script>
      <script src="/static/js/shinken-refresh.js?v={{app.app_version}}"></script>
      %end
      <script src="/static/js/shinken-layout.js?v={{app.app_version}}"></script>
      <script src="/static/js/shinken-actions.js?v={{app.app_version}}"></script>
      <script src="/static/js/screenfull.js?v={{app.app_version}}"></script>
      <script src="/static/js/shinken-tooltip.js?v={{app.app_version}}"></script>

      %# End of classic js import. Now call for specific ones ...
      %for p in js:
      <script type="text/javascript" src="/static/{{p}}?v={{app.app_version}}"></script>
      %end
   </head>

   <body style="{{css_body if css_body else ''}}">
      <div class="container-fluid">
         <div id="page-wrapper" class="fullscreen">
            <!-- Page content -->
            <section class="content">
               {{!base}}
            </section>
            %#include("footer_element")
         </div>
      </div>
   </body>
</html>
