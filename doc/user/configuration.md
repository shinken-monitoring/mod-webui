# Configuration


## Login welcome message


A welcome text on the login page may be defined in the *webui.cfg* file, parameter *login_text*.


## Company logo


A company logo is used in the Web UI. The default company logo is a Shinken logo.

![Default company logo](../../module/htdocs/images/default_company.png "Default company logo")

To use another logo, the file name must be set in the *webui.cfg* file (*company_logo*) and the file must be copied in the *photos_dir (default is */var/lib/shinken/share/photos/*).


## User picture


If gravatar is configured in the *webui.cfg* file, the Web UI tries to find a Gravatar image to use for the logged in user. Gravatar searched image is based upon the user configured email.

If gravatar is not configured in the *webui.cfg* file, the Web UI tries to find an image in a *username.png* file located in the *photos_dir* configured in the WebUI.

If none found, a default image is used.

![Default user logo](../../module/htdocs/images/default_user.png "Default user logo")

