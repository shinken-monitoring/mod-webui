#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ai ts=4 sts=4 et sw=4 nu

import traceback
import json

from shinken.log import logger

from submodules.metamodule import MetaModule

class PrefsMetaModule(MetaModule):

    _functions = ['get_ui_user_preference',
                  'set_ui_user_preference',
                  'get_ui_common_preference',
                  'set_ui_common_preference']

    def __init__(self, modules, app):
        ''' Because it would'nt make sense to use many submodules in this
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
            from pymongo import MongoClient
        except ImportError:
            logger.error('[WebUI - MongoDB] Can not import pymongo and/or MongoClient'
                         'Your pymongo lib is too old. '
                         'Please install it with a 3.x+ version from '
                         'https://pypi.python.org/pypi/pymongo')
            raise
        self.uri = getattr(mod_conf, 'uri', 'mongodb://localhost/?safe=false')
        logger.info('[WebUI - MongoDB] mongo uri: %s' % self.uri)
        self.replica_set = getattr(mod_conf, 'replica_set', None)
        if self.replica_set and int(pymongo.version[0]) < 3:
            logger.error('[WebUI - MongoDB] Can not initialize module with '
                         'replica_set because your pymongo lib is too old. '
                         'Please install it with a 3.x+ version from '
                         'https://pypi.python.org/pypi/pymongo')
            return None
        self.database = getattr(mod_conf, 'database', 'shinken')
        self.username = getattr(mod_conf, 'username', None)
        self.password = getattr(mod_conf, 'password', None)
        logger.info('[WebUI - MongoDB] database: %s' % self.database)

        self.con = None
        self.db = None

        logger.info("[WebUI - MongoDB] Try to open a Mongodb connection to %s, database: %s" % (self.uri, self.database))
        try:
            if self.replica_set:
                self.con = MongoClient(self.uri, replicaSet=self.replica_set, fsync=False)
            else:
                self.con = MongoClient(self.uri, fsync=False)

            self.db = getattr(self.con, self.database)
            if self.username and self.password:
                self.db.authenticate(self.username, self.password)
        except Exception, e:
            logger.warning("[WebUI - MongoDB] Exception type: %s", type(e))
            logger.warning("[WebUI - MongoDB] Back trace of this kill: %s", traceback.format_exc())
            # Depending on exception type, should raise ...
            
        logger.info("[WebUI - MongoDB] Connection OK")

    # We will get in the mongodb database the user preference entry, for the 'shinken-global' user
    # and get the key they are asking us
    def get_ui_common_preference(self, key):
        if not self.db:
            logger.error("[WebUI - MongoDB] error during initialization, no database connection!")
            return None

        e = self.db.ui_user_preferences.find_one({'_id': 'shinken-global'})

        # Maybe it's a new entryor missing this parameter, bail out
        if not e or key not in e:
            logger.warning("[WebUI - MongoDB] error during initialization, no database connection")
            return None

        return e.get(key)

    # We will get in the mongodb database the user preference entry, and get the key
    # they are asking us
    def get_ui_user_preference(self, user, key):
        if not self.db:
            logger.error("[WebUI - MongoDB] error during initialization, no database connection!")
            return None

        if not user:
            print '[WebUI - MongoDB]: error get_ui_user_preference, no user'
            return None

        e = self.db.ui_user_preferences.find_one({'_id': user.get_name()})

        # If no specific key is required, returns all user parameters ...
        if key is None:
            return e

        # Maybe it's a new entryor missing this parameter, bail out
        if not e or key not in e:
            return None

        return e.get(key)

    # Same but for saving
    def set_ui_user_preference(self, user, key, value):
        if not self.db:
            logger.error("[WebUI - MongoDB] error during initialization, no database connection!")
            return None

        if not user:
            logger.warning("[WebUI - MongoDB] error set_ui_user_preference, no user!")
            return None

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
                logger.debug ("[WebUI - MongoDB] No user entry for %s, I create a new one", user.get_name())
                self.db.ui_user_preferences.save({'_id': user.get_name(), key: value})
            else:  # ok, it was just the key that was missing, just update it and save it
                u[key] = value
                logger.debug ("[WebUI - MongoDB] Just saving the new key in the user pref")
                self.db.ui_user_preferences.save(u)

    def set_ui_common_preference(self, key, value):
        if not self.db:
            logger.error("[WebUI - MongoDB] error during initialization, no database connection!")
            return None

        # check a collection exist for this user
        u = self.db.ui_user_preferences.find_one({'_id': 'shinken-global'})

        if not u:
            # no collection for this user? create a new one
            r = self.db.ui_user_preferences.save({'_id': 'shinken-global', key: value})
        else:
            # found a collection for this user
            r = self.db.ui_user_preferences.update({'_id': 'shinken-global'}, {'$set': {key: value}})

        if not r:
            return None

        return r
