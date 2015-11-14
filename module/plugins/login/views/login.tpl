<!DOCTYPE html>

%from shinken.bin import VERSION

<html lang="en">
   <head>
      <meta charset="utf-8">
      <title>Shinken WebUI Login page</title>

      <!--
         This file is a part of Shinken.

         Shinken is free software: you can redistribute it and/or modify it under the terms of the
         GNU Affero General Public License as published by the Free Software Foundation, either
         version 3 of the License, or (at your option) any later version.

         WebUI Version: {{app.app_version}}
         Shinken Framework Version: {{VERSION}}
      -->

      <!-- Stylesheets
      ================================================== -->
      <link href="/static/css/bootstrap.min.css" rel="stylesheet">
      <link href="/static/css/bootstrap-theme.min.css" rel="stylesheet">
      <link href="/static/css/font-awesome.min.css" rel="stylesheet">
      <link href="/static/css/shinken-layout.css" rel="stylesheet">

      <!-- Scripts
      ================================================== -->
      <script src="/static/js/jquery-1.11.1.min.js"></script>
      <script src="/static/js/bootstrap.min.js"></script>
   </head>

   <body>
      <div class="container" style="padding-top: 100px;">
         <div class="col-md-4 col-md-offset-4">
            <div class="login-panel panel panel-default">
               <div class="panel-heading">
                  <h2>Shinken <small>version {{VERSION}}</small></h2>
                  <center>
                     <img src="/static/logo/{{company_logo}}" alt="Company logo" style="width: 80%"/>
                  </center>
               </div>
               <div class="panel-body">
                  <form role="form" method="post" action="/user/auth">
                     <fieldset>
                        <div class="form-group">
                           <input class="form-control" placeholder="username" name="login" type="text" autofocus>
                        </div>
                        <div class="form-group">
                           <input class="form-control" placeholder="Password" name="password" type="password" value="">
                        </div>

                        <button class="btn btn-lg btn-success btn-block" type="submit"><i class="fa fa-sign-in"></i> Login</button>
                     </fieldset>
                  </form>
               </div>
               <div class="panel-footer">
                  %if msg_text:
                  <div class="alert alert-danger" role="alert">
                     <strong>Warning!</strong>
                     {{msg_text}}
                  </div>
                  %end
                  <div style="min-height: 100px;">
                     <img src="/static/images/shinken.png" style="position: relative; top:-30px; left:-12px; width: 120px;" class="pull-left"/>
                     %if login_text:
                     <h3>{{login_text}}</h3>
                     %end
                  </div>
               </div>
            </div>
         </div>
      </div>

      %include("footer_element")
   </body>
</html>
