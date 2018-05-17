<!DOCTYPE html>

%from shinken.bin import VERSION

<html lang="en">
   <head>
      <meta charset="utf-8">
      <title>Shinken WebUI Login page</title>
      <meta name="viewport" content="width=device-width, initial-scale=1">

      <!--
         This file is a part of Shinken.

         Shinken is free software: you can redistribute it and/or modify it under the terms of the
         GNU Affero General Public License as published by the Free Software Foundation, either
         version 3 of the License, or (at your option) any later version.

         WebUI Version: {{app.app_version}}
         Shinken Framework Version: {{VERSION}}
      -->

      <link href="/static/images/favicon.ico" rel="shortcut icon">

      <!-- Stylesheets
      ================================================== -->
      <link href="/static/css/bootstrap.min.css" rel="stylesheet">
      <link href="/static/css/bootstrap-theme.min.css" rel="stylesheet">
      <link href="/static/css/font-awesome.min.css" rel="stylesheet">
      <link href="/static/css/shinken-layout.css" rel="stylesheet">

      <!-- Scripts
      ================================================== -->
      <script src="/static/js/jquery-1.12.0.min.js"></script>
      <script src="/static/js/bootstrap.min.js"></script>
   </head>

   <body>
      <div class="container" style="padding-top: 100px;">
         <div class="col-md-4 col-md-offset-4 col-sm-8 col-sm-offset-2">
            <div class="login-panel panel panel-default">
               <div class="panel-heading">
                  <center>
                     <img src="/static/logo/{{company_logo}}" alt="Company logo" style="width: 80%"/>
                  </center>
               </div>
               <div class="panel-body">
                  <form role="form" class="form-signin" method="post" action="/user/auth?path={{path}}">
                    <!--<h2>Please sign in</h2>-->
                  %if msg_text:
                  <div class="alert alert-danger" role="alert">
                     <strong>Warning!</strong>
                     {{msg_text}}
                  </div>
                  %end
                    <!--<div class="form-group">-->
                      <input class="form-control" placeholder="Username" name="login" type="text" required autofocus>
                    <!--</div>-->
                    <!--<div class="form-group">-->
                      <input class="form-control" placeholder="Password" name="password" type="password" value="" required>
                    <!--</div>-->
                      <input type="hidden" class="form-control" placeholder="path" name="path" type="path" value="{{path}}">

                    <button class="btn btn-lg btn-success btn-block" type="submit"><i class="fa fa-sign-in"></i> Login</button>
                  </form>
               </div>
            </div>
         </div>
      </div>

      %include("footer_element")
   </body>
</html>
