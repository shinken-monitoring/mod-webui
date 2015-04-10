====================================
User's guide
====================================

Shinken Web User Interface is built with a modern Javascript library (Bootstrap 3) to allow access with most Web browser.

Logging in
------------------------------------

On the application login page, log in with the provided username and password.

Once logged in the user is relocated on the home page. 

On the top of the page a navigation bar that allows to :

- hide / show the side bar menu
- search for an host
- display the "one eye monitoring view"
- show logged in user information / settings

On the left side of the page a side bar menu to switch between application pages : 
- Dashboard
- Problems
- Hosts groups
- Hosts tags
- Minemap
- World map
- Logs
- System
- Graphite

The following chapters introduce every feature.

Dashboard
------------------------------------
On top of the Dashboard page, a summary bar with main information about the system status : 
- current problems 
- main impacts on business
- monitored hosts status summarized as a percentage
- monitored services status summarized as a percentage

On the page, some widgets that main be chosen by the logged in user:

![Dashboard page](./Capture01.JPG "Dashboard")

To add a widget on the dashboard page, click on "Add a new widget" and then choose the desired widget.


Problems
------------------------------------
The problems page displays the current detected problems on the system. Problems are presented in a list of collapsible elements sorted by level of criticity.

On the left side of the page, it is possible to filter the problems list and to set bookmarks that may be global or user specifically stored.

![Problems page](./Capture02.JPG "Problems")


Hosts groups
------------------------------------
The hosts groups page is a view of the monitored hosts grouped by hosts groups. This view is switchable from box to list thanks to the upper right icons.

Each hosts group contains information about the Up, Unreachable, Down and Unknown hosts status.

Hovering a group allows to switch to the details or minemap view for the group.

![Hosts groups page](./Capture03.JPG "Hosts groups")

Groups are logical hosts grouping.


Hosts tags
------------------------------------
The hosts tags page is a view of the monitored hosts grouped by hosts tags. This view is switchable from box to list thanks to the upper right icons.

Each hosts group contains information about the Up, Unreachable, Down and Unknown hosts status.

Hovering a group allows to switch to the details view for the group.

![Hosts tags page](./Capture04.JPG "Hosts tags")

Tags are monitoring profiles hosts grouping.


Minemap
------------------------------------
The minemap page is a view of the monitored hosts and services in a matrix (you know the famous minemap game ...).


![Minemap page](./Capture05.JPG "Minemap")


Worldmap
------------------------------------
The worldmap page is a view of the monitored hosts on a Google map.

Each host is located on the world map with a marker colored depending upon host overall state. Depending upon the zoom level, hosts are grouped in a cluster which colors depend upon all included hosts overall state.

Host overall state is computed as is:

- if host state is not Up, orange/red color for unreachable/down

- if host state is Up, 

   - if at least one service is Critical, red color
   - if at least one service is Warning, orange color
   -  if all services are Ok, green color


![Worldmap page](./Capture05.JPG "Worldmap")

Note that it is possible to view an OSM map layout instead of Google's one ...


"one eye monitoring view"
------------------------------------
In the navigation bar, the eye icon enables to switch to this view that is a fullscreen display of the main information concerning the overall system status.

![Dashboard page](./Capture00.JPG "One eyed")

An icon of top left of this view allows to go back to Dashboard page.

