.. _webui_index:

WebUI module
########################

Shinken includes a self sufficient Web User Interface, which includes its own web server (No need to setup Apache or Microsoft IIS)

Shinken WebUI is started at the same time Shinken itself does, and is configured by setting a few basic parameters. 

Overview 
=========
Enable the webui **module** in the broker daemon configuration file (*brokers/broker-master.cfg*).

::

   define broker {
       broker_name     broker-master
       
       ...
       
       modules simple-log, webui, statsd, glpidb, livestatus, graphite

   }

WebUI configuration
========================
The WebUI module has its own configuration file (*webui.cfg*) located in the *modules* directory.

This file is largely commented and is quite self explanatory.

::

   ## Module:      WebUI
   ## Loaded by:   Broker
   # The Shinken web interface and integrated web server.
   define module {
      module_name         webui
      module_type         webui
      
      # Web server configuration
      host                       0.0.0.0      ; All interfaces = 0.0.0.0
      port                       7767
      
      # Authentication secret for session cookie
      auth_secret                CHANGEME
                                 ; CHANGE THIS or someone could forge cookies
      
      # Manage contacts ACL
      # 0 allows actions for all contacts
      # 1 allows actions only for contacts whose property 'is_admin' equals to 1
      manage_acl                 1

      # Configuration directory
      config_dir                 /var/lib/shinken/config/
      
      # Login form
      # Welcome text in the login form.
      login_text                 Login to the Shinken WebUI - Live System

      # Company logo in the login form and header bar
      # Default is default_logo.png in webui/htdocs/images/logo
      company_logo               company.png

      allow_html_output          1
                                 ; Allow or not HTML chars in plugins output.
                                 ; WARNING: Allowing can be a security issue.
                           
      max_output_length          1024
                                 ; Maximum output length for plugin output in webui
                           
      play_sound                 0
                                 ; Play sound on new non-acknowledged problems.

      # Gravatar image for users logged in
      gravatar                   0
                                 ; If gravatar=0, image used is username.png in webui/htdocs/images/logo
                                 ; If not found, default is default_user.png in webui/htdocs/images/logo

      # Refresh period
      refresh_period             60
                                 ; Number of seconds between each page refresh

      # WebUI information
      # Overload default information included in the WebUI
      #about_version              2.0 alpha
      #about_copyright            (c) 2013-2015 - License GNU AGPL as published by the FSF, minimum version 3 of the License.
      #about_release              Bootstrap 3 User Interface

      # WebUI timezone (default is Europe/Paris)
      #timezone                  Europe/Paris

      ## Modules for WebUI
      # - auth-htpasswd         = Use an htpasswd file for auth backend.
      # - auth-active-directory = Use AD for auth backend (and retrieve photos).
      # - auth-cfg-password     = Use the password set in Shinken contact for auth.
      # - auth-ws-glpi          = Use the Glpi Web Services for user authentication
      # - ui-pnp                = Use PNP graphs in the UI.
      # - ui-graphite           = Use graphs from Graphite time series database.
      # - mongodb               = Save user preferences to a Mongodb database
      # - SQLitedb              = Save user preferences to a SQLite database
      modules                    auth-cfg-password, auth-ws-glpi, ui-graphite

      ## Advanced Options
      # Best choice is auto, whereas Bottle chooses the best server it finds amongst:
      # - [WaitressServer, PasteServer, TwistedServer, CherryPyServer, WSGIRefServer]
      # Install CherryPy for a multi-threaded server ...
      # ------------
      # Handle with very much care!
      #http_backend              auto
                                 ; Choice is: auto, wsgiref or cherrypy if available
                                 
      # Specific options store in the serverOptions when invoking Bottle run method ...
      # ------------
      # Handle with very much care!
      #bindAddress               auto
                                 ; bindAddress for backend server
      #umask                     auto
                                 ; umask for backend server
                                 
      #remote_user_enable        1
                                 ; If WebUI is behind a web server which
                                 ; has already authentified user, enable.
                                 
      #remote_user_enable        2
                                 ; Look for remote user in the WSGI environment
                                 ; instead of the HTTP header. This allows
                                 ; for fastcgi (flup) and scgi (flupscgi)
                                 ; integration, eg. with the apache modules.
                                 
      #remote_user_variable      X_Remote_User  
                                 ; Set to the HTTP header containing
                                 ; the authentificated user s name, which
                                 ; must be a Shinken contact.

      # For external plugins to load on webui
      #additional_plugins_dir   

      # Share directory
      share_dir                  /var/lib/shinken/share/

      # Photos directory
      photos_dir                 /var/lib/shinken/share/photos/
   }



Authentification modules
========================

The WebUI uses external modules to lookup your user password and allow to authenticate or not.

By default it is using the auth-cfg-password module, which will look into your contact definition for the password parameter. 

Shinken contact - auth-cfg-password
-----------------------------------

How to install:

::

   shinken install auth-cfg-password

The simpliest is to use the users added as Shinken contacts

How to configure the module:

::

   define module {
      module_name Cfg_password
      module_type cfg_password_webui
   }

Apache htpasswd - auth-htpasswd
-------------------------------
This module uses an Apache passwd file (htpasswd) as authentification backend. All it needs is the full path of the file.

How to install:

::

   shinken install auth-htpasswd

How to configure the module:

::

   define module {
      module_name      Apache_passwd
      module_type      passwd_webui

      # WARNING: put the full PATH for this value!
      passwd           /etc/shinken/htpasswd.users
   }

Check the owner (must be Shinken user) and mode (must be readable) of this file.

If you don't have such a file you can generate one with the “htpasswd” command (in Debian's “apache2-utils” package), or from websites like htaccessTools. 

Active Directory / OpenLDAP - ad_webui
--------------------------------------
This module allows to lookup passwords into both Active Directory or OpenLDAP entries.

How to install:

::

   shinken install auth-active-directory

How to configure the module:

::

   define module {
      module_name ActiveDir_UI
      module_type ad_webui
      ldap_uri ldaps://adserver
      username user
      password password
      basedn DC=google,DC=com

      # For mode you can switch between ad (active dir)
      # and openldap
      mode	 ad
   }

Change “adserver” by your own dc server, and set the “user/password” to an account with read access on the basedn for searching the user entries.

Change “mode” from “ad” to “openldap” to make the module ready to authenticate against an OpenLDAP directory service.

You could also find module sample in shinken.specific.cfg. 

User photos
-----------
In the WebUI users can see each others photos.
At this point only the “ad_webui” module allows to import and display photos in the WebUI. There is no configuration: if you add the “ad_webui” module it will import contact photos automatically.


User preferences modules
========================

The WebUI is self sufficient to store common and user preferences: dashboard, default parameters, ...

It is whenever possible to store user preferences in a MongoDB or Sqlite database.

To enable user preferences in MongoDB do the following:

How to install:

::

   shinken install mongodb


Add "Mongodb" to the modules list in the WebUI configuration file 

To enable user preferences in Sqlite do the following:

How to install:

::

   shinken install sqlite


Add "sqlite" to the modules list in the WebUI configuration file 


Metrology graph modules
=======================

You can link the WebUI so it will present graphs from other tools, like PNP4Nagios or Graphite. All you need is to declare such modules (there are already samples in the default configuration) and add them in the WebUI modules definition.

PNP graphs
----------
You can ask for a PNP integration with a pnp_webui module. Here is its definition:

::

   # Use PNP graphs in the WebUI
   define module {
      module_name    PNP_UI
      module_type    pnp_webui
      uri            http://YOURSERVERNAME/pnp4nagios/  ; put the real PNP uri here. YOURSERVERNAME must be changed
                                                       ; to the hostname of the PNP server
   }

Shinken will automatically replace YOURSERVERNAME with the broker hostname at runtime to try and make it work for you, but you MUST change it to the appropriate value.

Graphite graphs
----------------
You can ask for Graphite graphs with the graphite_ui definition.

::

   define module {
      module_name    GRAPHITE_UI
      module_type    graphite_webui
      uri            http://YOURSERVERNAME/ ; put the real GRAPHITE uri here. YOURSERVERNAME must be changed
                                            ; to the hostname of the GRAPHITE server
   }

Shinken will automatically replace YOURSERVERNAME with the broker hostname at runtime to try and make it work for you, but you MUST change it to the appropriate value.
