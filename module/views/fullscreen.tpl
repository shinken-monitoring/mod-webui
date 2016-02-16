<!DOCTYPE html>
%#Set default values
%#if not 'js' in locals(): js = []
%#if not 'css' in locals(): css = []
%#if not 'title' in locals(): title = 'Untitled ...'
%setdefault('js', [])
%setdefault('css', [])
%setdefault('title', 'Untitled ...')

%# Current page may be refreshed or not
%setdefault('refresh', True)

%setdefault('user', None)
%setdefault('app', None)

%from shinken.bin import VERSION
%if app is not None:
%helper = app.helper
%end

<html lang="en">
   <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
      <title>{{title or 'No title'}}</title>

      <!--
         This file is a part of Shinken.

         Shinken is free software: you can redistribute it and/or modify it under the terms of the
         GNU Affero General Public License as published by the Free Software Foundation, either
         version 3 of the License, or (at your option) any later version.

         WebUI Version: {{app.app_version if app is not None and app.app_version is not None else ''}}
         Shinken Framework Version: {{VERSION}}
      -->

      <link href="/static/images/favicon.ico" rel="shortcut icon">

      <!--[if lt IE 9]>
      <script src="/static/js/ie9/html5.js"></script>
      <script src="/static/js/ie9/json2.js"></script>
      <![endif]-->

      <!-- Stylesheets
      ================================================== -->
      <link href="/static/css/bootstrap.min.css" rel="stylesheet">
      <link href="/static/css/bootstrap-theme.min.css" rel="stylesheet">
      <link href="/static/css/font-awesome.min.css" rel="stylesheet">

      <link href="/static/css/shinken-layout.css" rel="stylesheet">
      <link href="/static/css/alertify.css" rel="stylesheet">

      %# And now for css files
      %for p in css:
      <link rel="stylesheet" type="text/css" href="/static/{{p}}">
      %end

      <!-- Scripts
      ================================================== -->
      <script src="/static/js/jquery-1.12.0.min.js"></script>
      <script src="/static/js/jquery-ui-1.11.4.min.js"></script>
      <script src="/static/js/bootstrap.min.js"></script>

      <script src="/static/js/moment.min.js"></script>

      <script src="/static/js/jquery.jclock.js"></script>
      <script src="/static/js/alertify.js"></script>

      <!--
       Shinken globals ...
      -->
      <script>
      var dashboard_currently = false;
      </script>

      <!--Shinken ones : refresh pages -->
      %if refresh:
      <script>
      var app_refresh_period = {{app.refresh_period}};
      </script>
      <script src="/static/js/shinken-refresh.js"></script>
      %end
      <script src="/static/js/screenfull.js"></script>
      <script src="/static/js/shinken-actions.js"></script>

      %# End of classic js import. Now call for specific ones ...
      %for p in js:
      <script type="text/javascript" src="/static/{{p}}"></script>
      %end
   </head>

   <body>
      <div class="container-fluid">
         <div id="page-wrapper" class="fullscreen">
            <!-- Page content -->
            <section class="content">
            %include
            </section>
            %#include("footer_element")
         </div>
      </div>
   </body>
</html>
