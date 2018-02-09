#!/bin/sh

xyz=$1

rsync -av --cvs-exclude ./module/ ${xyz}.phicus.es:/var/lib/shinken/modules/webui2;
#ssh ${xyz}.phicus.es "service shinken-broker restart; service shinken reload"
