# Web UI users


## Login / authentication
------------------------------------

All Shinken declared contacts are allowed to login the Web UI whereas an authentication module allows their login parameters. 

Main authentication modules are : 
 - auth-cfg-password, that uses the password set in Shinken contact for authentication.
 - auth-htpasswd, that uses an htpasswd file for authentication.
 - auth-active-directory, that uses Active Directory for authentication (and retrieve photos).
 - auth-ws-glpi, that uses Glpi Web Services for user authentication

Some properties are used by the WebUI in the Shinken contact definition.

```
define contact{
   use                  generic-contact
   contact_name         admin
   alias                Administrator
   email                shinken@localhost
   pager                0600000000   ; contact phone number
   password             admin
   is_admin             1
   can_submit_commands  0
   expert               1
}
```

*password* is required if you use the auth-cfg-password module.
*is_admin* to define the user as an administrator
*can_submit_commands* indicates that the user can launch commands on the elements.


## User role / profile
------------------------------------

An administrator user is allowed to see all the elements.
A non administrator user (user) is only allowed to see the elements he is attached to.

An expert user ... to be defined ! Shinken contact owns this property ...


## User picture
------------------------------------

The user picture used in the Web UI are locally stored in a directory defined in the *webui.cfg* file (*photos_dir*, that defauls to */var/lib/shinken/share/photos/*).

The user picture used is a PNG file named with the login username (eg. *admin.png*).

If gravatar is configured in the *webui.cfg* file, the Web UI tries to find a Gravatar image to use for the logged in user.

If gravatar is not configured in the *webui.cfg* file, the Web UI tries to find an image username.png to use for the logged in user.

If none found, a default image is used:

![Default admin user picture](../../share/photos/admin.png "Default admin user picture")

![Default guest user picture](../../share/photos/guest.png "Default guest user picture")

![Default standard user picture](../../share/photos/default.png "Default standard user picture")


## Company logo
------------------------------------

A company logo is used in the Web UI. The default company logo is a Shinken logo.

![Default company logo](../../module/htdocs/images/default_company.png "Default company logo")

To use another logo, the file name must be set in the *webui.cfg* file (*company_logo*) and the file must be copied in the *photos_dir (default is */var/lib/shinken/share/photos/*).
