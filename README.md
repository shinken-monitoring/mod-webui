<a href='https://travis-ci.org/shinken-monitoring/mod-webui'><img src='https://api.travis-ci.org/shinken-monitoring/mod-webui.svg?branch=master' alt='Travis Build'></a>
#mod-webui

###Description
Shinken main Web interface

###Installation

* *$ shinken install webui*
* Add it into the modules of the broker configuration :
```
shinken@debian# cat /etc/shinken/brokers/broker-master.cfg
[...]
modules     webui
[...]
```
* Install an authentication module for instance 
```
shinken install auth-cfg-password
```

* Declare it on the WebUI configuration :
```
shinken@debian# grep modules /etc/shinken/modules/webui.cfg
modules             auth-cfg-password
```
* Restart shinken and connect to the WebUI that will be available on the 7767 port.
```
root@debian# /etc/init.d/shinken restart
```

###Screenshots

Host Detail
![Host Detail](doc/animated.31005.gif)

System
![System](doc/ShinkenWebUISystem.png)

###Dependencies


###Report a bug
* A helpful title - use descriptive keywords in the title and body so others can find your bug (avoiding duplicates).
* WebUI Version and branch
* Steps to reproduce the problem, with actual vs. expected results
* OS version
* Browser and Version
* If the problem happens with specific code, link to test files (gist.github.com is a great place to upload code).
* Screenshots are very helpful if you're seeing an error message or a UI display problem. (Just drag an image into the issue description field to include it).

###Contributing
1. Fork it.
2. Create a branch (`git checkout -b my_branch`)
3. Commit your changes (`git commit -am "Major fixup."`)
4. Push to the develop branch (`git push develop my_branch`)
5. Open a [Pull Request](https://github.com/shinken-monitoring/mod-webui/pulls)
6. Enjoy a refreshing Diet Coke and wait :+1:
