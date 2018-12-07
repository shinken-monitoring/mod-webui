%# Default is to consider that the underlying framework is not Alignak (hence Shinken)
%setdefault('alignak', False)
%setdefault('fmwk', 'Shinken')

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

%# Layout is built with:
%# - page header: logo, top navigation bar, indicators, user menu
%# - side menu: left sidebar menu
%# - content: including current page layout with title
%# - page footer: copyright
%# For breadcrumb, declare as is when rebasing layout:
%# - breadcrumb=[ ['Groups', '/servicegroups'], [groupalias, '/servicegroup/'+groupname] ]
%setdefault('breadcrumb', '')

%setdefault('user', None)
%setdefault('app', None)

%setdefault('navi', None)
%setdefault('elts_per_page', 25)

%if app is not None:
%helper = app.helper
%refresh = app.refresh
%end

<html lang="en">
   <head>
      <meta charset="utf-8">
      <meta http-equiv="X-UA-Compatible" content="IE=edge">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>{{title or 'No title'}}</title>

      <!--
         This file is a part of Shinken.

         Shinken is free software: you can redistribute it and/or modify it under the terms of the
         GNU Affero General Public License as published by the Free Software Foundation, either
         version 3 of the License, or (at your option) any later version.

         WebUI Version: {{app.app_version if app is not None and app.app_version is not None else ''}}
         {{fmwk}} Framework Version: {{VERSION}}
      -->

      <link href="/static/images/favicon.ico" rel="shortcut icon">

      <!--[if lt IE 9]>
      <script src="/static/js/ie9/html5.js"></script>
      <script src="/static/js/ie9/json2.js"></script>
      <![endif]-->

      <!-- Stylesheets
      ================================================== -->
      <link href="/static/css/bootstrap.min.css?v={{app.app_version}}" rel="stylesheet">
      <!--<link href="/static/css/bootstrap-theme.min.css" rel="stylesheet">-->
      <link href="/static/css/font-awesome.min.css?v={{app.app_version}}" rel="stylesheet">
      <link href="/static/css/metisMenu.min.css?v={{app.app_version}}" rel="stylesheet">
      <link href="/static/css/sb-admin-2.css?v={{app.app_version}}" rel="stylesheet">
      <link href="/static/css/typeahead.css?v={{app.app_version}}" rel="stylesheet">
      <link href="/static/css/daterangepicker.css?v={{app.app_version}}" rel="stylesheet">
      <link href="/static/css/shinken-layout.css?v={{app.app_version}}" rel="stylesheet">
      <link href="/static/css/alertify.css?v={{app.app_version}}" rel="stylesheet">

      <!-- css3 effect for pulse is not available on IE It's not real comment, if so it will not work. -->
      <!--[IF !IE]> -->
      <link href="/static/css/pulse.css?v={{app.app_version}}" rel="stylesheet">
      <!-- <![ENDIF]-->

      %# And now for css files
      %for p in css:
      <link rel="stylesheet" type="text/css" href="/static/{{p}}?v={{app.app_version}}">
      %end

      <!-- Opensearch
      ================================================== -->
      <link rel="search" type="application/opensearchdescription+xml" href="/opensearch.xml" title="Search for hosts and services in Shinken" />

      <!-- Scripts
      ================================================== -->
      <script src="/static/js/jquery-1.12.0.min.js"></script>
      <script src="/static/js/shinken-bookmarks.js?v={{app.app_version}}"></script>
   </head>

   <body>
      <div id="wrapper">
         %include("header_element")
         <div id="page-wrapper">

            <!-- Do not remove the next comment!
               Everything between 'begin-page-content' comment and 'end-page-content' comment
               is used by the layout page refresh.
               @mohierf: for future refresh implementation ... not used currently!
            -->
            <!--begin-page-content-->
            <div id="page-content">
               <div class="row">
                  <!-- Page header -->
                  <section class="content-header">
                     %if navi:
                     %include("pagination_element", navi=navi, page=page, elts_per_page=elts_per_page, display_steps_form=True, drop="dropdown")
                     %end
                     <h3 class="page-header" style="margin-top: 10px">
                       <ol class="breadcrumb" style="margin:0px">
                         <li><a href="/">Home</a></li>
                         %if breadcrumb == '':
                         <li class="active">{{title or 'No title'}}</li>
                         %else:
                         %_go_active = 'active'
                         %for p in breadcrumb:
                         %_go_active = ''
                         %if p[0]:
                         <li class="{{_go_active}}"><a href="{{p[1]}}">{{p[0]}}</a></li>
                         %else:
                         <li class="{{_go_active}}">{{p}}</li>
                         %end
                         %end
                         %end
                       </ol>
                     </h3>

                  </section>

                  <!-- Page content -->
                  <section class="content">
                     {{!base}}
                  </section>

                  %if navi and len(navi) > 1:
                  <hr>
                  <section class="pagination-footer">
                  %include("pagination_element", navi=navi, page=page, elts_per_page=elts_per_page, display_steps_form=True, drop="dropup")
                  </section>
                  %end
               </div>
            </div>
            <!--end-page-content-->

         </div>
      </div>

      %include("footer_element")

      <!-- A modal div that will be filled and shown when we want forms ... -->
      <div class="modal fade" id="modal" role="dialog" aria-labelledby="Generic modal box" aria-hidden="true">
         <div class="modal-dialog">
            <div class="modal-content">
               <div class="modal-header">
                  <h4 class="modal-title">Generic modal</h4>
               </div>
               <div class="modal-body">
                  <!-- Filled by application ... -->
               </div>
               <div class="modal-footer">
                  <a href="#" class="btn btn-default" data-dismiss="modal">Close</a>
               </div>
            </div>
         </div>
      </div>

      <!--
       Shinken scripts ...
      -->

      <script src="/static/js/bootstrap.min.js?v={{app.app_version}}"></script>
      <script src="/static/js/bootstrap-tab-bookmark.js?v={{app.app_version}}"></script>
      <script src="/static/js/metisMenu.min.js?v={{app.app_version}}"></script>
      <script src="/static/js/sb-admin-2.js?v={{app.app_version}}"></script>
      <script src="/static/js/moment.min.js?v={{app.app_version}}"></script>
      <script src="/static/js/daterangepicker.js?v={{app.app_version}}"></script>
      <script src="/static/js/jquery.jclock.js?v={{app.app_version}}"></script>
      <script src="/static/js/jquery.jTruncate.js?v={{app.app_version}}"></script>
      <script src="/static/js/alertify.js?v={{app.app_version}}"></script>
      <script src="/static/js/typeahead.bundle.min.js?v={{app.app_version}}"></script>
      <script src="/static/js/screenfull.js?v={{app.app_version}}"></script>

      <!--
       Shinken globals ...
      -->
      <script>
      var dashboard_currently = false;

      // Configuration for shinken-actions.js
      %user = app.get_user()
      var user='{{ user.alias if hasattr(user, "alias") and user.alias != "none" else user.get_name() }}';
      var shinken_downtime_fixed='{{ app.shinken_downtime_fixed}}';
      var shinken_downtime_trigger='{{ app.shinken_downtime_trigger }}';
      var shinken_downtime_duration='{{ app.shinken_downtime_duration }}';
      var default_ack_persistent='{{ app.default_ack_persistent }}';
      var default_ack_notify='{{ app.default_ack_notify }}';
      var default_ack_sticky='{{ app.default_ack_sticky }}';
      </script>

      <!--
       Shinken scripts ...
      -->
      %if refresh:
      <script>
      var app_refresh_period = {{app.refresh_period}};
      </script>
      <script src="/static/js/shinken-refresh.js?v={{app.app_version}}"></script>
      <script src="/static/js/shinken-actions.js?v={{app.app_version}}"></script>
      %end

      <script src="/static/js/shinken-layout.js?v={{app.app_version}}"></script>
      <script src="/static/js/shinken-tooltip.js?v={{app.app_version}}"></script>

      %# Include specific Js files ...
      %for p in js:
      <script type="text/javascript" src="/static/{{p}}?v={{app.app_version}}"></script>
      %end
   </body>
</html>
