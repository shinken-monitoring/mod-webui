# Shinken Web User Interface, version 2

## Description
Shinken Web User Interface

Current version is 2.3.2, available on [`shinken.io`](http://shinken.io/package/webui2).

## Release notes

### Version 2.3.2
 - Features:
   - Update (huge) dashboard currently view
   - Improve problems widgets (synthesis, commands bar)
   - Problems page metrics improvements (thanks @medismail)
   - New dashboard widget to enable/disable global notifications

 - Enhancements:
   - Clean dashboard widgets management (addition, options, removal, ...)
   - Update JS/CSS/Fonts libraries (jQuery, Font Awesome)
   - Update login process and user management
   - Refactoring in the data manager
   - Allows authenticating a user with Alignak backend

 - Bugs and fixes:
    #471: downtime page error
    #469: currently 404
    #468: CSS bug
    #466: use display_name when available
    ... and some others :)

### Version 2.3.1
 Only for internal testings and not published on shinken.io
 - Features:
   - Update (huge) dashboard currently view
   - Improve problems widgets (synthesis, commands bar)
   - Problems page metrics improvements (thanks @medismail)

 - Enhancements:
   - Clean dashboard widgets management (addition, options, removal, ...)
   - Update JS/CSS/Fonts libraries (jQuery, Font Awesome)
   - Update login process and user management

## Installation

 Installing/upgrading the Shinken WebUI is an easy process:
 - install the module dependencies ([`requirements.txt`](https://github.com/shinken-monitoring/mod-webui/blob/develop/requirements.txt)).
 - install the module (`shinken install webui2`)
 - restart Shinken

 View installation/upgrade procedure in [this article](https://github.com/shinken-monitoring/mod-webui/wiki/Installation).

## Screenshots

![Host Detail](doc/animation.gif)

## Dependencies

Dependencies are listed in the [`requirements.txt`](https://github.com/shinken-monitoring/mod-webui/blob/develop/requirements.txt) file.

## Report a bug

See the [`contributing.md`](https://github.com/shinken-monitoring/mod-webui/blob/develop/contributing.md) file.

## Contributing

See the [`contributing.md`](https://github.com/shinken-monitoring/mod-webui/blob/develop/contributing.md) file.
