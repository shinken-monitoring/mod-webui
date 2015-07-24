#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright (C) 2015:
# Guillaume Subiron, maethor@subiron.org
#
# Based upon "mod-mongodb", Copyright (C) 2009-2012:
# Gabes Jean, naparuba@gmail.com
# Gerhard Lausser, Gerhard.Lausser@consol.de
# Gregory Starck, g.starck@gmail.com
# Hartmut Goebel, h.goebel@goebel-consult.de
#
# This file is part of Shinken.
#
# Shinken is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Shinken is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Shinken. If not, see <http://www.gnu.org/licenses/>.

"""
This module job is to get webui configuration data from a mongodb database:
"""

import traceback

from shinken.log import logger

try:
    import pymongo
    from pymongo import MongoClient
except ImportError:
    logger.error('[WebUI - MongoDB] Can not import pymongo and/or MongoClient'
                 'Your pymongo lib is too old. '
                 'Please install it with a 3.x+ version from '
                 'https://pypi.python.org/pypi/pymongo')
    raise


class MongoDBPreferences():
    def __init__(self, mod_conf):
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