<!DOCTYPE html>
%import time
%t0 = time.time()

%#Set default values
%if not 'js' in locals(): js = []
%if not 'css' in locals(): css = []
%if not 'title' in locals(): title = 'Untitled ...'

%# Layout is built with:
%# - page header: logo, top navigation bar, indicators, user menu
%# - side menu: left sidebar menu
%# - content: including current page layout with title
%# - page footer: copyright
%# Following variables allow to include or not different layout pieces: 
%if not 'print_menu' in locals(): print_menu = True
%if not 'print_header' in locals(): print_header = True
%if not 'print_title' in locals(): print_title = True
%if not 'print_footer' in locals(): print_footer = True
%# For breadcrumb, declare as is when rebasing layout: 
%# - breadcrumb=[ ['Groups', '/servicegroups'], [groupalias, '/servicegroup/'+groupname] ]
%if not 'breadcrumb' in locals(): breadcrumb = ''

%# Current page may be refreshed or not
%if not 'refresh' in locals(): refresh = False

%if not 'user' in locals(): user = None
%if not 'app' in locals(): app = None

%from shinken.bin import VERSION
%if app is not None: helper = app.helper

<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>{{title or 'No title'}}</title>

    %include copyright_element globals()

    <!--[if lt IE 9]>
    <script src="/static/js/ie9/html5.js"></script>
    <script src="/static/js/ie9/json2.js"></script>
    <![endif]-->

    <!-- Stylesheets 
    ================================================== -->
    <link href="/static/css/bootstrap.min.css" rel="stylesheet">
    <link href="/static/css/font-awesome.min.css" rel="stylesheet">
    <link href="/static/css/Shinken-webUI.css" rel="stylesheet">

    <link href="/static/css/jquery.meow.css" rel="stylesheet">
    <link href="/static/css/typeahead.css" rel="stylesheet">

    <link href="/static/css/daterangepicker.css" rel="stylesheet">
    <!--
    <link href="/static/css/bootstrap-datetimepicker.min.css" rel="stylesheet">
    -->
    
    <link href="/static/css/shinken-layout.css" rel="stylesheet">
    
    <!-- css3 effect for pulse is not available on IE It's not real comment, if so it will not work. -->
    <!--[IF !IE]> -->
    <link href="/static/css/pulse.css" rel="stylesheet">
    <!-- <![ENDIF]-->

    %# And now for css files
    %for p in css:
    <link rel="stylesheet" type="text/css" href="/static/{{p}}">
    %end

    <!-- Scripts
    ================================================== -->
    <script src="/static/js/jquery-1.11.0.min.js"></script>
    <script src="/static/js/jquery-ui-1.10.3.min.js"></script>
    <script src="/static/js/bootstrap.min.js"></script>

    <script src="/static/js/moment.min.js"></script>
    
    <!-- See: https://github.com/dangrossman/bootstrap-daterangepicker -->
    <script src="/static/js/daterangepicker.js"></script>
    
    <!-- See: http://www.malot.fr/bootstrap-datetimepicker/demo.php 
    <script src="/static/js/bootstrap-datetimepicker.min.js"></script>
    -->
    
    <script src="/static/js/shinken-layout.js"></script>

    <script src="/static/js/jquery.jclock.js"></script>
    <script src="/static/js/jquery.jTruncate.js"></script>
    <script src="/static/js/jquery.meow.js"></script>
    <script src="/static/js/typeahead.bundle.min.js"></script>

    <!--Shinken ones : refresh pages -->
    %if refresh:
    <script>
      var app_refresh_period = {{app.refresh_period}};
    </script>
    <script src="/static/js/shinken-refresh.js"></script>
    %end
    <!--Shinken ones : dashboard widgets -->
    <script src="/static/js/shinken-ui.js"></script>
    <script src="/static/js/shinken-actions.js"></script>
    <script src="/static/js/shinken-aggregation.js"></script>
    <script src="/static/js/shinken-deptree.js"></script>
    <script src="/static/js/shinken-canvas.js"></script>
<!--
    <script src="/static/js/shinken-greeting.js"></script>
    <script src="/static/js/shinken-opacity.js"></script>
    <script src="/static/js/shinken-modals.js"></script>
    <script src="/static/js/shinken-treemap.js"></script>
-->

    %# End of classic js import. Now call for specific ones
    %for p in js:
    <script type="text/javascript" src="/static/{{p}}"></script>
    %end
  </head>

  <body class="skin-blue">
    %if print_header:
      %include header_element globals()
    %end	
    
    <div class="wrapper row-offcanvas row-offcanvas-left">
      <aside class="left-side sidebar-offcanvas">
        <!-- Left side column. Contains the user panel (clock) and sidebar menu -->
        <section class="sidebar">
        %if print_menu:
          %include sidebar_element globals()
        %end
        </section>
      </aside>
      <!-- Right side column. Contains the content of the page -->
      <aside class="right-side">
        %if print_title:
        <!-- Page header -->
        <section class="content-header">
          <h1>{{!title or 'Untitled ...'}}</h1>

          <ol class="breadcrumb">
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
        </section>
        %end

        <!-- Page content -->
        <section class="content">
          %include
        </section>
      </aside>
      %if not print_menu:
        <script type="text/javascript">
        $(document).ready(function(){
          window.setTimeout(function() { 
            $('.left-side').toggleClass("collapse-left");
            $(".right-side").toggleClass("strech");
          }, 0);
        });
        </script>
      %end
    </div>

    <!-- A modal div that will be filled and shown when we want for forms ... -->
    <div class="modal fade" id="modal" role="dialog" aria-labelledby="Generic modal box" aria-hidden="true">
      <div class="modal-dialog modal-lg">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
            <h4 class="modal-title">About Shinken Web UI:</h4>
          </div>
          <div class="modal-body">
            <!--  ... -->
          </div>
          <div class="modal-footer">
            <a href="#" class="btn btn-default" data-dismiss="modal">Close</a>
          </div>
        </div>
      </div>
    </div>
    
    <script type="text/javascript">
    $(function() {
      $('#modal').on('hidden.bs.modal', function () {
        // Clean modal content when hidden ...
        $(this).removeData('bs.modal');
      });
    });
    </script>

    <!-- About modal window -->
    <div class="modal fade" role="dialog" aria-labelledby="About box" aria-hidden="true" id="about">
      <div class="modal-dialog modal-lg">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
            <h4 class="modal-title">About Shinken Web UI:</h4>
          </div>
          <div class="modal-body">
            <!-- About Form -->
            <form class="form-horizontal">
              <fieldset>
                <div class="control-group">
                  <label class="control-label" for="app_version">Web User Interface Version</label>
                  <div class="controls">
                    <input required="" readonly="" name="app_version" type="text" class="form-control" placeholder="Not set" class="input-medium" value="Shinken Web UI, version: {{app.app_version if app is not None else ''}}">
                  </div>
                </div>

                <div class="control-group">
                  <label class="control-label" for="shinken_version">Shinken Framework Version</label>
                  <div class="controls">
                    <input required="" readonly="" name="shinken_version" type="text" class="form-control" placeholder="Not set" class="input-medium" value="Shinken Framework, version: {{VERSION}}">
                  </div>
                </div>

                <div class="control-group">
                  <label class="control-label" for="app_copyright">Copyright</label>
                  <div class="controls">
                    <input required="" readonly="" name="app_copyright" type="text" class="form-control" placeholder="Not set" class="input-medium" value="{{app.app_copyright if app is not None else ''}}">
                  </div>
                </div>

                <div class="control-group">
                  <label class="control-label" for="app_release">Release notes</label>
                  <div class="controls">
                    <input required="" readonly="" name="app_release" type="text" class="form-control" placeholder="Not set" class="input-medium" value="{{app.app_release if app is not None else ''}}">
                  </div>
                </div>

              </fieldset>
            </form>
          </div>
          <div class="modal-footer">
            <a href="#" class="btn btn-default" data-dismiss="modal">Close</a>
          </div>
        </div>
      </div>
    </div>

    %if print_footer:
      %include footer_element globals()
    %end
  </body>
</html>
