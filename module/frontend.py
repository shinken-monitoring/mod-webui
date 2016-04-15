#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright (c) 2015:
#   Frederic Mohier, frederic.mohier@gmail.com
#
# This file is part of (WebUI).
#
# (WebUI) is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# (WebUI) is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with (WebUI).  If not, see <http://www.gnu.org/licenses/>.

"""
    Interface to the Alignak backend
"""

import os
import time
import traceback
import logging

import json


# Import all objects we will need
from shinken.objects.host import Host, Hosts
from shinken.objects.hostgroup import Hostgroup, Hostgroups
from shinken.objects.service import Service, Services
from shinken.objects.servicegroup import Servicegroup, Servicegroups
from shinken.objects.contact import Contact, Contacts
from shinken.objects.contactgroup import Contactgroup, Contactgroups
from shinken.objects.notificationway import NotificationWay, NotificationWays
from shinken.objects.timeperiod import Timeperiod, Timeperiods
from shinken.objects.command import Command, Commands
from shinken.objects.config import Config
from shinken.objects.schedulerlink import SchedulerLink, SchedulerLinks
from shinken.objects.reactionnerlink import ReactionnerLink, ReactionnerLinks
from shinken.objects.pollerlink import PollerLink, PollerLinks
from shinken.objects.brokerlink import BrokerLink, BrokerLinks
from shinken.objects.receiverlink import ReceiverLink, ReceiverLinks

# Import specific modules
import requests

# import alignak_backend_client.client
from alignak_backend_client.client import Backend, BackendException

from shinken.log import logger


class FrontEnd(object):
    """
    Frontend class used to communicate with Alignak backend
    """
    def __init__(self):
        """
        Initialize class object ...
        """
        self.url_endpoint_root = None
        self.backend = None

        self.initialized = False
        self.loaded = False
        self.logged_in = None

        # Backend objects which will be loaded on backend connection ...
        # ... do not need to wait for any user request to get these objects
        # Dictionnary of object type / request parameters
        self.interested_in = {
            'command' : { 'parameters': None, 'length': 0, 'timestamp': 0 },
            'contact' : { 'parameters': None, 'length': 0, 'timestamp': 0 },
            'contactgroup' : { 'parameters': None, 'length': 0, 'timestamp': 0 },
            'host' : { 'parameters': None, 'length': 0, 'timestamp': 0 },
            'hostdependency' : { 'parameters': None, 'length': 0, 'timestamp': 0 },
            'hostgroup' : { 'parameters': None, 'length': 0, 'timestamp': 0 },
            'realm' : { 'parameters': None, 'length': 0, 'timestamp': 0 },
            'service' : { 'parameters': None, 'length': 0, 'timestamp': 0 },
            'servicegroup' : { 'parameters': None, 'length': 0, 'timestamp': 0 },
            'timeperiod' : { 'parameters': None, 'length': 0, 'timestamp': 0 },
        }

        # Backend available objects (filled with objects received from backend)
        self.backend_available_objets = []

        # Frontend objects
        self.objects_cache = {}

        # Shinken objects
        self.hosts = Hosts([])
        self.services = Services([])
        self.notificationways = NotificationWays([])
        self.contacts = Contacts([])
        self.hostgroups = Hostgroups([])
        self.servicegroups = Servicegroups([])
        self.contactgroups = Contactgroups([])
        self.timeperiods = Timeperiods([])
        self.commands = Commands([])
        # From now we only look for realms names
        self.realms = set()
        self.hosts_tags = {}
        self.services_tags = {}

        # And in progress one
        tmp_hosts = {}
        tmp_services = {}
        tmp_contacts = {}
        tmp_hostgroups = {}
        tmp_servicegroups = {}
        tmp_contactgroups = {}

        # API Data model
        self.dm_server_name = None
        self.dm_api_name = None
        self.dm_base = None
        self.dm_domains = {}
        logger.info("Alignak - backend __init: %s", self.interested_in)

    def configure(self, endpoint):
        """
        Define backend URL endpoint and create backend client object to use for communication.
        """
        assert endpoint, "Backend endpoint can not be None!"

        # Backend API start point
        if endpoint.endswith('/'):
            self.url_endpoint_root = endpoint[0:-1]
        else:
            self.url_endpoint_root = endpoint

        logger.info("Alignak - Configured backend endpoint: %s", self.url_endpoint_root)
        self.backend = Backend(self.url_endpoint_root)

    def connect(self, token):
        """
        Connect to backend using provided token

        :param token: authentication token
        :type token: string
        :return: True  if connected, else False
        :rtype: dict
        """
        assert token, "Connection requires not empty token!"

        self.logged_in = None
        save = self.backend.token
        try:
            logger.info("Alignak - request backend connection, token: %s", token)
            self.backend.token = token
            if self.backend.get_domains():
                contacts = self.get_objects(
                    'contact', parameters={"where": '{"token": "%s"}' % self.backend.token}
                )
                for contact in contacts["_items"]:
                    if contact["token"] == token:
                        self.logged_in = contact
                        logger.info("Alignak - backend user authenticated: %s", contact["name"])

                # Initialize embedded objects
                if self.initialize():
                    logger.info("Alignak - frontend initialized: %s", self.initialized)

                    # create Shinken objects and link them together...
                    self.all_done_linking()

                    logger.info("Alignak - objects loaded")

                return self.is_logged_in(token=token)
            logger.info("Alignak - backend connection failed")
            return False
        except BackendException as e:
            logger.error("Alignak - backend login, error: %s", str(e))
            logger.debug("Alignak - exception type: %s", type(e))
            logger.debug("Alignak - Back trace of this kill: %s", traceback.format_exc())
            self.backend.token = save
            raise e

        logger.warning("Alignak - backend connection impossible")
        return False

    def login(self, username, password):
        """
        Log in to backend using provided credentials

        :param username: user to authenticate
        :type username: string
        :param password: password
        :type password: string
        :return: True  if authenticated, else False
        :rtype: dict
        """
        assert username and password, "Login requires not empty username and password!"

        self.logged_in = None
        try:
            logger.info("Alignak - request backend user authentication, username: %s", username)
            if self.backend.login(username=username, password=password):
                logger.info("Alignak - backend login, token: %s", self.backend.token)
                # Initialize embedded objects
                if self.initialize():
                    logger.info("Alignak - frontend initialized: %s", self.initialized)

                    contacts = self.get_objects(
                        'contact', parameters={"where": '{"token": "%s"}' % self.backend.token}
                    )
                    for contact in contacts['_items']:
                        if contact['name'] == username:
                            if not 'contact_name' in contact:
                                contact['contact_name'] = username
                            self.logged_in = contact
                            logger.info("Alignak - backend user authenticated: %s", username)

                    # create Shinken objects and link them together...
                    self.all_done_linking()

                    return self.is_logged_in(username)

            logger.warning("Alignak - backend connection failed")
            return False
        except BackendException as e:
            logger.error("Alignak - backend login, error: %s", str(e))
            logger.debug("Alignak - exception type: %s", type(e))
            logger.debug("Alignak - Back trace of this kill: %s", traceback.format_exc())
            raise e

        logger.warning("Alignak - backend connection impossible")
        return False

    def is_logged_in(self, username=None, token=None):
        """
        Test if usern is correctly logged in

        :param username: user to check for logged in
        :type username: string
        :param token: password
        :type token: string
        :return: user is logged in or not
        :rtype: boolean
        """

        if not self.logged_in:
            return False

        if username:
            logger.debug("Alignak - is_logged_in %s with name: %s", self.logged_in["name"] == username, username)
            return self.logged_in["name"] == username

        if token:
            logger.debug("Alignak - is_logged_in %s with token: %s", self.logged_in["token"] == token, token)
            return self.logged_in["token"] == token

        return True

    def get_logged_user(self, name_only=False):
        if self.is_logged_in():
            if name_only:
                return self.get_logged_user_username()
            else:
                return self.logged_in

        return None

    def get_logged_user_token(self):
        if self.is_logged_in():
            return self.logged_in["token"]

        return None

    def get_logged_user_username(self):
        if self.is_logged_in():
            return self.logged_in["name"]

        return None

    def logout(self):
        """
        Logout user from backend

        :return: True
        :rtype: boolean
        """
        logger.info("Alignak - request backend logout")
        self.logged_in = None
        self.initialized = False

        for object_type in self.backend_available_objets:
            t = object_type["href"]
            if t in self.interested_in:
                logger.info("Alignak - cleaning '%s' cached objects...", object_type["title"])
                self.interested_in[t]['length'] = 0
                self.interested_in[t]['timestamp'] = 0

        if self.backend.token or self.backend.authenticated:
            self.backend.logout()
        return True

    def initialize(self):
        """
        Initialize:

        - list of backend domains (endpoints)
        - data model
        - self cached backend objects

        :return: true / false
        :rtype: boolean
        """
        self.initialized = False

        try:
            # Get backend served domains
            self.backend_available_objets = self.backend.get_domains()

            # Retrieve data model from the backend
            response = requests.get('/'.join([self.url_endpoint_root, 'docs/spec.json']))
            resp = response.json()
            self.dm_server_name = resp['server_name']
            self.dm_api_name = resp['api_name']
            self.dm_base = resp['base']
            self.dm_domains = {}
            for domain_name in resp['domains']:
                fields = resp['domains'][domain_name]["/" + domain_name]['POST']['params']
                self.dm_domains.update({
                    domain_name: fields
                })

            # Fetch objects type which I am interested in to store in cache ...
            for object_type in self.backend_available_objets:
                t = object_type["href"]
                if t in self.interested_in:
                    logger.info(
                        "Alignak - getting '%s' cached objects on %s/%s",
                        object_type["title"], self.url_endpoint_root, t
                    )

                    # Get all objects of type t ...
                    items = self.get_objects(t, self.interested_in[t]['parameters'], all_elements=True, force=True)
                    self.objects_cache[t] = items
                    self.interested_in[t]['length'] = len(items)
                    self.interested_in[t]['timestamp'] = time.time()

                    logger.info("Alignak - got %d %s(s)", self.interested_in[t]['length'], t)

            self.initialized = True
        except Exception as e:  # pragma: no cover
            logger.error("Alignak - FrontEnd, initialize, exception: %s", str(e))
            logger.error("Alignak - Back trace: %s", traceback.format_exc())

        return self.initialized

    def get_objects(self, object_type, parameters=None, all_elements=False, force=False):
        """
        Get stored objects

        !!! NOTE !!!
        Beware of the all_elements=True parameter because the backend client method fetches all
        the elements and the get_objects is not able anymore to send the _meta information !

        :param object_type: object type (eg. host, contact, ...)
        :type object_type: str
        :param parameters: list of parameters for the backend API
        :type parameters: list
        :param all_elements: get all elements (True) or apply default pagination
        :type all_elements: bool
        :return: list of properties when query item | list of items when get many items
        :rtype: list
        """
        try:
            items = []

            logger.debug("Alignak - get_objects, type: %s, parameters: %s / %d", object_type, parameters, all_elements)

            # If requested objects are stored locally ...
            if not force and object_type in self.objects_cache:
                if not parameters:
                    logger.info("Alignak - get_objects '%s', returns all locally stored objects", object_type)
                    return {'_items': self.objects_cache[object_type]}

                if 'where' in parameters and len(parameters.keys()) == 1:
                    where = json.loads(parameters['where'])
                    logger.debug("Alignak - get_objects '%s', apply where in stored objects: %s", object_type, where)
                    items = []
                    for object in self.objects_cache[object_type]:
                        logger.debug("Alignak - get_objects '%s', object: %s", object_type, object['_id'])
                        insert = False
                        for key,value in where.iteritems():
                            logger.debug("Alignak - get_objects '%s', key: %s = %s", object_type, key, value)
                            if object[key] == value:
                                insert = True
                            else:
                                insert = False
                        if insert:
                            items.append(object)

                    if items:
                        for item in items:
                            logger.debug("Alignak - get_objects '%s', found local item: %s", object_type, item['_id'])
                    return {'_items': items}

            # Request objects from the backend ...
            if all_elements:
                items = self.backend.get_all(object_type, parameters)
            else:
                items = self.backend.get(object_type, parameters)
            # logger.info("get_objects, items: %s", items)

            # Should be handled in the try / except ... but exception is not always raised!
            if '_error' in items:  # pragma: no cover - need specific backend tests
                error = items['_error']
                logger.error(
                    "backend get: %s, %s",
                    error['code'], error['message']
                )
                items = []

        except Exception as e:  # pragma: no cover - need specific backend tests
            logger.error("Alignak - get_objects, exception: %s", str(e))
            logger.error("Alignak - Back trace: %s", traceback.format_exc())

        return items

    def add_object(self, object_type, data=None):
        """
        Add an object

        :param object_type: object type (eg. host, contact, ...)
        :type object_type: str
        :param data: dictionary with all data for the object
        :type data: dict
        :return: list of properties when query item | list of items when get many items
        :rtype: list
        """
        try:
            logger.info("add_object, type: %s, data: %s", object_type, data)

            return self.backend.post(object_type, data=data)
        except Exception as e:  # pragma: no cover - need specific backend tests
            logger.error("add_object, exception: %s", str(e))
            if "_issues" in e.response:
                for issue in e.response["_issues"]:
                    logger.error(" - issue: %s: %s", issue, e.response['_issues'][issue])
            return e.response

    def delete_object(self, object_type, name):
        """
        Delete an object

        :param object_type: object type (eg. host, contact, ...)
        :type object_type: str
        :param name: name of the object to be deleted
        :type name: string
        :return: list of properties when query item | list of items when get many items
        :rtype: list
        """
        try:
            logger.info("delete_object, type: %s, name = '%s'", object_type, name)

            parameters = {'where': '{"%s_name":"%s"}' % (object_type, name)}
            logger.info("delete_object, parameters: %s", parameters)
            items = self.backend.get_all(object_type, params=parameters)
            logger.info("delete_object, parameters: %s", items)
            if not items:
                response = {
                    "_issues": {
                        "Not found": "Required object not found when searching: name = '%s'" % name
                    }
                }
                return response

            item = items[0]
            logger.info("delete_object, etag: %s, id = '%s'", item['_etag'], item['_id'])
            headers = {'If-Match': item['_etag']}
            return self.backend.delete('/'.join([object_type, item['_id']]), headers)
        except BackendException as e:  # pragma: no cover - should never happen ...
            logger.error("delete_object, exception %d: %s", e.code, str(e))
            if e.code == 400:
                response = {
                    "_issues": {
                        "Not found": "Required object not found when deleting: name = '%s'" % name
                    }
                }
                return response
            if "_issues" in e.response:
                for issue in e.response["_issues"]:
                    logger.error(" - issue: %s: %s", issue, e.response['_issues'][issue])
            return e.response

        except Exception as e:  # pragma: no cover - need specific backend tests
            logger.error("delete_object, exception: %s / %s", type(e), str(e))
            response = {"_issues": {"Exception": str(e)}}
            return response

    def delete_user_preferences(self, user, prefs_type):
        """
        Delete user's preferences

        If the data are not found, returns None else return the backend response.

        An exception is raised if an error occurs, else returns the backend response

        :param user: username
        :type user: string
        :param prefs_type: preference type
        :type prefs_type: string
        :return: server's response
        :rtype: dict
        """
        try:
            logger.debug(
                "delete_user_preferences, type: %s, for: %s",
                prefs_type, user
            )

            # Still existing ...
            items = self.backend.get_all(
                'uipref',
                params={'where': '{"type":"%s", "user": "%s"}' % (prefs_type, user)}
            )
            if items:
                items = items[0]
                logger.debug(
                    "delete_user_preferences, delete an exising record: %s / %s (%s)",
                    prefs_type, user, items['_id']
                )
                # Delete existing record ...
                headers = {'If-Match': items['_etag']}
                self.backend.delete('/'.join(['uipref', items['_id']]), headers)

            return True
        except Exception as e:  # pragma: no cover - need specific backend tests
            logger.error("delete_user_preferences, exception: %s", str(e))
            raise e

        return False

    def set_user_preferences(self, user, prefs_type, parameters):
        """
        Set user's preferences

        An exception is raised if an error occurs, else returns the backend response

        :param user: username
        :type user: string
        :param prefs_type: preference type
        :type prefs_type: string
        :param parameters: list of parameters for the backend API
        :type parameters: list
        :return: server's response
        :rtype: dict
        """
        try:
            response = None

            logger.debug(
                "set_user_preferences, type: %s, for: %s, parameters: %s",
                prefs_type, user, parameters
            )

            # Still existing ...
            items = self.backend.get_all(
                'uipref',
                params={'where': '{"type":"%s", "user": "%s"}' % (prefs_type, user)}
            )
            if items:
                items = items[0]
                logger.debug(
                    "set_user_preferences, update existing record: %s / %s (%s)",
                    prefs_type, user, items['_id']
                )
                # Update existing record ...
                headers = {'If-Match': items['_etag']}
                data = {
                    "user": user,
                    "type": prefs_type,
                    "data": parameters
                }
                response = self.backend.patch(
                    '/'.join(['uipref', items['_id']]),
                    data=data, headers=headers, inception=True
                )
            else:
                # Create new record ...
                logger.debug(
                    "set_user_preferences, create new record: %s / %s",
                    prefs_type, user
                )
                data = {
                    "user": user,
                    "type": prefs_type,
                    "data": parameters
                }
                response = self.backend.post('uipref', data=data)
            logger.debug("set_user_preferences, response: %s", response)

        except Exception as e:  # pragma: no cover - need specific backend tests
            logger.error("set_user_preferences, exception: %s", str(e))
            if "_issues" in e.response:
                for issue in e.response["_issues"]:
                    logger.error(" - issue: %s: %s", issue, e.response['_issues'][issue])
            return e.response

        return response

    def get_user_preferences(self, user, prefs_type):
        """
        Get user's preferences

        If the data are not found, returns None else return found data.

        :param user: username
        :type user: string
        :param prefs_type: preference type
        :type prefs_type: string
        :return: found data, or None
        :rtype: dict
        """
        try:
            logger.debug("get_user_preferences, type: %s, for: %s", prefs_type, user)

            # Still existing ...
            items = self.backend.get_all(
                'uipref',
                params={'where': '{"type":"%s", "user": "%s"}' % (prefs_type, user)}
            )
            if items:
                logger.debug("get_user_preferences, found: %s", items[0])
                return items[0]

        except Exception as e:  # pragma: no cover - should never happen
            logger.error("get_user_preferences, exception: %s", str(e))
            raise e

        return None

    def get_ui_data_model(self, element_type):
        """ Get the data model for an element type

            If the data model specifies that the element is managed in the UI,
            all the fields for this element are provided

            Returns a dictionary containing:

            - element_type: element type
            - uid: unique identifier for the element type. Contains the field that is to be used as
                a unique identifier field
            - list_title: title format string to be used for an elements list page
            - page_title: title format string to be used for an element page
            - fields: list of dictionaries. One dictionary per each field mentioned as visible in
                the ui in its schema. The dictionary contains all the fields defined in the 'ui'
                property of the schema of the element.

            :param element_type: element type
            :type element_type: str
            :return: list of fields name/title
            :rtype: list
            :return: dictionary
            :rtype: list
        """
        logger.debug("get_ui_data_model, element type: %s", element_type)

        ui_dm = {}
        if element_type in self.dm_domains:
            ui_dm.update({"element_type": element_type, "fields": []})

            for field in self.dm_domains[element_type]:
                # If element is considered for the UI
                if "ui" not in field:
                    continue

                if field["name"] == "ui":
                    if "uid" not in field["ui"]:  # pragma: no cover - should never happen
                        logger.error(
                            "get_ui_data_model, UI schema is not well formed: missing uid property"
                        )
                        continue
                    ui_dm.update({"uid": field["ui"]["uid"]})
                    ui_dm.update({"visible": field["ui"].get("visible", False)})
                    ui_dm.update({"orderable": field["ui"].get("orderable", False)})
                    ui_dm.update({"searchable": field["ui"].get("searchable", False)})
                    ui_dm.update({"list_title": field["ui"].get(
                        "list_title", "%ss list (%%d items)" % element_type
                    )})
                    ui_dm.update({"page_title": field["ui"].get(
                        "page_title", "%s: %%s" % element_type
                    )})
                    continue

                if "visible" not in field['ui']:
                    continue
                if not field["ui"]["visible"]:
                    continue

                field["ui"]["type"] = field.get("type", "string")
                field["ui"]["default"] = field.get("default", "-/-")
                field["ui"]["required"] = field.get("required", False)
                field["ui"]["unique"] = field.get("unique", False)
                field["ui"]["regex"] = field.get("regex", '')

                if "title" not in field["ui"]:
                    field["ui"]["title"] = field["name"]
                ui_dm["fields"].append((field["name"], field["ui"]))

        return ui_dm

    def get_hosts(self, parameters=None, all_elements=True, update=False):
        """ Get hosts definition

            :param parameters: backend request parameters
            :type parameters: dict
            :param all_elements: get all elements (True) or apply default pagination
            :type all_elements: bool
            :return: list of hosts
            :rtype: list
        """

        logger.info("Alignak - get_hosts, parameters: %s", parameters)
        resp = self.get_objects('host', parameters, all_elements=all_elements, force=update)
        if not all_elements:
            total = 0
            if '_meta' in resp:
                total = int(resp['_meta']['total'])
                page_number = int(resp['_meta']['page'])

            if '_items' in resp:
                hosts = resp['_items']
        else:
            hosts = resp

        if update:
            new_hosts = []
            for host in hosts:
                logger.info("Alignak - get_hosts, update host: %s", host['name'])
                h = self.hosts.find_by_name(host['name'])
                if h:
                    if not 'host_name' in host:
                        host['host_name'] = host['name']

                    # Update found element
                    # self.update_element(h, host)
                    for property in host:
                        if property in [
                            'check_command', 'event_handler', 'snapshot_command',
                            'check_period', 'notification_period', 'maintenance_period',
                            'contacts', 'contact_groups',
                            'realm']:
                            continue
                        setattr(h, property, host[property])

                    new_hosts.append(h)
            hosts = new_hosts

        logger.info("Alignak - get_hosts, %d hosts", len(hosts))
        return hosts

    def get_services(self, parameters=None, all_elements=True, update=False):
        """ Get services definition

            :param parameters: backend request parameters
            :type parameters: dict
            :param all_elements: get all elements (True) or apply default pagination
            :type all_elements: bool
            :return: list of services
            :rtype: list
        """
        logger.info("Alignak - get_services, parameters: %s", parameters)
        resp = self.get_objects('service', parameters, all_elements=all_elements, force=update)
        if not all_elements:
            total = 0
            if '_meta' in resp:
                total = int(resp['_meta']['total'])
                page_number = int(resp['_meta']['page'])

            if '_items' in resp:
                services = resp['_items']
        else:
            services = resp

        return services

    def get_livestate(self, parameters=None, all_elements=True):
        """ Get livestate for hosts and services

            :param parameters: backend request parameters
            :type parameters: dic
            :param all_elements: get all elements (True) or apply default pagination
            :type all_elements: bool
            :return: list of hosts/services live states
            :rtype: list
        """
        return self.get_objects('livestate', parameters, all_elements=all_elements)

    def get_livestate_hosts(self, parameters=None, all_elements=True):
        """ Get livestate for hosts

            Elements in the livestat which service_description is null (eg. hosts)

            :param parameters: backend request parameters
            :type parameters: dic
            :param all_elements: get all elements (True) or apply default pagination
            :type all_elements: bool
            :return: list of hosts live states
            :rtype: list
        """
        if not parameters:
            parameters = {}
        parameters.update({'where': '{"type": "host"}'})

        return self.get_objects('livestate', parameters, all_elements=all_elements)

    def get_livestate_services(self, parameters=None, all_elements=True):
        """ Get livestate for services

            Elements in the livestat which service_description is not null (eg. services)

            :param parameters: backend request parameters
            :type parameters: dic
            :param all_elements: get all elements (True) or apply default pagination
            :type all_elements: bool
            :return: list of services live states
            :rtype: list
        """
        if not parameters:
            parameters = {}
        parameters.update({'where': '{"type": "service"}'})
        return self.get_objects('livestate', parameters, all_elements=all_elements)

    def get_livesynthesis(self, parameters=None, all_elements=True):
        """ Get livestate synthesis for hosts and services

            Example backend response::

                {
                    "hosts_total": 12,
                    "hosts_business_impact": 0,
                    "hosts_acknowledged": 0,
                    "hosts_in_downtime": 0,
                    "hosts_flapping": 0,
                    "hosts_up_hard": 0,
                    "hosts_up_soft": 0,
                    "hosts_unreachable_hard": 0,
                    "hosts_unreachable_soft": 0,
                    "hosts_down_hard": 0,
                    "hosts_down_soft": 0,

                    "services_total": 245,
                    "services_business_impact": 0,
                    "services_acknowledged": 0,
                    "services_in_downtime": 0,
                    "services_flapping": 0,
                    "services_ok_hard": 0,
                    "services_ok_soft": 0,
                    "services_warning_hard": 0,
                    "services_warning_soft": 0,
                    "services_critical_hard": 0,
                    "services_critical_soft": 0,
                    "services_unknown_soft": 0,
                    "services_unknown_hard": 0,
                    "_created": "Thu, 01 Jan 1970 00:00:00 GMT",
                    "_updated": "Sat, 10 Oct 2015 09:08:59 GMT",
                    "_id": "5618d5abf9e3852e3444a5ee",
                    "_etag": "edce4629fff2412ab7257216bb66c54795baada4"
                    "_links": {
                        "self": {
                            "href": "livesynthesis/5618d5abf9e3852e3444a5ee",
                            "title": "Livesynthesi"
                        }
                    },
                }

            Returns an hosts_synthesis dictionary containing:
            - number of elements
            - business impact
            - count for each state (hard and soft)
            - percentage for each state (hard and soft)
            - number of problems (down and unreachable, only hard state)
            - percentage of problems

            Returns a services_synthesis dictionary containing:
            - number of elements
            - business impact
            - count for each state (hard and soft)
            - percentage for each state (hard and soft)
            - number of problems (down and unreachable, only hard state)
            - percentage of problems

            :return: hosts and services live state synthesis in a dictionary
            :rtype: dict
        """
        ls = self.get_objects('livesynthesis', parameters, all_elements=all_elements)
        if not ls:
            return None

        ls = ls[0]

        # Services synthesis
        hosts_synthesis = {
            'nb_elts': ls["hosts_total"],
            'business_impact': ls["hosts_business_impact"],
        }
        for state in 'up', 'down', 'unreachable':
            hosts_synthesis.update({
                "nb_" + state: ls["hosts_%s_hard" % state] + ls["hosts_%s_soft" % state]
            })
        for state in 'acknowledged', 'in_downtime', 'flapping':
            hosts_synthesis.update({
                "nb_" + state: ls["hosts_%s" % state]
            })
        hosts_synthesis.update({
            "nb_problems": ls["hosts_down_hard"] + ls["hosts_unreachable_hard"]
        })
        for state in 'up', 'down', 'unreachable':
            hosts_synthesis.update({
                "pct_" + state: round(
                    100.0 * hosts_synthesis['nb_' + state] / hosts_synthesis['nb_elts'], 2
                ) if hosts_synthesis['nb_elts'] else 0.0
            })
        for state in 'acknowledged', 'in_downtime', 'flapping', 'problems':
            hosts_synthesis.update({
                "pct_" + state: round(
                    100.0 * hosts_synthesis['nb_' + state] / hosts_synthesis['nb_elts'], 2
                ) if hosts_synthesis['nb_elts'] else 0.0
            })

        # Services synthesis
        services_synthesis = {
            'nb_elts': ls["services_total"],
            'business_impact': ls["services_business_impact"],
        }
        for state in 'ok', 'warning', 'critical', 'unknown':
            services_synthesis.update({
                "nb_" + state: ls["services_%s_hard" % state] + ls["services_%s_soft" % state]
            })
        for state in 'acknowledged', 'in_downtime', 'flapping':
            services_synthesis.update({
                "nb_" + state: ls["services_%s" % state]
            })
        services_synthesis.update({
            "nb_problems": ls["services_warning_hard"] + ls["services_critical_hard"]
        })
        for state in 'ok', 'warning', 'critical', 'unknown':
            services_synthesis.update({
                "pct_" + state: round(
                    100.0 * services_synthesis['nb_' + state] / services_synthesis['nb_elts'], 2
                ) if services_synthesis['nb_elts'] else 0.0
            })
        for state in 'acknowledged', 'in_downtime', 'flapping', 'problems':
            services_synthesis.update({
                "pct_" + state: round(
                    100.0 * services_synthesis['nb_' + state] / services_synthesis['nb_elts'], 2
                ) if services_synthesis['nb_elts'] else 0.0
            })

        synthesis = {
            'hosts_synthesis': hosts_synthesis,
            'services_synthesis': services_synthesis
        }
        return synthesis



    # Now we get all data about an instance, link all this stuff :)
    def all_done_linking(self):

        start = time.time()
        logger.warning("In linking phase for frontend")

        self.loaded = False

        # Parse backend objects
        # - remove Eve backend attributes (_id, _etag, ...) that are considered as custom variables

        # Hosts
        logger.info("Alignak - parsing hosts...")
        for idx,item in enumerate(self.objects_cache['host']):
            try:
                logger.debug("Alignak - host: %s", item)
                if 'register' in item and not item['register']:
                    logger.info("Alignak - host template: %s", item['name'])
                    continue

                if not 'host_name' in item:
                    self.objects_cache['host'][idx]['host_name'] = item['name']
                    item['host_name'] = item['name']

                logger.info("Alignak - host: %s", self.objects_cache['host'][idx]['host_name'])
                self.objects_cache['host'][idx]['imported_from'] = 'Alignak'

                # global realms list
                if 'realm' in item:
                    parameters = {
                        'where': json.dumps({'_id': item['realm']})
                    }
                    resp = self.get_objects('realm', parameters=parameters)
                    if '_items' in resp:
                        for group in resp['_items']:
                            self.realms.add(group['name'])

                # hostgroups which host is member of
                if 'hostgroups' in item and item['hostgroups']:
                    logger.info("Alignak - host: %s / %s", item['name'], item['hostgroups'])
                    new_members = []
                    for member in item['hostgroups']:
                        parameters = {
                            'where': json.dumps({'_id': member})
                        }
                        resp = self.get_objects('hostgroup', parameters=parameters)
                        if '_items' in resp:
                            for group in resp['_items']:
                                new_members.append(group['name'])
                    item['hostgroups'] = new_members
                    self.objects_cache['host'][idx]['hostgroups'] = new_members
                    logger.info("Alignak - host: %s / %s", item['name'], item['hostgroups'])
                else:
                    self.objects_cache['host'][idx].update({'hostgroups': ''})

                # contactgroups which host is member of
                if 'contact_groups' in item:
                    new_members = []
                    for member in item['contact_groups']:
                        parameters = {
                            'where': json.dumps({'_id': member})
                        }
                        resp = self.get_objects('contactgroup', parameters=parameters)
                        if '_items' in resp:
                            for group in resp['_items']:
                                new_members.append(group['name'])
                    if new_members:
                        self.objects_cache['host'][idx]['contact_groups'] = ','.join(new_members)
                else:
                    self.objects_cache['host'][idx].update({'contact_groups': ''})

                # contacts which host is attached to
                if 'contacts' in item:
                    new_members = []
                    for member in item['contacts']:
                        parameters = {
                            'where': json.dumps({'_id': member})
                        }
                        resp = self.get_objects('contact', parameters=parameters)
                        if '_items' in resp:
                            for group in resp['_items']:
                                new_members.append(group['name'])
                    if new_members:
                        self.objects_cache['host'][idx]['contacts'] = ','.join(new_members)
                else:
                    self.objects_cache['host'][idx].update({'contacts': ''})

                # host check command
                if 'check_command' in item and item['check_command']:
                    parameters = {
                        'where': json.dumps({'_id': item['check_command']})
                    }
                    resp = self.get_objects('command', parameters=parameters)
                    if '_items' in resp:
                        for element in resp['_items']:
                            self.objects_cache['host'][idx].update({'check_command': element['name']})
                else:
                    self.objects_cache['host'][idx].update({'check_command': ''})

                # host event handler
                if 'event_handler' in item and item['event_handler']:
                    parameters = {
                        'where': json.dumps({'_id': item['event_handler']})
                    }
                    resp = self.get_objects('command', parameters=parameters)
                    if '_items' in resp:
                        for group in resp['_items']:
                            self.objects_cache['host'][idx].update({'event_handler': group['name']})
                else:
                    self.objects_cache['host'][idx].update({'event_handler': ''})

                # host snapshot command
                if 'snapshot_command' in item and item['snapshot_command']:
                    parameters = {
                        'where': json.dumps({'_id': item['snapshot_command']})
                    }
                    resp = self.get_objects('command', parameters=parameters)
                    if '_items' in resp:
                        for element in resp['_items']:
                            self.objects_cache['host'][idx].update({'snapshot_command': element['name']})
                else:
                    self.objects_cache['host'][idx].update({'snapshot_command': ''})

                # check period
                if 'check_period' in item and item['check_period']:
                    parameters = {
                        'where': json.dumps({'_id': item['check_period']})
                    }
                    resp = self.get_objects('timeperiod', parameters=parameters)
                    if '_items' in resp:
                        for group in resp['_items']:
                            self.objects_cache['host'][idx].update({'check_period': group['name']})
                else:
                    # Default is always
                    self.objects_cache['host'][idx].update({'check_period': '24x7'})

                # notification period
                if 'notification_period' in item and item['notification_period']:
                    parameters = {
                        'where': json.dumps({'_id': item['notification_period']})
                    }
                    resp = self.get_objects('timeperiod', parameters=parameters)
                    if '_items' in resp:
                        for group in resp['_items']:
                            self.objects_cache['host'][idx].update({'notification_period': group['name']})
                else:
                    # Default is always
                    self.objects_cache['host'][idx].update({'notification_period': '24x7'})

                # maintenance period
                if 'maintenance_period' in item and item['maintenance_period']:
                    parameters = {
                        'where': json.dumps({'_id': item['maintenance_period']})
                    }
                    resp = self.get_objects('timeperiod', parameters=parameters)
                    if '_items' in resp:
                        for group in resp['_items']:
                            self.objects_cache['host'][idx].update({'maintenance_period': group['name']})
                else:
                    # Default is never
                    self.objects_cache['host'][idx].update({'maintenance_period': 'none'})

                # snapshot period
                if 'snapshot_period' in item and item['snapshot_period']:
                    parameters = {
                        'where': json.dumps({'_id': item['snapshot_period']})
                    }
                    resp = self.get_objects('timeperiod', parameters=parameters)
                    if '_items' in resp:
                        for group in resp['_items']:
                            self.objects_cache['host'][idx].update({'snapshot_period': group['name']})
                else:
                    # Default is never
                    self.objects_cache['host'][idx].update({'snapshot_period': 'none'})

            except Exception as e:
                logger.error("Alignak - all_done_linking, exception: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
                continue
        logger.info("Alignak - parsed %d hosts", len(self.objects_cache['host']))
        logger.info("Alignak - found %d realms", len(self.realms))
        for idx,item in enumerate(self.objects_cache['host']):
            logger.info("Alignak - host: %s / %s", item['host_name'], item['hostgroups'])

        # Hosts groups ...
        logger.info("Alignak - parsing host groups...")
        for idx,item in enumerate(self.objects_cache['hostgroup']):
            try:
                logger.debug("Alignak - hostgroup: %s", item)
                if 'register' in item and not item['register']:
                    logger.info("Alignak - hostgroup template: %s", item['name'])
                    continue

                if not 'hostgroup_name' in item:
                    self.objects_cache['hostgroup'][idx]['hostgroup_name'] = item['name']
                    item['hostgroup_name'] = item['name']

                logger.info("Alignak - hostgroup: %s", item['name'])
                self.objects_cache['hostgroup'][idx]['imported_from'] = 'Alignak'

                # hosts members of the group
                if 'members' in item and item['members']:
                    new_members = []
                    for member in item['members']:
                        parameters = {
                            'where': json.dumps({'_id': member})
                        }
                        resp = self.get_objects('host', parameters=parameters)
                        if '_items' in resp:
                            for group in resp['_items']:
                                new_members.append(group['name'])
                    item['members'] = new_members
                    self.objects_cache['hostgroup'][idx].update({'members': new_members})
                else:
                    self.objects_cache['hostgroup'][idx].update({'members': ''})
                logger.debug("Alignak - hostgroup: %s, members: %s",
                    self.objects_cache['hostgroup'][idx]['hostgroup_name'],
                    self.objects_cache['hostgroup'][idx]['members']
                )

                # groups members of the group
                if 'hostgroup_members' in item and item['hostgroup_members']:
                    new_members = []
                    for member in item['hostgroup_members']:
                        parameters = {
                            'where': json.dumps({'_id': member})
                        }
                        resp = self.get_objects('hostgroup', parameters=parameters)
                        if '_items' in resp:
                            for group in resp['_items']:
                                new_members.append(group['name'])
                    if new_members:
                        item['hostgroup_members'] = ','.join(new_members)
                        self.objects_cache['hostgroup'][idx].update({'hostgroup_members': ','.join(new_members)})
                else:
                    self.objects_cache['hostgroup'][idx].update({'hostgroup_members': ''})
                logger.debug("Alignak - hostgroup: %s, groups members: %s",
                    self.objects_cache['hostgroup'][idx]['hostgroup_name'],
                    self.objects_cache['hostgroup'][idx]['hostgroup_members']
                )

            except Exception as e:
                logger.error("Alignak - all_done_linking, exception: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
                continue
        logger.info("Alignak - parsed %d hostgroups", len(self.objects_cache['hostgroup']))

        # Services
        logger.info("Alignak - parsing services...")
        for idx,item in enumerate(self.objects_cache['service']):
            try:
                logger.debug("Alignak - service: %s", item)
                if 'register' in item and not item['register']:
                    logger.info("Alignak - service template: %s", item['name'])
                    continue

                if not 'service_description' in item:
                    self.objects_cache['service'][idx]['service_description'] = item['name']
                    item['service_description'] = item['name']

                # host relation
                if 'host_name' in item:
                    parameters = {
                        'where': json.dumps({'_id': item['host_name']})
                    }
                    resp = self.get_objects('host', parameters=parameters)
                    if '_items' in resp:
                        for element in resp['_items']:
                            item['host_name'] = element['name']
                            self.objects_cache['service'][idx].update({'host_name': element['name']})

                logger.debug(
                    "Alignak - service: %s / %s",
                    self.objects_cache['service'][idx]['host_name'],
                    self.objects_cache['service'][idx]['service_description']
                )
                self.objects_cache['service'][idx]['imported_from'] = 'Alignak'

                # servicegroups which service is member of
                if 'servicegroups' in item and item['servicegroups']:
                    new_members = []
                    for member in item['servicegroups']:
                        parameters = {
                            'where': json.dumps({'_id': member})
                        }
                        resp = self.get_objects('servicegroup', parameters=parameters)
                        if '_items' in resp:
                            for group in resp['_items']:
                                new_members.append(group['name'])
                    self.objects_cache['service'][idx].update({'servicegroups': new_members})
                    logger.info("Alignak - service: %s, servicegroups: %s", item['name'], item['servicegroups'])
                else:
                    self.objects_cache['service'][idx].update({'servicegroups': ''})

                # contactgroups which service is member of
                if 'contact_groups' in item:
                    new_members = []
                    for member in item['contact_groups']:
                        parameters = {
                            'where': json.dumps({'_id': member})
                        }
                        resp = self.get_objects('contactgroup', parameters=parameters)
                        if '_items' in resp:
                            for group in resp['_items']:
                                new_members.append(group['name'])
                    self.objects_cache['service'][idx].update({'contact_groups': ','.join(new_members)})
                else:
                    self.objects_cache['service'][idx].update({'contact_groups': ''})
                    item.update({'contact_groups': ''})

                # contacts which service is attached to
                if 'contacts' in item:
                    new_members = []
                    for member in item['contacts']:
                        parameters = {
                            'where': json.dumps({'_id': member})
                        }
                        resp = self.get_objects('contact', parameters=parameters)
                        if '_items' in resp:
                            for group in resp['_items']:
                                new_members.append(group['name'])
                    self.objects_cache['service'][idx].update({'contacts': ','.join(new_members)})
                else:
                    self.objects_cache['service'][idx].update({'contacts': ''})

                # check command
                if 'check_command' in item and item['check_command']:
                    parameters = {
                        'where': json.dumps({'_id': item['check_command']})
                    }
                    resp = self.get_objects('command', parameters=parameters)
                    if '_items' in resp:
                        for element in resp['_items']:
                            self.objects_cache['service'][idx].update({'check_command': element['name']})
                else:
                    self.objects_cache['service'][idx].update({'check_command': ''})

                # event handler
                if 'event_handler' in item and item['event_handler']:
                    parameters = {
                        'where': json.dumps({'_id': item['event_handler']})
                    }
                    resp = self.get_objects('command', parameters=parameters)
                    if '_items' in resp:
                        for group in resp['_items']:
                            self.objects_cache['service'][idx].update({'event_handler': group['name']})
                else:
                    self.objects_cache['service'][idx].update({'event_handler': ''})

                # snapshot command
                if 'snapshot_command' in item and item['snapshot_command']:
                    parameters = {
                        'where': json.dumps({'_id': item['snapshot_command']})
                    }
                    resp = self.get_objects('command', parameters=parameters)
                    if '_items' in resp:
                        for element in resp['_items']:
                            self.objects_cache['service'][idx].update({'snapshot_command': element['name']})
                else:
                    self.objects_cache['service'][idx].update({'snapshot_command': ''})

                # check period
                if 'check_period' in item and item['check_period']:
                    parameters = {
                        'where': json.dumps({'_id': item['check_period']})
                    }
                    resp = self.get_objects('timeperiod', parameters=parameters)
                    if '_items' in resp:
                        for group in resp['_items']:
                            self.objects_cache['service'][idx].update({'check_period': group['name']})
                else:
                    # Default is always
                    self.objects_cache['service'][idx].update({'check_period': '24x7'})

                # notification period
                if 'notification_period' in item and item['notification_period']:
                    parameters = {
                        'where': json.dumps({'_id': item['notification_period']})
                    }
                    resp = self.get_objects('timeperiod', parameters=parameters)
                    if '_items' in resp:
                        for group in resp['_items']:
                            self.objects_cache['service'][idx].update({'notification_period': group['name']})
                else:
                    # Default is always
                    self.objects_cache['service'][idx].update({'notification_period': '24x7'})

                # maintenance period
                if 'maintenance_period' in item and item['maintenance_period']:
                    parameters = {
                        'where': json.dumps({'_id': item['maintenance_period']})
                    }
                    resp = self.get_objects('timeperiod', parameters=parameters)
                    if '_items' in resp:
                        for group in resp['_items']:
                            self.objects_cache['service'][idx].update({'maintenance_period': group['name']})
                else:
                    # Default is never
                    self.objects_cache['service'][idx].update({'maintenance_period': 'none'})

                # snapshot period
                if 'snapshot_period' in item and item['snapshot_period']:
                    parameters = {
                        'where': json.dumps({'_id': item['snapshot_period']})
                    }
                    resp = self.get_objects('timeperiod', parameters=parameters)
                    if '_items' in resp:
                        for group in resp['_items']:
                            self.objects_cache['service'][idx].update({'snapshot_period': group['name']})
                else:
                    # Default is never
                    self.objects_cache['service'][idx].update({'snapshot_period': 'none'})
                logger.debug("Alignak - service: %s", item)

            except Exception as e:
                logger.error("Alignak - all_done_linking, exception: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
                continue
        logger.info("Alignak - parsed %d services", len(self.objects_cache['service']))

        # Services groups ...
        logger.info("Alignak - parsing servicegroups...")
        for idx,item in enumerate(self.objects_cache['servicegroup']):
            try:
                logger.debug("Alignak - servicegroup: %s", item)
                if 'register' in item and not item['register']:
                    logger.info("Alignak - servicegroup template: %s", item['name'])
                    continue

                if not 'servicegroup_name' in item:
                    self.objects_cache['servicegroup'][idx]['servicegroup_name'] = item['name']
                    item['servicegroup_name'] = item['name']

                logger.debug("Alignak - servicegroup: %s", item['name'])
                self.objects_cache['servicegroup'][idx]['imported_from'] = 'Alignak'

                # services members of the group
                if 'members' in item and item['members']:
                    new_members = []
                    for member in item['members']:
                        parameters = {
                            'where': json.dumps({'_id': member})
                        }
                        resp = self.get_objects('service', parameters=parameters)
                        if '_items' in resp:
                            for group in resp['_items']:
                                parameters = {
                                    'where': json.dumps({'_id': member})
                                }
                                host = self.get_objects('host', parameters=parameters)
                                if '_items' in host:
                                    for group_h in host['_items']:
                                        new_members.append("%s,%s" % (group_h['name'], group['service_description']))
                    self.objects_cache['servicegroup'][idx].update({'members': new_members})
                    logger.info("Alignak - servicegroup: %s, members: %s", item['servicegroup_name'], item['members'])
                else:
                    self.objects_cache['servicegroup'][idx].update({'members': ''})
                logger.info("Alignak - hostgroup: %s, members: %s",
                    self.objects_cache['servicegroup'][idx]['servicegroup_name'],
                    self.objects_cache['servicegroup'][idx]['members']
                )

                # groups members of the group
                if 'servicegroup_members' in item and item['servicegroup_members']:
                    new_members = []
                    for member in item['servicegroup_members']:
                        parameters = {
                            'where': json.dumps({'_id': member})
                        }
                        resp = self.get_objects('servicegroup', parameters=parameters)
                        if '_items' in resp:
                            for group in resp['_items']:
                                new_members.append(group['name'])
                    if new_members:
                        item['servicegroup_members'] = ','.join(new_members)
                        self.objects_cache['servicegroup'][idx].update({'servicegroup_members': ','.join(new_members)})
                else:
                    self.objects_cache['servicegroup'][idx].update({'servicegroup_members': ''})
                logger.debug("Alignak - servicegroup: %s", item)

            except Exception as e:
                logger.error("Alignak - all_done_linking, exception: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
                continue
        logger.info("Alignak - parsed %d servicegroups", len(self.objects_cache['servicegroup']))

        # Contacts
        logger.info("Alignak - parsing contacts...")
        for idx,item in enumerate(self.objects_cache['contact']):
            try:
                logger.debug("Alignak - contact: %s", item)
                if 'register' in item and not item['register']:
                    logger.info("Alignak - contact template: %s", item['name'])
                    continue

                if not 'contact_name' in item:
                    self.objects_cache['contact'][idx]['contact_name'] = item['name']
                    item['contact_name'] = item['name']

                logger.info("Alignak - contact: %s", item['name'])
                self.objects_cache['contact'][idx]['imported_from'] = 'Alignak'

                # contactgroups which contact is member of
                if 'contactgroups' in item:
                    new_members = []
                    for member in item['contactgroups']:
                        parameters = {
                            'where': json.dumps({'_id': member})
                        }
                        resp = self.get_objects('contactgroup', parameters=parameters)
                        if '_items' in resp:
                            for group in resp['_items']:
                                new_members.append(group['name'])
                    self.objects_cache['contact'][idx].update({'contactgroups': new_members})
                else:
                    item.update({'contactgroups': ''})
                    self.objects_cache['contact'][idx].update({'contactgroups': ''})

                # contact notification period
                if 'notification_period' in item:
                    parameters = {
                        'where': json.dumps({'_id': item['notification_period']})
                    }
                    resp = self.get_objects('timeperiod', parameters=parameters)
                    if '_items' in resp:
                        for group in resp['_items']:
                            self.objects_cache['contact'][idx].update({'notification_period': group['name']})
                else:
                    self.objects_cache['contact'][idx].update({'notification_period': ''})
                logger.debug("Alignak - contact: %s", item)

            except Exception as e:
                logger.error("Alignak - all_done_linking, exception: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
                continue
        logger.info("Alignak - parsed %d contacts", len(self.objects_cache['contact']))
        # Contacts now have a contact_name property ...
        # logger.info("Alignak - contacts: %s", self.objects_cache['contact'])

        # Contacts groups ...
        logger.info("Alignak - parsing contactgroups...")
        for idx,item in enumerate(self.objects_cache['contactgroup']):
            try:
                logger.debug("Alignak - contactgroup: %s", item)
                if 'register' in item and not item['register']:
                    logger.info("Alignak - contactgroup template: %s", item['name'])
                    continue

                if not 'contactgroup_name' in item:
                    self.objects_cache['contactgroup'][idx]['contactgroup_name'] = item['name']
                    item['contactgroup_name'] = item['name']

                logger.info("Alignak - contactgroup: %s", self.objects_cache['contactgroup'][idx]['contactgroup_name'])
                self.objects_cache['contactgroup'][idx]['imported_from'] = 'Alignak'

                # contacts members of the group
                if 'members' in item:
                    new_members = []
                    for member in item['members']:
                        parameters = {
                            'where': json.dumps({'_id': member})
                        }
                        resp = self.get_objects('contact', parameters=parameters)
                        if '_items' in resp:
                            for group in resp['_items']:
                                new_members.append(group['name'])
                    self.objects_cache['contactgroup'][idx].update({'members': new_members})
                else:
                    self.objects_cache['contactgroup'][idx].update({'members': ''})
                logger.info("Alignak - contactgroup: %s, members: %s",
                    self.objects_cache['contactgroup'][idx]['contactgroup_name'],
                    self.objects_cache['contactgroup'][idx]['members']
                )

                # groups members of the group
                if 'contactgroup_members' in item:
                    new_members = []
                    for member in item['contactgroup_members']:
                        parameters = {
                            'where': json.dumps({'_id': member})
                        }
                        resp = self.get_objects('contactgroup', parameters=parameters)
                        if '_items' in resp:
                            for group in resp['_items']:
                                new_members.append(group['name'])
                    self.objects_cache['contactgroup'][idx].update({'contactgroup_members': new_members})
                else:
                    self.objects_cache['contactgroup'][idx].update({'contactgroup_members': ''})
                logger.debug("Alignak - contactgroup: %s", item)

            except Exception as e:
                logger.error("Alignak - all_done_linking, exception: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
                continue
        logger.info("Alignak - parsed %d contactgroups", len(self.objects_cache['contactgroup']))

        # Timeperiods
        logger.info("Alignak - parsing timeperiods...")
        for idx,item in enumerate(self.objects_cache['timeperiod']):
            try:
                logger.debug("Alignak - timeperiod: %s", item)
                if not 'timeperiod_name' in item:
                    self.objects_cache['timeperiod'][idx]['timeperiod_name'] = item['name']
                    item['timeperiod_name'] = item['name']

                if 'definition_order' in item:
                    item['definition_order'] = "%s" % item['definition_order']
                    self.objects_cache['timeperiod'][idx]['definition_order'] = item['definition_order']

                logger.info("Alignak - timeperiod: %s", self.objects_cache['timeperiod'][idx]['timeperiod_name'])
                self.objects_cache['timeperiod'][idx]['imported_from'] = 'Alignak'

                dateranges = []
                for dr in item['dateranges']:
                    logger.info("Alignak - timeperiod, daterange: %s", dr)
                    for day in dr:
                        self.objects_cache['timeperiod'][idx][day] = dr[day]
                self.objects_cache['timeperiod'][idx]['dateranges'] = ''
            except Exception as e:
                logger.error("Alignak - all_done_linking, exception: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
                continue
        logger.info("Alignak - parsed %d timeperiods", len(self.objects_cache['timeperiod']))

        # Commands
        logger.info("Alignak - parsing commands...")
        for idx,item in enumerate(self.objects_cache['command']):
            try:
                logger.debug("Alignak - command: %s", item)
                if not 'command_name' in item:
                    self.objects_cache['command'][idx]['command_name'] = item['name']
                    item['command_name'] = item['name']

                logger.debug("Alignak - command: %s", self.objects_cache['command'][idx]['command_name'])
                self.objects_cache['command'][idx]['imported_from'] = 'Alignak'

            except Exception as e:
                logger.error("Alignak - all_done_linking, exception: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
                continue
        logger.info("Alignak - parsed %d commands", len(self.objects_cache['command']))

        # Setting Alignak backend properies
        # ------------------------------------------------------------------------------------------
        try:
            logger.debug("Alignak - changing backend properties ...")
            # Make Alignak backend specific attributes be considered as customs ...
            for type in self.objects_cache:
                logger.info("Alignak - changing backend properties for %s...", type)
                for idx,item in enumerate(self.objects_cache[type]):
                    self.objects_cache[type][idx]['_backend_id'] = self.objects_cache[type][idx]['_id']
                    self.objects_cache[type][idx]['_backend_etag'] = self.objects_cache[type][idx]['_etag']
                    self.objects_cache[type][idx]['_backend_links'] = self.objects_cache[type][idx]['_links']
                    self.objects_cache[type][idx]['_backend_created'] = self.objects_cache[type][idx]['_created']
                    self.objects_cache[type][idx]['_backend_updated'] = self.objects_cache[type][idx]['_updated']
                    if '_realm' in self.objects_cache[type][idx]:
                        self.objects_cache[type][idx]['_backend_realm'] = self.objects_cache[type][idx]['_realm']
                    if '_sub_realm' in self.objects_cache[type][idx]:
                        self.objects_cache[type][idx]['_backend_sub_realm'] = self.objects_cache[type][idx]['_sub_realm']
                    if '_users_read' in self.objects_cache[type][idx]:
                        self.objects_cache[type][idx]['_backend_users_read'] = self.objects_cache[type][idx]['_users_read']
                    if '_users_update' in self.objects_cache[type][idx]:
                        self.objects_cache[type][idx]['_backend_users_update'] = self.objects_cache[type][idx]['_users_update']
                    if '_users_delete' in self.objects_cache[type][idx]:
                        self.objects_cache[type][idx]['_backend_users_delete'] = self.objects_cache[type][idx]['_users_delete']
                    if 'ui' in self.objects_cache[type][idx]:
                        self.objects_cache[type][idx]['_backend_ui'] = self.objects_cache[type][idx]['ui']
                logger.info("Alignak - changed backend properties for %d %s(s)", len(self.objects_cache[type]), type)

            # Clean Alignak backend specific attributes ...
            for type in self.objects_cache:
                logger.info("Alignak - cleaning backend properties for %s...", type)
                for item in self.objects_cache[type]:
                    # Keep _id field for searching in objects ...
                    # item.pop('_id', None)
                    item.pop('_etag', None)
                    item.pop('_links', None)
                    item.pop('_created', None)
                    item.pop('_updated', None)

                    if '_realm' in item:
                        item.pop('_realm', None)
                    if '_sub_realm' in item:
                        item.pop('_sub_realm', None)
                    if '_users_read' in item:
                        item.pop('_users_read', None)
                    if '_users_update' in item:
                        item.pop('_users_update', None)
                    if '_users_delete' in item:
                        item.pop('_users_delete', None)
                    if 'ui' in item:
                        item.pop('ui', None)
                logger.info("Alignak - removed backend properties for %d %s(s)", len(self.objects_cache[type]), type)
        except Exception as e:
            logger.error("Alignak - all_done_linking, exception: %s", str(e))
            logger.error("Alignak - Back trace: %s", traceback.format_exc())

        # Create Shinken objects
        # ------------------------------------------------------------------------------------------
        try:
            # Shinken objects
            logger.info("Alignak - cleaning objects...")
            self.hosts = Hosts([])
            self.services = Services([])
            self.notificationways = NotificationWays([])
            self.contacts = Contacts([])
            self.hostgroups = Hostgroups([])
            self.servicegroups = Servicegroups([])
            self.contactgroups = Contactgroups([])
            self.timeperiods = Timeperiods([])
            self.commands = Commands([])
            self.realms = set()
            self.hosts_tags = {}
            self.services_tags = {}

            # And temporary one
            tmp_hosts = Hosts([])
            tmp_services = Services([])
            tmp_contacts = Contacts([])
            tmp_hostgroups = Hostgroups([])
            tmp_servicegroups = Servicegroups([])
            tmp_contactgroups = Contactgroups([])

            logger.debug("Alignak - creating hosts ...")
            for i in self.objects_cache['host']:
                tmp_hosts.add_item(Host(i))
            logger.debug("Alignak - created %d temporary hosts", len(tmp_hosts))

            logger.debug("Alignak - creating hostgroups ...")
            for i in self.objects_cache['hostgroup']:
                tmp_hostgroups.add_item(Hostgroup(i))
            logger.debug("Alignak - created %d temporary hostgroups", len(tmp_hostgroups))

            logger.debug("Alignak - creating services ...")
            for i in self.objects_cache['service']:
                tmp_services.add_item(Service(i))
            logger.debug("Alignak - created %d temporary services", len(tmp_services))

            logger.debug("Alignak - creating servicegroups ...")
            for i in self.objects_cache['servicegroup']:
                tmp_servicegroups.add_item(Servicegroup(i))
            logger.debug("Alignak - created %d temporary servicegroups", len(tmp_servicegroups))

            logger.debug("Alignak - creating contacts ...")
            for i in self.objects_cache['contact']:
                tmp_contacts.add_item(Contact(i))
            logger.debug("Alignak - created %d temporary contacts", len(tmp_contacts))

            logger.debug("Alignak - creating contactgroups  ...")
            for i in self.objects_cache['contactgroup']:
                tmp_contactgroups.add_item(Contactgroup(i))
            logger.debug("Alignak - created %d temporary contactgroups", len(tmp_contactgroups))

            logger.debug("Alignak - creating timeperiods ...")
            for i in self.objects_cache['timeperiod']:
                self.timeperiods.add_item(Timeperiod(i))
            logger.debug("Alignak - created %d timeperiods", len(self.timeperiods))

            logger.debug("Alignak - creating commands ...")
            for i in self.objects_cache['command']:
                self.commands.add_item(Command(i))
            logger.debug("Alignak - created %d commands", len(self.commands))
        except Exception as e:
            logger.error("Alignak - all_done_linking, exception: %s", str(e))
            logger.error("Alignak - Back trace: %s", traceback.format_exc())


        # Create Shinken objects relations
        # ------------------------------------------------------------------------------------------
        # Link hostgroups objects to their hostgroups objects
        logger.info("Alignak - linking hostgroups to hostgroups...")
        for hg in tmp_hostgroups:
            try:
                logger.debug("Alignak - hostgroup '%s' groups members: %s", hg.hostgroup_name, hg.hostgroup_members)
                new_members = []
                for hgname in hg.get_hostgroup_members():
                    logger.debug("Alignak - hostgroup '%s' member: %s", hg.hostgroup_name, hgname)
                    hgc = tmp_hostgroups.find_by_name(hgname)
                    if hgc:
                        new_members.append(hgname)
                hg.hostgroup_members = ','.join(new_members)

                self.hostgroups.add_item(hg)
                logger.debug("Alignak - hostgroup '%s' members (new): %s, groups members: %s", hg.hostgroup_name, hg.members, hg.hostgroup_members)
            except Exception as e:
                logger.error("Alignak - all_done_linking, exception when linking hostgroups to hosts: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
                continue
        logger.info("Alignak - linked %d hostgroups", len(self.hostgroups))

        logger.info("Alignak - linking servicegroups to servicegroups...")
        for sg in tmp_servicegroups:
            try:
                logger.debug("Alignak - servicegroup '%s' groups members: %s", sg.servicegroup_name, sg.servicegroup_members)
                new_members = []
                for sgname in sg.get_servicegroup_members():
                    logger.debug("Alignak - servicegroup '%s' member: %s", sg.servicegroup_name, sgname)
                    sgc = tmp_servicegroups.find_by_name(sgname)
                    if sgc:
                        new_members.append(sgname)
                sg.servicegroup_members = ','.join(new_members)

                self.servicegroups.add_item(sg)
                logger.debug("Alignak - servicegroup '%s' members (new): %s, groups members: %s", sg.servicegroup_name, sg.members, sg.servicegroup_members)
            except Exception as e:
                logger.error("Alignak - all_done_linking, exception when linking servicegroups to services: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
                continue
        logger.info("Alignak - linked %d servicegroups", len(self.servicegroups))

        logger.info("Alignak - linking contactgroups to contactgroups...")
        for cg in tmp_contactgroups:
            try:
                logger.info("Alignak - contactgroup '%s' groups members: %s", cg.contactgroup_name, cg.contactgroup_members)
                new_members = []
                for cgname in cg.contactgroup_members:
                    logger.debug("Alignak - contactgroup '%s' member: %s", cgc.contactgroup_name, cgname)
                    cgc = self.contactgroups.find_by_name(cgname)
                    if cgc:
                        new_members.append(cgc)
                    else:
                        self.contactgroups.add_item(cgc)
                        cgc = self.contactgroups.find_by_name(cgname)
                        if cgc:
                            # Should be a link to other groups ...
                            # new_members.append(cgc)
                            # ... but it is only a link to name of groups !
                            new_members.append(cgname)
                cg.contactgroup_members = ','.join(new_members)

                self.contactgroups.add_item(cg)
                logger.debug("Alignak - contactgroup '%s' members (new): %s", cg.contactgroup_name, cg.members)
            except Exception as e:
                logger.error("Alignak - all_done_linking, exception when linking contactgroups to contacts: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
                continue
        logger.info("Alignak - linked %d contactgroups", len(self.contactgroups))

        # Link hosts objects to their hostgroups objects
        logger.debug("Alignak - linking hosts to hostgroups, commands, timeperiods,...")
        for h in tmp_hosts:
            try:
                logger.debug("Alignak - host '%s'", h.host_name)
                logger.debug("Alignak - linking hostgroups...")
                if h.hostgroups:
                    new_objects = []
                    logger.info("Alignak - host '%s', hostgroups: %s", h.host_name, h.hostgroups)
                    for name in h.hostgroups:
                        element = self.hostgroups.find_by_name(name)
                        if element:
                            new_objects.append(element)
                    h.hostgroups = new_objects

                # Link timeperiods
                logger.debug("Alignak - linking timeperiods...")
                t = self.timeperiods.find_by_name(h.check_period)
                if t:
                    h.check_period = t
                t = self.timeperiods.find_by_name(h.notification_period)
                if t:
                    h.notification_period = t
                t = self.timeperiods.find_by_name(h.maintenance_period)
                if t:
                    h.maintenance_period = t
                t = self.timeperiods.find_by_name(h.snapshot_period)
                if t:
                    h.snapshot_period = t

                # And link contacts too
                logger.debug("Alignak - linking contacts...")
                if h.contacts:
                    new_objects = []
                    logger.debug("Alignak - contacts: %s", h.contacts)
                    for name in h.contacts:
                        element = self.contacts.find_by_name(name)
                        if element:
                            new_objects.append(element)
                    h.contacts = new_objects
                logger.debug("Alignak - linking contacts groups...")
                if h.contact_groups:
                    new_objects = []
                    logger.debug("Alignak - contact groups: %s", h.contact_groups)
                    for name in h.contact_groups:
                        element = self.contactgroups.find_by_name(name)
                        if element:
                            new_objects.append(element)
                    h.contact_groups = new_objects

                # Linkify tags
                logger.debug("Alignak - linking tags...")
                for t in h.tags:
                    if t not in self.hosts_tags:
                        self.hosts_tags[t] = 0
                    self.hosts_tags[t] += 1

                # We can really declare this host OK now
                logger.info("Alignak - linked host: %s", h)
                self.hosts.add_item(h)
            except Exception as e:
                logger.error("Alignak - all_done_linking, exception when linking hosts to hostgroups: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
                continue
        logger.info("Alignak - linked %d hosts", len(self.hosts))

        # Link hostgroups objects to their hosts objects
        logger.info("Alignak - linking hostgroups to hosts...")
        for hg in self.hostgroups:
            try:
                logger.info("Alignak - hostgroup '%s' members: %s", hg.hostgroup_name, hg.members)
                new_members = []
                for hname in hg.members:
                    logger.info("Alignak - hostgroup '%s' member: %s (%s)", hg.hostgroup_name, hname, tmp_hosts.find_by_name(hname))
                    h = self.hosts.find_by_name(hname)
                    if h:
                        new_members.append(h)
                        # Link back with hosts
                        if hg not in h.hostgroups:
                            h.hostgroups.append(hg)
                hg.members = new_members
                logger.debug("Alignak - hostgroup '%s' members (new): %s", hg.hostgroup_name, hg.members)
            except Exception as e:
                logger.error("Alignak - all_done_linking, exception when linking hostgroups to hosts: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
                continue

        # Link services objects to their servicegroups objects
        logger.debug("Alignak - linking services to servicegroups, commands, timeperiods,...")
        for s in tmp_services:
            try:
                logger.debug("Alignak - service '%s/%s'", s.host_name, s.service_description)
                logger.debug("Alignak - linking servicegroups...")
                if s.servicegroups:
                    new_objects = []
                    logger.debug("Alignak - service '%s', servicegroups: %s", s.service_description, s.servicegroups)
                    for name in s.servicegroups:
                        element = self.servicegroups.find_by_name(name)
                        if element:
                            new_objects.append(element)
                    s.servicegroups = new_objects


                # Now link with host
                logger.debug("Alignak - linking host...")
                hname = s.host_name
                logger.debug("Alignak - linking host: %s", hname)
                s.host = self.hosts.find_by_name(hname)
                if s.host:
                    s.host.services.append(s)
                logger.debug("Alignak - linked to host: %s", s.host.host_name)

                # Now link timeperiods
                logger.debug("Alignak - linking timeperiods...")
                t = self.timeperiods.find_by_name(s.check_period)
                if t:
                    s.check_period = t
                t = self.timeperiods.find_by_name(s.notification_period)
                if t:
                    s.notification_period = t
                t = self.timeperiods.find_by_name(s.maintenance_period)
                if t:
                    s.maintenance_period = t
                t = self.timeperiods.find_by_name(s.snapshot_period)
                if t:
                    s.snapshot_period = t

                # And link contacts too
                logger.debug("Alignak - linking contacts...")
                # self.linkify_contacts(h, 'contacts')
                if s.contacts:
                    new_objects = []
                    logger.debug("Alignak - contacts: %s", s.contacts)
                    for name in s.contacts:
                        element = self.contacts.find_by_name(name)
                        if element:
                            new_objects.append(element)
                    s.contacts = new_objects
                if s.contact_groups:
                    new_objects = []
                    logger.debug("Alignak - contact groups: %s", s.contact_groups)
                    for name in s.contact_groups:
                        element = self.contactgroups.find_by_name(name)
                        if element:
                            new_objects.append(element)
                    s.contact_groups = new_objects
                # self.linkify_contacts(s, 'contacts')

                # Linkify services tags
                for t in s.tags:
                    if t not in self.services_tags:
                        self.services_tags[t] = 0
                    self.services_tags[t] += 1

                # We can really declare this host OK now
                self.services.add_item(s, index=True)
            except Exception as e:
                logger.error("Alignak - all_done_linking, exception when linking services and servicesgroups: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
        logger.info("Alignak - linked %d services", len(self.services))

        # Link servicegroups objects to their services objects
        logger.info("Alignak - linking servicegroups to services...")
        for sg in self.servicegroups:
            try:
                logger.info("Alignak - servicegroup '%s' members: %s", sg.servicegroup_name, sg.members)
                new_members = []
                for hname in sg.members:
                    logger.debug("Alignak - servicegroup '%s' member: %s (%s)", sg.servicegroup_name, hname, tmp_services.find_by_name(hname))
                    h = self.services.find_by_name(hname)
                    if h:
                        new_members.append(h)
                        # Link back with services
                        if sg not in s.servicegroups:
                            h.servicegroups.append(sg)
                sg.members = new_members
                logger.debug("Alignak - servicegroup '%s' members (new): %s", sg.servicegroup_name, sg.members)
            except Exception as e:
                logger.error("Alignak - all_done_linking, exception when linking servicegroups to services: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
                continue

        # Now we can link all impacts/source problem list
        # but only for the new ones here of course
        logger.debug("Alignak - linking hosts with impacts, problems,...")
        for h in self.hosts:
            try:
                logger.debug("Alignak - linking host: %s", h)
                logger.debug("Alignak - linking host impacts: %s", h.impacts)
                self.linkify_dict_srv_and_hosts(h, 'impacts')
                self.linkify_dict_srv_and_hosts(h, 'source_problems')
                logger.debug("Alignak - linking host parents: %s", h.parent_dependencies)
                self.linkify_host_and_hosts(h, 'parents')
                logger.debug("Alignak - linking host children: %s", h.child_dependencies)
                self.linkify_host_and_hosts(h, 'childs')
                self.linkify_dict_srv_and_hosts(h, 'parent_dependencies')
                self.linkify_dict_srv_and_hosts(h, 'child_dependencies')
                logger.debug("Alignak - linking host commands")
                h.linkify_one_command_with_commands(self.commands, 'check_command')
                h.linkify_one_command_with_commands(self.commands, 'event_handler')
                h.linkify_one_command_with_commands(self.commands, 'snapshot_command')
            except Exception as e:
                logger.error("Alignak - all_done_linking, exception when linking hosts: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
        logger.info("Alignak - linked hosts")

        # Now services too
        logger.debug("Alignak - linking services with impacts, problems,...")
        for s in self.services:
            try:
                logger.debug("Alignak - linking service: %s", s)
                logger.debug("Alignak - linking service impacts: %s", s.impacts)
                self.linkify_dict_srv_and_hosts(s, 'impacts')
                self.linkify_dict_srv_and_hosts(s, 'source_problems')
                logger.debug("Alignak - linking service parents: %s", s.parent_dependencies)
                self.linkify_dict_srv_and_hosts(s, 'parent_dependencies')
                logger.debug("Alignak - linking service children: %s", s.child_dependencies)
                self.linkify_dict_srv_and_hosts(s, 'child_dependencies')
                logger.debug("Alignak - linking service commands")
                s.linkify_one_command_with_commands(self.commands, 'check_command')
                s.linkify_one_command_with_commands(self.commands, 'event_handler')
                s.linkify_one_command_with_commands(self.commands, 'snapshot_command')
            except Exception as e:
                logger.error("Alignak - all_done_linking, exception when linking services: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
        logger.info("Alignak - linked services")

        # Linking TIMEPERIOD exclude with real ones now
        logger.info("Alignak - linking timeperiods exclusions...")
        for tp in self.timeperiods:
            logger.info("Alignak - timeperiod: %s", tp.timeperiod_name)
            try:
                for entry in tp.unresolved:
                    logger.info("Alignak - resolving daterange: %s", entry)
                    tp.resolve_daterange(tp.dateranges, entry)

                new_exclude = []
                for ex in tp.exclude:
                    logger.debug("Alignak - exclusion: %s", ex.timeperiod_name)
                    t = self.timeperiods.find_by_name(ex.timeperiod_name)
                    if t:
                        new_exclude.append(t)
                tp.exclude = new_exclude

            except Exception as e:
                logger.error("Alignak - all_done_linking, exception when linking timeperiods: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
        logger.info("Alignak - linked timeperiods")

        # Link contactgroups objects to their contacts objects
        logger.info("Alignak - linking contactgroups to contacts...")
        for cg in self.contactgroups:
            try:
                logger.info("Alignak - contactgroup '%s' members: %s", cg.contactgroup_name, cg.members)
                new_members = []
                for hname in cg.members:
                    logger.debug("Alignak - contactgroup '%s' member: %s (%s)", cg.contactgroup_name, hname, tmp_contacts.find_by_name(hname))
                    c = self.contacts.find_by_name(hname)
                    if c:
                        new_members.append(c)
                        # Link back with hosts
                        if cg not in c.contactgroups:
                            c.contactgroups.append(cg)
                cg.members = new_members
                logger.debug("Alignak - contactgroup '%s' members (new): %s", cg.contactgroup_name, cg.members)
            except Exception as e:
                logger.error("Alignak - all_done_linking, exception when linking contactgroups to contacts: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
                continue

        # Manage Livestate
        # ------------------------------------------------------------------------------------------
        # Livestate
        self.update_livestate()

        self.loaded = True

        logger.warning("Linking phase duration: %s" % (time.time() - start))

    def update_livestate(self):
        """
        """
        # Hosts
        logger.debug("Alignak - getting hosts livestate...")
        hosts_ls = self.get_livestate_hosts()
        for element in hosts_ls:
            try:
                # host relation
                hostname = ''
                if not 'name' in element:
                    parameters = {
                        'where': json.dumps({'_id': element['host_name']})
                    }
                    resp = self.get_objects('host', parameters=parameters)
                    if '_items' in resp:
                        for group in resp['_items']:
                            hostname = group['name']
                else:
                    hostname = element['name']

                if hostname:
                    if 'current_attempt' in element:
                        element['attempt'] = element['current_attempt']
                    if 'downtime' in element:
                        element['in_scheduled_downtime'] = element['downtime']
                    if 'acknowledged' in element:
                        element['problem_has_been_acknowledged'] = element['acknowledged']
                    if 'state_id' in element and not 'is_problem' in element and element['state_id'] > 0:
                        element['is_problem'] = True

                    logger.debug("Alignak - LS host %s", hostname)
                    h = self.hosts.find_by_name(hostname)
                    if h:
                        logger.debug("Alignak - LS found host %s", h.host_name)
                        for property in element:
                            if property in [
                                "in_scheduled_downtime", "problem_has_been_acknowledged",
                                "last_check", "next_check",
                                "last_state", "last_state_type", "last_state_changed",
                                "attempt", "max_attempts",
                                "state", "state_type", "state_id",
                                "output", "long_output", "perf_data",
                                "business_impact",
                                "is_problem"
                                ]:
                                logger.debug("Alignak - LS host %s: %s = %s", hostname, property, element[property])
                                setattr(h, property, element[property])
                        logger.debug("Alignak - host %s is %s", hostname, h.state)
            except Exception as e:
                logger.error("Alignak - all_done_linking, exception: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
                continue

        # Services
        logger.debug("Alignak - getting services livestate...")
        services_ls = self.get_livestate_services()
        for element in services_ls:
            try:
                # host relation
                hostname = ''
                service = ''
                if not 'name' in element:
                    parameters = {
                        'where': json.dumps({'_id': element['host_name']})
                    }
                    resp = self.get_objects('host', parameters=parameters)
                    if '_items' in resp:
                        for group in resp['_items']:
                            hostname = group['name']

                    # service relation
                    parameters = {
                        'where': json.dumps({'_id': element['service_description']})
                    }
                    resp = self.get_objects('service', parameters=parameters)
                    if '_items' in resp:
                        for group in resp['_items']:
                            service = group['name']
                else:
                    hs_name = element['name'].split('/')
                    hostname = hs_name[0]
                    service = hs_name[1]


                if hostname and service:
                    if 'current_attempt' in element:
                        element['attempt'] = element['current_attempt']
                    if 'downtime' in element:
                        element['in_scheduled_downtime'] = element['downtime']
                    if 'acknowledged' in element:
                        element['problem_has_been_acknowledged'] = element['acknowledged']
                    if 'state_id' in element and not 'is_problem' in element and element['state_id'] > 0:
                        element['is_problem'] = True

                    logger.debug("Alignak - LS host/service %s/%s", hostname, service)
                    s = self.services.find_srv_by_name_and_hostname(hostname, service)
                    if s:
                        logger.debug("Alignak - LS found service %s/%s", s.host_name, s.service_description)
                        for property in element:
                            if property in [
                                "in_scheduled_downtime", "problem_has_been_acknowledged",
                                "last_check", "next_check",
                                "last_state", "last_state_type", "last_state_changed",
                                "attempt", "max_attempts",
                                "state", "state_type", "state_id",
                                "output", "long_output", "perf_data",
                                "business_impact",
                                "is_problem"
                                ]:
                                logger.debug("Alignak - LS service %s/%s: %s = %s", hostname, service, property, element[property])
                                setattr(s, property, element[property])
                        logger.debug("Alignak - service %s/%s is %s", hostname, service, s.state)
            except Exception as e:
                logger.error("Alignak - all_done_linking, exception: %s", str(e))
                logger.error("Alignak - Back trace: %s", traceback.format_exc())
                continue

        return True

    def update_element(self, element, data):
        for property in data:
            setattr(element, property, data[property])

    def linkify_dict_srv_and_hosts(self, o, prop):
        logger.debug("Alignak - linkify_dict_srv_and_hosts, property: %s, object: %s", prop, o)
        v = getattr(o, prop)
        if not v:
            v = {'hosts': [], 'services': []}
            setattr(o, prop, v)
        logger.debug("Alignak - linkify_dict_srv_and_hosts, v: %s", v)

        new_v = []

        new_v = []
        # print "Linkify Dict SRV/Host", v, o.get_name(), prop
        for name in v['services']:
            elts = name.split('/')
            hname = elts[0]
            sdesc = elts[1]
            s = self.services.find_srv_by_name_and_hostname(hname, sdesc)
            if s:
                new_v.append(s)
        for hname in v['hosts']:
            h = self.hosts.find_by_name(hname)
            if h:
                new_v.append(h)
        setattr(o, prop, new_v)

    def linkify_host_and_hosts(self, o, prop):
        v = getattr(o, prop)
        if not v:
            v = []
            setattr(o, prop, v)

        new_v = []
        for hname in v:
            h = self.hosts.find_by_name(hname)
            if h:
                new_v.append(h)
        setattr(o, prop, new_v)
