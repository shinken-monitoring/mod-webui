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
    
    <link href="/static/css/shinken-layout.css" rel="stylesheet">
    
    <!-- css3 effect for pulse is not available on IE It's not real comment, if so it will not work. -->
    <!--[IF !IE]> -->
    <link href="/static/css/pulse.css" rel="stylesheet">
    <!-- <![ENDIF]-->

    <!-- Warning, this version of datepicker came from http://dl.dropbox.com/u/143355/datepicker/datepicker.html -->
    <!-- TODO : find a more recent version ! 
    <link href="/static/css/custom/datepicker.css" rel="stylesheet">
    -->

    %# And now for css files
    %for p in css:
    <link rel="stylesheet" type="text/css" href="/static/{{p}}">
    %end

    <!-- Scripts
    ================================================== -->
    <script src="/static/js/jquery-1.11.0.min.js"></script>
    <script src="/static/js/jquery-ui-1.10.3.min.js"></script>
    <script src="/static/js/bootstrap.min.js"></script>

    <script src="/static/js/shinken-layout.js"></script>

    <script src="/static/js/jquery.jclock.js"></script>
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
    <script src="/static/js/shinken-widgets.js"></script>
    <script src="/static/js/shinken-actions.js"></script>
<!--
    <script src="/static/js/shinken-deptree.js"></script>
    <script src="/static/js/shinken-greeting.js"></script>
    <script src="/static/js/shinken-opacity.js"></script>
    <script src="/static/js/shinken-modals.js"></script>
    <script src="/static/js/shinken-canvas.js"></script>
    <script src="/static/js/shinken-treemap.js"></script>
    <script src="/static/js/shinken-aggregation.js"></script>
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
          <h1>{{title or 'Untitled ...'}}</h1>

          <ol class="breadcrumb">
            <li><a href="/">Home</a></li>
            <li class="active">{{title or 'No title'}}</li>
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

    <!-- A modal div that will be filled and shown when we want ... -->
    <div class="modal fade" id="modal"></div>

    <!-- About modal window -->
    <div class="modal fade" id="about">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
            <h4 class="modal-title">Shinken</h4>
          </div>
          <div class="modal-body">
            <!-- About Form -->
            <form class="form-horizontal">
              <fieldset>
                <!-- Version -->
                <div class="control-group">
                  <label class="control-label" for="app_version">Version</label>
                  <div class="controls">
                    <input required="" readonly="" name="app_version" type="text" class="form-control" placeholder="Not set" class="input-medium" value="WebUI Version: 1.1.0-dev.3 (Contis) - Shinken Framework Version: {{VERSION}}">
                  </div>
                </div>

                <!-- Copyright -->
                <div class="control-group">
                  <label class="control-label" for="app_copyright">Copyright</label>
                  <div class="controls">
                    <input required="" readonly="" name="app_copyright" type="text" class="form-control" placeholder="Not set" class="input-medium" value="License GNU AGPL as published by the FSF, minimum version 3 of the License.">
                  </div>
                </div>

                <!-- Release notes -->
                <div class="control-group">
                  <label class="control-label" for="app_release">Release notes</label>
                  <div class="controls">
                    <input required="" readonly="" name="app_release" type="text" class="form-control" placeholder="Not set" class="input-medium">
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
