.. _webui_index:

=======================
WebUI module
=======================

 Shinken includes a self sufficient Web User Interface, which includes its own web server (No need to setup Apache or Microsoft IIS)

Shinken WebUI is started at the same time Shinken itself does, and is configured using the main Shinken configuration file by setting a few basic parameters. 

Overview 
=========
Enable the webui **module** in shinken-specific.cfg configuration file that is on the server where your Arbiter is installed.

::

	## Module:      WebUI
	## Loaded by:   Broker
	# The Shinken web interface and integrated web server.
	define module {
	    module_name     WebUI
	    module_type     webui
	    host            0.0.0.0     ; All interfaces = 0.0.0.0
	    port            7767
	    auth_secret     CHANGE_ME   ; CHANGE THIS or someone could forge
	                                ; cookies!!
	    allow_html_output   1       ; Allow or not HTML chars in plugins output.
	                                ; WARNING: Allowing can be a security issue.
	    max_output_length   100     ; Maximum output length for plugin output in webui
	    manage_acl          1       ; Use contacts ACL. 0 allow actions for all.
	    play_sound          0       ; Play sound on new non-acknowledged problems.
	    login_text          Login to the Shinken WebUI - Live System; Text in the login form.

	    refresh_period		60		; Number of seconds between each page refresh
									; Default value is 60 seconds

	    ## Modules for WebUI
	    # - Apache_passwd   = Use an htpasswd file for auth backend.
	    # - ActiveDir_UI    = Use AD for auth backend (and retrieve photos).
	    # - Cfg_password    = Use the password setted in Shinken contact for auth.
	    # - PNP_UI          = Use PNP graphs in the UI.
	    # - GRAPHITE_UI     = Use graphs from Graphite time series database.
	    # - Mongodb         = Save user preferences to a Mongodb database
	    # - SQLitedb        = Save user preferences to a SQLite database
	    modules     Apache_passwd, Cfg_password, PNP_UI, Mongodb, Glances_UI

	    ## Advanced Options
	    # Don't use them as long as you don't know what you are doing!
	    #http_backend            auto    ; Choice is: auto, wsgiref, cherrypy, flup,
	                                     ; flupscgi, paste, tornado, twisted or gevent.
	                                     ; Leave auto to find the best available.
	    #remote_user_enable      1       ; If WebUI is behind a web server which
	                                     ; has already authentified user, enable.
	    #remote_user_enable      2       ; Look for remote user in the WSGI environment
	                                     ; instead of the HTTP header. This allows
	                                     ; for fastcgi (flup) and scgi (flupscgi)
	                                     ; integration, eg. with the apache modules.
	    #remote_user_variable    X_Remote_User  ; Set to the HTTP header containing
	                                     ; the authentificated user s name, which
	                                     ; must be a Shinken contact.
	    # If you got external plugins (pages) to load on webui
	    #additional_plugins_dir   
	    #embeded_graph          1       ; If we don't want to publish graphing tools
	                                    ; and embed graph in html code
	}

Authentification modules
========================

The WebUI use modules to lookup your user password and allow to authenticate or not.

By default it is using the cfg_password_webui module, which will look into your contact definition for the password parameter. 

Shinken contact - cfg_password_webui
====================================

The simpliest is to use the users added as Shinken contacts
::

	define module {
		module_name Cfg_password
	    module_type cfg_password_webui
	}

Apache htpasswd - passwd_webui
==============================
This module uses an Apache passwd file (htpasswd) as authentification backend. All it needs is the full path of the file (from a legacy Nagios CGI installation, for example). 
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
======================================
This module allows to lookup passwords into both Active Directory or OpenLDAP entries. 
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
	    mode	ad
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

The WebUI use mongodb to store all user preferences, dashboards and other information.

To enable user preferences do the following:

    install mongodb using the Shinken installation script: cd /usr/local/shinken ; ./install -a mongodb
    add “Mongodb” to your WebUI module list as done in the example at the top of this page

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
	  uri            http://YOURSERVERNAME/pnp4nagios/       ; put the real PNP uri here. YOURSERVERNAME must be changed
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

