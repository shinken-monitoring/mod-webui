#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ai ts=4 sts=4 et sw=4 nu

import traceback
import json
import time

from shinken.log import logger

from .metamodule import MetaModule

class PrefsMetaModule(MetaModule):

    _functions = ['get_ui_user_preference',
                  'set_ui_user_preference',
                  'get_ui_common_preference',
                  'set_ui_common_preference']

    def __init__(self, modules, app):
        ''' Because it wouldn't make sense to use many submodules in this
            MetaModule, we only use the first one in the list of modules.
            If there is no module in the list, we try to init a default module.
        '''
        self.app = app
        self.module = None
        if modules:
            if len(modules) > 1:
                logger.warning('[WebUI] Too much prefs modules declared (%s > 1). Using %s.' % (len(modules), modules[0]))
            self.module = modules[0]
        else:
            try:
                self.module = MongoDBPreferences(app.modconf)
            except Exception as e:
                logger.warning('[WebUI] %s' % e)

    def is_available(self):
        return self.module is not None

    def get_ui_user_preference(self, user, key=None, default=None):
        if self.is_available():
            return self.module.get_ui_user_preference(user, key) or default
        return default

    def set_ui_user_preference(self, user, key, value):
        if self.is_available():
            return self.module.set_ui_user_preference(user, key, value)

    def get_ui_common_preference(self, key=None, default=None):
        if self.is_available():
            return self.module.get_ui_common_preference(key) or default
        return default

    def set_ui_common_preference(self, key, value):
        if self.is_available():
            return self.module.set_ui_common_preference(key, value)

    def get_user_bookmarks(self, user):
        ''' Returns the user bookmarks. '''
        return json.loads(self.get_ui_user_preference(user, 'bookmarks') or '[]')

    def get_common_bookmarks(self):
        ''' Returns the common bookmarks. '''
        return json.loads(self.get_ui_common_preference('bookmarks') or '[]')



class MongoDBPreferences():
    '''
    This module job is to get webui configuration data from a mongodb database:
    '''

    def __init__(self, mod_conf):
        try:
            import pymongo
        except ImportError:
            logger.error('[WebUI-MongoDBPreferences] Can not import pymongo'
                         'Please install it with a 3.x+ version from '
                         'https://pypi.python.org/pypi/pymongo')
            raise

        self.uri = getattr(mod_conf, 'uri', 'mongodb://localhost')
        logger.info('[WebUI-MongoDBPreferences] mongo uri: %s' % self.uri)

        self.replica_set = getattr(mod_conf, 'replica_set', None)
        if self.replica_set and int(pymongo.version[0]) < 3:
            logger.error('[WebUI-MongoDBPreferences] Can not initialize module with '
                         'replica_set because your pymongo lib is too old. '
                         'Please install it with a 3.x+ version from '
                         'https://pypi.python.org/pypi/pymongo')
            return None

        self.database = getattr(mod_conf, 'database', 'shinken')
        self.username = getattr(mod_conf, 'username', None)
        self.password = getattr(mod_conf, 'password', None)
        logger.info('[WebUI-MongoDBPreferences] database: %s' % self.database)

        self.mongodb_fsync = getattr(mod_conf, 'mongodb_fsync', "True") == "True"

        self.is_connected = False
        self.con = None
        self.db = None

        logger.info("[WebUI-MongoDBPreferences] Trying to open a Mongodb connection to %s, database: %s" % (self.uri, self.database))
        self.open()

    def open(self):
        try:
            from pymongo import MongoClient
        except ImportError:
            logger.error('[WebUI-MongoDBPreferences] Can not import pymongo.MongoClient')
            raise

        try:
            if self.replica_set:
                self.con = MongoClient(self.uri, replicaSet=self.replica_set, fsync=self.mongodb_fsync)
            else:
                self.con = MongoClient(self.uri, fsync=self.mongodb_fsync)
            logger.info("[WebUI-MongoDBPreferences] connected to mongodb: %s", self.uri)

            self.db = getattr(self.con, self.database)
            logger.info("[WebUI-MongoDBPreferences] connected to the database: %s", self.database)

            if self.username and self.password:
                self.db.authenticate(self.username, self.password)
                logger.info("[WebUI-MongoDBPreferences] user authenticated: %s", self.username)

            # Check if a document exists in the preferences collection ...
            logger.info('[WebUI-MongoDBPreferences] searching connection test item in the collection ...')
            u = self.db.ui_user_preferences.find_one({'_id': 'shinken-test'})
            if not u:
                # No document ... create a new one!
                logger.debug('[WebUI-MongoDBPreferences] not found connection test item in the collection')
                r = self.db.ui_user_preferences.save({'_id': 'shinken-test', 'last_test': time.time()})
                logger.info('[WebUI-MongoDBPreferences] updated connection test item')
            else:
                # Found document ... update!
                logger.debug('[WebUI-MongoDBPreferences] found connection test item in the collection')
                r = self.db.ui_user_preferences.update({'_id': 'shinken-test'}, {'$set': {'last_test': time.time()}})
                logger.info('[WebUI-MongoDBPreferences] updated connection test item')

            self.is_connected = True
            logger.info('[WebUI-MongoDBPreferences] database connection established')
        except Exception, e:
            logger.error("[WebUI-MongoDBPreferences] Exception: %s", str(e))
            logger.debug("[WebUI-MongoDBPreferences] Exception type: %s", type(e))
            logger.debug("[WebUI-MongoDBPreferences] Back trace of this kill: %s", traceback.format_exc())
            # Depending on exception type, should raise ...
            self.is_connected = False
            raise

        return self.is_connected

    def close(self):
        self.is_connected = False
        self.conn.close()

    # We will get in the mongodb database the user preference entry, for the 'shinken-global' user
    # and get the key they are asking us
    def get_ui_common_preference(self, key):
        if not self.is_connected:
            if not self.open():
                logger.error("[WebUI-MongoDBPreferences] error during initialization, no database connection!")
                return None

        try:
            e = self.db.ui_user_preferences.find_one({'_id': 'shinken-global'})
        except Exception, e:
            logger.warning("[WebUI-MongoDBPreferences] Exception: %s", str(e))
            self.is_connected = False
            return None

        # Maybe it's a new entry or missing this parameter, bail out
        if not e or key not in e:
            logger.debug("[WebUI-MongoDBPreferences] new parameter of not stored preference: %s", key)
            return None

        return e.get(key)

    # We will get in the mongodb database the user preference entry, and get the key
    # they are asking us
    def get_ui_user_preference(self, user, key):
        if not self.is_connected:
            if not self.open():
                logger.error("[WebUI-MongoDBPreferences] error during initialization, no database connection!")
                return None

        if not user:
            print '[WebUI-MongoDBPreferences]: error get_ui_user_preference, no defined user'
            return None

        try:
            e = self.db.ui_user_preferences.find_one({'_id': user.get_name()})
        except Exception, e:
            logger.warning("[WebUI-MongoDBPreferences] Exception: %s", str(e))
            self.is_connected = False
            return None

        # If no specific key is required, returns all user parameters ...
        if key is None:
            return e

        # Maybe it's a new entry or missing this parameter, bail out
        if not e or key not in e:
            logger.debug("[WebUI-MongoDBPreferences] new parameter of not stored preference: %s", key)
            return None

        return e.get(key)

    # Same but for saving
    def set_ui_user_preference(self, user, key, value):
        if not self.is_connected:
            if not self.open():
                logger.error("[WebUI-MongoDBPreferences] error during initialization, no database connection!")
                return None

        if not user:
            logger.warning("[WebUI-MongoDBPreferences] error set_ui_user_preference, no user!")
            return None

        try:
            # check a collection exist for this user
            u = self.db.ui_user_preferences.find_one({'_id': user.get_name()})
            if not u:
                # no collection for this user? create a new one
                self.db.ui_user_preferences.save({'_id': user.get_name(), key: value})

            r = self.db.ui_user_preferences.update({'_id': user.get_name()}, {'$set': {key: value}})
            # Maybe there was no doc there, if so, create an empty one
            if not r:
                # Maybe the user exist, if so, get the whole user entry
                u = self.db.ui_user_preferences.find_one({'_id': user.get_name()})
                if not u:
                    logger.debug ("[WebUI-MongoDBPreferences] No user entry for %s, I create a new one", user.get_name())
                    self.db.ui_user_preferences.save({'_id': user.get_name(), key: value})
                else:  # ok, it was just the key that was missing, just update it and save it
                    u[key] = value
                    logger.debug ("[WebUI-MongoDBPreferences] Just saving the new key in the user pref")
                    self.db.ui_user_preferences.save(u)
        except Exception, e:
            logger.warning("[WebUI-MongoDBPreferences] Exception: %s", str(e))
            self.is_connected = False
            return None

    def set_ui_common_preference(self, key, value):
        if not self.is_connected:
            if not self.open():
                logger.error("[WebUI-MongoDBPreferences] error during initialization, no database connection!")
                return None

        try:
            # check a collection exist for this user
            u = self.db.ui_user_preferences.find_one({'_id': 'shinken-global'})

            if not u:
                # no collection for this user? create a new one
                r = self.db.ui_user_preferences.save({'_id': 'shinken-global', key: value})
            else:
                # found a collection for this user
                r = self.db.ui_user_preferences.update({'_id': 'shinken-global'}, {'$set': {key: value}})
        except Exception, e:
            logger.warning("[WebUI-MongoDBPreferences] Exception: %s", str(e))
            self.is_connected = False
            return None

        if not r:
            return None

        return r
