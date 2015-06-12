Shinken WebUI BS3 - roadmap
===========================

Currently, this project is in a transition phase between master and BS3 branch. This BS3 branch is a really good candidate to become the new master branch of the Shinken WebUI but some milestones are still to be achieved before this step.

We made real improvements on this branch and we are still testing if it is stable enough to become the new master ... discussions are ongoing about it.

This file describes the main milestones currently defined for the BS3 branch of the WebUI. When these features will be implemented and tested, a new WebUI V2 module will be published on Shinken.IO to be easily installed.


## Layout:
- clean UI layout
- design rules for hosts/services state
- boostrap themable layout + how-to

## All / Problems view:
- simple and compact user interface
- Github like filtering system

   - filter on host/service name
   - filter on host/service state
   - filter acknowledged
   - filter scheduled downtimes
   - filter on business priority

- bookmark filters
- launch commands

## Host / service view:
- clean element view
- launch commands

## Common / User preferences
- improve preferences storage backend (Mongodb)
- configuration parameters in storage backend instead of cfg files
- 
   
## Tactical overview:

### Minemap:
- filterable
- new design rules

### Hosts/services groups:
- filterable
- new design rules

### Hosts/services tags:
- filterable
- new design rules

### Worldmap:
- filterable
- new design rules

