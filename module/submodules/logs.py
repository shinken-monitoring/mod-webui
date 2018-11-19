#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ai ts=4 sts=4 et sw=4 nu

import traceback
import time

import pymongo

from shinken.log import logger

from .metamodule import MetaModule


class LogsMetaModule(MetaModule):

    _functions = ['get_ui_logs', 'get_ui_availability']
    _custom_log = "You should configure the module 'mongo-logs' in your broker " \
                  "to be able to display logs and availability."

    def __init__(self, modules, app):
        """ Because it wouldn't make sense to use many submodules in this
            MetaModule, we only use the first one in the list of modules.
            If there is no module in the list, we try to init a default module.
        """
        super(LogsMetaModule, self).__init__(modules=modules, app=app)

        self.app = app
        self.module = None
        if modules:
            if len(modules) > 1:
                logger.warning("[WebUI] Too much prefs modules declared (%s > 1). Using %s.",
                               len(modules), modules[0])
            self.module = modules[0]
        else:
            try:
                self.module = MongoDBLogs(app.modconf)
            except Exception as exp:
                logger.warning('[WebUI] Exception %s', str(exp))

    def is_available(self):
        if isinstance(self.module, MongoDBLogs):
            return self.module.is_connected

        return self.module is not None

    def get_ui_logs(self, *args, **kwargs):
        return self.module.get_ui_logs(*args, **kwargs)

    def get_ui_availability(self, elt, range_start=None, range_end=None, default=None):
        if self.is_available():
            return self.module.get_ui_availability(elt, range_start, range_end) or default
        return default


class MongoDBLogs(object):
    """
    This module job is to get webui configuration data from a mongodb database:
    """

    def __init__(self, mod_conf):
        self.uri = getattr(mod_conf, 'uri', 'mongodb://localhost')
        logger.info('[WebUI-mongo-logs] mongo uri: %s', self.uri)

        self.replica_set = getattr(mod_conf, 'replica_set', None)
        if self.replica_set and int(pymongo.version[0]) < 3:
            logger.error('[WebUI-mongo-logs] Can not initialize module with '
                         'replica_set because your pymongo lib is too old. '
                         'Please install it with a 3.x+ version from '
                         'https://pypi.python.org/pypi/pymongo')
            return

        self.database = getattr(mod_conf, 'database', 'shinken')
        self.username = getattr(mod_conf, 'username', None)
        self.password = getattr(mod_conf, 'password', None)
        logger.info('[WebUI-mongo-logs] database: %s, user: %s', self.database, self.username)

        self.logs_collection = getattr(mod_conf, 'logs_collection', 'logs')
        logger.info('[WebUI-mongo-logs] shinken logs collection: %s', self.logs_collection)

        self.hav_collection = getattr(mod_conf, 'hav_collection', 'availability')
        logger.info('[WebUI-mongo-logs] hosts availability collection: %s', self.hav_collection)

        # self.max_records = int(getattr(mod_conf, 'max_records', '200'))
        # logger.info('[WebUI-mongo-logs] max records: %s' % self.max_records)

        self.mongodb_fsync = getattr(mod_conf, 'mongodb_fsync', "True") == "True"
        self.is_connected = False
        self.con = None
        self.db = None

        if not self.uri:
            logger.warning("[WebUI-MongoDBPreferences] No Mongodb connection configured!")
            return

        if self.uri:
            logger.info("[WebUI-mongo-logs] Trying to open a Mongodb connection to %s, database: %s",
                        self.uri, self.database)
            self.open()
        else:
            logger.warning("You do not have any MongoDB connection for log module installed. "
                           "The Web UI system log and availability features will not be available.")

    def open(self):
        try:
            from pymongo import MongoClient
        except ImportError:
            logger.error('[WebUI-mongo-logs] Can not import pymongo.MongoClient')
            raise

        try:
            if self.replica_set:
                self.con = MongoClient(self.uri, replicaSet=self.replica_set,
                                       fsync=self.mongodb_fsync, connect=True)
            else:
                self.con = MongoClient(self.uri, fsync=self.mongodb_fsync, connect=True)
            logger.info("[WebUI-mongo-logs] connected to mongodb: %s", self.uri)

            self.db = getattr(self.con, self.database)
            logger.info("[WebUI-mongo-logs] connected to the database: %s", self.database)

            if self.username and self.password:
                self.db.authenticate(self.username, self.password)
                logger.info("[WebUI-mongo-logs] user authenticated: %s", self.username)

            # Check if a document exists in the logs collection ...
            logger.info('[WebUI-mongo-logs] searching connection test item in the collection ...')
            u = self.db[self.logs_collection].find_one({'_id': 'shinken-test'})
            if not u:
                # No document ... create a new one!
                logger.debug('[WebUI-mongo-logs] not found connection test item in the collection')
                r = self.db[self.logs_collection].save({'_id': 'shinken-test',
                                                        'last_test': time.time()})
                logger.debug('[WebUI-mongo-logs] result: %s', r)
                logger.info('[WebUI-mongo-logs] updated connection test item')
            else:
                # Found document ... update!
                logger.debug('[WebUI-mongo-logs] found connection test item in the collection')
                r = self.db[self.logs_collection].update({'_id': 'shinken-test'},
                                                         {'$set': {'last_test': time.time()}})
                logger.debug('[WebUI-mongo-logs] result: %s', r)
                logger.info('[WebUI-mongo-logs] updated connection test item')

            self.is_connected = True
            logger.info('[WebUI-mongo-logs] database connection established')
        except Exception as e:
            logger.error("[WebUI-mongo-logs] Exception: %s", str(e))
            logger.debug("[WebUI-mongo-logs] Exception type: %s", type(e))
            logger.debug("[WebUI-mongo-logs] Back trace of this kill: %s", traceback.format_exc())
            # Depending on exception type, should raise ...
            self.is_connected = False
            raise

        return self.is_connected

    def close(self):
        self.is_connected = False
        self.con.close()

    # We will get in the mongodb database the logs
    def get_ui_logs(self, filters=None, range_start=None, range_end=None, limit=200, offset=0):
        if not self.uri:
            return None

        if not self.db:
            logger.error("[mongo-logs] error Problem during init phase, no database connection")
            return []

        logger.debug("[mongo-logs] get_ui_logs")

        if filters is None:
            filters = {}

        query = []
        for k, v in filters.items():
            query.append({k: v})
        if range_start:
            query.append({'time': {'$gte': range_start}})
        if range_end:
            query.append({'time': {'$lte': range_end}})

        query = {'$and': query} if query else None
        logger.debug("[mongo-logs] Fetching %limit records from database with query: "
                     "'%s' and offset %s", limit, query, offset)

        records = []
        try:
            records = self.db[self.logs_collection].find(query).sort([
                ("time", pymongo.DESCENDING)]).skip(offset)
            if limit:
                records = records.limit(limit)

            logger.debug("[mongo-logs] %d records fetched from database.", records.count())
        except Exception as exp:
            logger.error("[mongo-logs] Exception when querying database: %s", str(exp))

        return records

    # We will get in the mongodb database the host availability
    def get_ui_availability(self, elt, range_start=None, range_end=None):
        if not self.uri:
            return None

        if not self.db:
            logger.error("[mongo-logs] error Problem during init phase, no database connection")
            return []

        logger.debug("[mongo-logs] get_ui_availability, name: %s", elt)

        query = [{"hostname": elt.host_name}]
        if elt.__class__.my_type == 'service':
            query.append({"service": elt.service_description})
        if range_start:
            query.append({'day_ts': {'$gte': range_start}})
        if range_end:
            query.append({'day_ts': {'$lte': range_end}})

        query = {'$and': query}
        logger.debug("[mongo-logs] Fetching records from database with query: '%s'", query)

        records = []
        try:
            for log in self.db[self.hav_collection].find(query).sort(
                    [("day", pymongo.DESCENDING),
                     ("hostname", pymongo.ASCENDING),
                     ("service", pymongo.ASCENDING)]):
                if '_id' in log:
                    del log['_id']
                records.append(log)
            logger.debug("[mongo-logs] %d records fetched from database.", records.count())
        except Exception as exp:
            logger.error("[mongo-logs] Exception when querying database: %s", str(exp))

        if not records:
            logger.warning("[mongo-logs] no record fetched from database.")
            return None

        # Aggregate logs in one record
        record = {'first_check_state': 0,
                  'day_ts': 0,
                  'hostname': elt.host_name,
                  'service': '',
                  'first_check_timestamp': None,
                  'last_check_timestamp': None,
                  'is_downtime': 0,
                  'day': '',
                  'last_check_state': 0,
                  'daily_0': 0,
                  'daily_1': 0,
                  'daily_2': 0,
                  'daily_3': 0,
                  'daily_4': 0}

        for log in records:
            record['daily_0'] += log['daily_0']
            record['daily_1'] += log['daily_1']
            record['daily_2'] += log['daily_2']
            record['daily_3'] += log['daily_3']
            record['daily_4'] += log['daily_4']
            if log['last_check_timestamp'] > record['last_check_timestamp'] or \
                    record['last_check_timestamp'] is None:
                record['last_check_timestamp'] = log['last_check_timestamp']
                record['last_check_state'] = log['last_check_state']
            if log['first_check_timestamp'] < record['first_check_timestamp'] or \
                    record['first_check_timestamp'] is None:
                record['first_check_timestamp'] = log['first_check_timestamp']
                record['first_check_state'] = log['first_check_state']

        return record
