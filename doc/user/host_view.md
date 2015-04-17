# Host view
====================================
When an host is selected, the host element view displays all information known about this host.

Two tabs menu are available on this page. A _vertical tabs menu_ on the left side allows to display information about the host and send commands.  An _horizontal tabs menu_ allows to display more information about the host monitoring status.

In this chapter, some more explanations about each available tab.

![Host view](./Capture10.JPG "Host view")


## Vertical tabs menu
------------------------------------

### Information 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
The host information pane contains information about : 

 - host current status : Up, Unreachable, Down
   Host is Up if it communicates with the monitoring server.
   Host is unreachable if the monitoring server does not known how to contact (host is behind a router that is down)
   Host is down if it does not communicate with the monitoring server, or its check command answers Down
   
 - host status flapping 
   Host status is flapping between two states (Up, Down, Up, Down, ...)
   
 - host downtime 
   Host is a downtime period
   
 - last host check: 
   When the last host check occured and what was the result: check output, performance data, latency and duration.
   
   When the state changed for the last time and when the next check is programmed.

   
![Host information](./host01.JPG "Host information")


### Additional information 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
The host additional information pane contains information about : 

 - host check configuration : 
   The host is *actively* or *passively* checked. If passively, the *freshness check and threshold* indicates wether and when the *check command* is executed.
   The host *check period* defines in which timeperiod the host is checked with the check *command*, and how many *retry* at which *interval*. 
   
   
 - flapping detection parameters
   See http://nagios.sourceforge.net/docs/3_0/flapping.html
   
 - notifications parameters 
   See http://nagios.sourceforge.net/docs/3_0/notifications.html
   
   If notifications are enabled, during the *notification period*, the declared *contacts* will receive the configured notifications at each each notification *interval*.
   The configured possible notifications are:
      host is switching from / to a problem state
      host is entering / exiting a downtime period
      a downtime period is programmed / cancelled
      host is starting / stopping flapping
   
   
![Host additional information](./host02.JPG "Host additional information")


### Commands
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
The host commands pane contains information about : 

 - commands that can be sent to the host : 
   add a comment:
      allows the user to add a persistent text message in the host comments
      
   try to fix
      if event handlers are enabled and an event handler is defined for the host, it may be started to try to fix the problem.
      
   add an acknowledgement
      allow the user to add an acknowledgement for the current problem
      
   recheck now
      allows to launch the check command for the host
      
   submit a check result
      allows to change the current host state and check output
      
   change a custom variable
      allows to change an host custom variable
      
   schedule a downtime
      allows to schedule a downtime period for the host

      
 - current host commands state (set per-host configuration and not modifiable): 
   active checks enabled / disabled
   passive checks enabled / disabled
   freshness check enabled / disabled
   notifications enabled / disabled
   event handlers enabled / disabled
   flapping detection enabled / disabled

![Host commands](./host03.JPG "Host commands")


### Configuration 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

![Host configuration](./host04.JPG "Host configuration")



## Horizontal tabs menu
------------------------------------

### Graphical status
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
- view graphical status of the host (note that all hosts do not have such a view)

### Host services status
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
- view host services status (Services tab) 

### Comments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
- view comments and acknowledges (Comments tab) for the host. Comments are texts sent when an host status is acknowledged with the Acknowledge command.

### Graphs
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
- view graphs (Graphs tab) for the host. Graphs are performance data sent with the host check (heartbeat)

### Impact graph
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
- view impact graph (Impact graph tab) for the host. 

### Logs
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
- view logs (Logs graph tab) for the host. Overall system logs are filtered for the current host (last 100 logs)


