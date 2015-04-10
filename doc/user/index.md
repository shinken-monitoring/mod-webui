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
The hosts groups page a selection of the monitored hosts grouped by hosts groups. This view is switchable from box to list thanks to the upper right icons.

Each host group contains information about the Up, Unreachable, Down and Unknown hosts status.

Hovering a group allows to switch to the details or minemap view for the group.

![Hosts groups page](./Capture03.JPG "Hosts groups")


"one eye monitoring view"
------------------------------------
In the navigation bar, the eye icon enables to switch to this view that is a fullscreen display of the main information concerning the overall system status.

![Dashboard page](./Capture00.JPG "One eyed")

An icon of top left of this view allows to go back to Dashboard page.

