#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ai ts=4 sts=4 et sw=4 nu

import traceback
import json
import time

import pymongo

from shinken.log import logger

from .metamodule import MetaModule


class PrefsMetaModule(MetaModule):

    _functions = ["get_ui_user_preference",
                  "set_ui_user_preference",
                  "get_ui_common_preference",
                  "set_ui_common_preference"]

    def __init__(self, modules, app):
        """ Because it wouldn"t make sense to use many submodules in this
            MetaModule, we only use the first one in the list of modules.
            If there is no module in the list, we try to init a default module.
        """
        super(PrefsMetaModule, self).__init__(modules=modules, app=app)

        self.app = app
        self.module = None
        if modules:
            if len(modules) > 1:
                logger.warning("[WebUI] Too much prefs modules declared (%s > 1). Using %s.",
                               len(modules), modules[0])
            self.module = modules[0]
        else:
            try:
                self.module = MongoDBPreferences(app.modconf)
            except Exception as exp:
                logger.warning("[WebUI] %s", str(exp))

    def is_available(self):
        if isinstance(self.module, MongoDBPreferences):
            return self.module.is_connected

        return self.module is not None

    def get_ui_user_preference(self, user, key=None, default=None):
        if self.is_available():
            return self.module.get_ui_user_preference(user, key) or default
        return default

    def set_ui_user_preference(self, user, key, value):
        if self.is_available():
            self.module.set_ui_user_preference(user, key, value)

    def get_ui_common_preference(self, key=None, default=None):
        if self.is_available():
            # return self.module.get_ui_common_preference(key) or default
            logger.debug("[WebUI-prefs] get common preference: %s", key)
            value = self.module.get_ui_common_preference(key)
            if value is None and default is not None:
                logger.debug("[WebUI-prefs] set default value: %s", default)
                self.set_ui_common_preference(key, default)
                value = default
            logger.debug("[WebUI-prefs] got: %s", value)
            return value
        return default

    def set_ui_common_preference(self, key, value):
        if self.is_available():
            self.module.set_ui_common_preference(key, value)

    def get_user_bookmarks(self, user):
        """ Returns the user bookmarks. """
        return json.loads(self.get_ui_user_preference(user, "bookmarks") or "[]")

    def get_common_bookmarks(self):
        """ Returns the common bookmarks. """
        return json.loads(self.get_ui_common_preference("bookmarks") or "[]")


class MongoDBPreferences(object):
    """
    This module job is to store/load webui configuration data from a mongodb database.
    """

    def __init__(self, mod_conf):
        self.uri = getattr(mod_conf, "uri", "mongodb://localhost")
        logger.info("[WebUI-MongoDBPreferences] mongo uri: %s", self.uri)

        self.replica_set = getattr(mod_conf, "replica_set", None)
        if self.replica_set and int(pymongo.version[0]) < 3:
            logger.error("[WebUI-MongoDBPreferences] Can not initialize module with "
                         "replica_set because your pymongo lib is too old. "
                         "Please install it with a 3.x+ version from "
                         "https://pypi.python.org/pypi/pymongo")
            return

        self.database = getattr(mod_conf, "database", "shinken")
        self.username = getattr(mod_conf, "username", None)
        self.password = getattr(mod_conf, "password", None)
        logger.info("[WebUI-MongoDBPreferences] database: %s, user: %s",
                    self.database, self.username)

        self.mongodb_fsync = getattr(mod_conf, "mongodb_fsync", "True") == "True"

        self.is_connected = False
        self.con = None
        self.db = None

        if self.uri:
            logger.info("[WebUI-MongoDBPreferences] Trying to open a Mongodb connection to %s, database: %s",
                        self.uri, self.database)
            self.open()
        else:
            logger.warning("You do not have any MongoDB connection for user's preferences storage module installed. "
                           "The Web UI dashboard and user's preferences will not be saved.")

    def open(self):
        """Open a connection to the mongodb server and check the connection by updating a documetn in a collection"""
        try:
            from pymongo import MongoClient
        except ImportError:
            logger.error("[WebUI-MongoDBPreferences] Can not import pymongo.MongoClient")
            raise

        try:
            if self.replica_set:
                self.con = MongoClient(self.uri, replicaSet=self.replica_set,
                                       fsync=self.mongodb_fsync)
            else:
                self.con = MongoClient(self.uri, fsync=self.mongodb_fsync)
            logger.info("[WebUI-MongoDBPreferences] connected to mongodb: %s", self.uri)

            self.db = getattr(self.con, self.database)
            logger.info("[WebUI-MongoDBPreferences] connected to the database: %s", self.database)

            if self.username and self.password:
                self.db.authenticate(self.username, self.password)
                logger.info("[WebUI-MongoDBPreferences] user authenticated: %s", self.username)

            # Update a document test item in the collection to confirm correct connection
            logger.info("[WebUI-MongoDBPreferences] updating connection test item in the collection ...")
            self.db.ui_user_preferences.update_one({"_id": "test-ui_prefs"},
                                                   {"$set": {"last_test": time.time()}},
                                                   upsert=True)
            logger.info("[WebUI-MongoDBPreferences] updated connection test item")

            self.is_connected = True
            logger.info("[WebUI-MongoDBPreferences] database connection established")
        except Exception as exp:
            logger.error("[WebUI-MongoDBPreferences] Exception: %s", str(exp))
            logger.debug("[WebUI-MongoDBPreferences] Back trace of this kill: %s", traceback.format_exc())
            # Depending on exception type, should raise ...
            self.is_connected = False
            raise

        return self.is_connected

    def close(self):
        self.is_connected = False
        self.con.close()

    def get_ui_common_preference(self, key):
        """Get a common preference entry in the mongodb database"""
        if not self.uri:
            return None

        if not self.is_connected:
            if not self.open():
                logger.error("[WebUI-MongoDBPreferences] error during initialization, no database connection!")
                return None

        try:
            doc = self.db.ui_user_preferences.find_one({"_id": "shinken-global"})
        except Exception as exp:
            logger.warning("[WebUI-MongoDBPreferences] Exception: %s", str(exp))
            self.is_connected = False
            return None

        # If no specific key is required, returns all parameters ...
        if key is None:
            return doc

        # Maybe it"s a new entry or missing this parameter, bail out
        if not doc or key not in doc:
            logger.debug("[WebUI-MongoDBPreferences] new parameter of not stored preference: %s", key)
            return None

        return doc.get(key)

    def get_ui_user_preference(self, user, key):
        """Get a user preference entry in the mongodb database"""
        if not self.uri:
            return None

        if not self.is_connected:
            if not self.open():
                logger.error("[WebUI-MongoDBPreferences] error during initialization, no database connection!")
                return None

        if not user:
            # logger.error("[WebUI-MongoDBPreferences]: error get_ui_user_preference, no defined user")
            return None

        try:
            doc = self.db.ui_user_preferences.find_one({"_id": user.contact_name})
        except Exception as exp:
            logger.warning("[WebUI-MongoDBPreferences] Exception: %s", str(exp))
            self.is_connected = False
            return None

        # If no specific key is required, returns all user parameters ...
        if key is None:
            return doc

        # Maybe it"s a new entry or missing this parameter, bail out
        if not doc or key not in doc:
            logger.debug("[WebUI-MongoDBPreferences] new parameter or not stored preference: %s", key)
            return None

        return doc.get(key)

    def set_ui_user_preference(self, user, key, value):
        """Save the user preference entry in the mongodb database"""
        if not self.uri:
            return

        if not self.is_connected:
            if not self.open():
                logger.error("[WebUI-MongoDBPreferences] error during initialization, no database connection!")
                return

        if not user:
            # logger.warning("[WebUI-MongoDBPreferences] error set_ui_user_preference, no user!")
            return

        try:
            # Update/insert user preference
            r = self.db.ui_user_preferences.update_one({"_id": user.contact_name},
                                                       {"$set": {key: value}}, upsert=True)
            if not r:
                # This should never happen but log for alerting!
                logger.warning("[WebUI-MongoDBPreferences] failed updating user preference: %s", key)
        except Exception as exp:
            logger.warning("[WebUI-MongoDBPreferences] Exception: %s", str(exp))
            self.is_connected = False

    def set_ui_common_preference(self, key, value):
        """Save a common preference entry in the mongodb database"""
        if not self.uri:
            return

        if not self.is_connected:
            if not self.open():
                logger.error("[WebUI-MongoDBPreferences] error during initialization, no database connection!")
                return

        try:
            # Update/insert the common preference
            r = self.db.ui_user_preferences.update_one({"_id": "shinken-global"},
                                                       {"$set": {key: value}},
                                                       upsert=True)
            if not r:
                # This should never happen but log for alerting!
                logger.warning("[WebUI-MongoDBPreferences] failed updating common preference: %s", key)
        except Exception as exp:
            logger.warning("[WebUI-MongoDBPreferences] Exception: %s", str(exp))
            self.is_connected = False
