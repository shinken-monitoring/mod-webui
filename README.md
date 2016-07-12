# Shinken Web User Interface, version 2

## Description
Shinken Web User Interface

Current version is 2.4.2c, available on [`shinken.io`](http://shinken.io/package/webui2).

## Release notes

### Version 2.4.2c

 - Bugs and fixes:
   - #520: data display for simple (non admin) user
   - hosts/services synthesis count restricted count for no admin user

### Version 2.4.2

 - Features:
   - Worldmap is based upon OSM/Leaflet instead of Google maps (thanks to RoPP)

 - Bugs and fixes:
   - #492: error on services tags page
   - #496: hide Execute menu for simple users
   - #515: missing view port declaration for mobile devices
   - #517: missing menu on mobile devices
   - #514: broken notification toggle widget
   - #513: bad quotes aroud hostgroups links


### Version 2.4.1
 *This version replaces the 2.4.0 that was not released nor published on shinken.io.*

 Version 2.4.0 intended to fix a serious bug (#486) that makes the WebUI not loading the external modules ... all my apologies for this!

 - Features:
   - No new major features

 - Enhancements:
   - Element view availability graphs tab (2.4.1)
   - Groups (hosts,services,contacts) pages are responsive (2.4.1)
   - Search filter improvements
   - Sort groups in element view
   - #224: remove change custom variable button
   - #472: downtime form when only one element is selected
   - Add default downtime duration in webui2.cfg (thanks to @TomaszUrugOlszewski, PR#451)
   - Add default downtime / acknowledge external commands parameters in webui2.cfg
   - #481: graph proxy response
   - #487: actions/widgets menu relooking

 - Bugs and fixes:
   - #489: groups filtering is broken
   - #482: make problems counters consistent
   - #483: protect against missing Alignak library
   - #485: modules broken (Active directory authentication)
   - #486: external modules not loaded

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
   - #471: downtime page error
   - #469: currently 404
   - #468: CSS bug
   - #466: use display_name when available
   - ... and some others :)

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
