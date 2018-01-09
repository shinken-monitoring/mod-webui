#!/bin/sh

xyz=$1

rsync -av --cvs-exclude ./module/ ${xyz}.phicus.es:/var/lib/shinken/modules/$( basename `pwd` );
#ssh ${xyz}.phicus.es "service shinken-broker restart; service shinken reload"
