#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright (C) 2009-2014:
#   Gabes Jean, naparuba@gmail.com
#   Gerhard Lausser, Gerhard.Lausser@consol.de
#   Gregory Starck, g.starck@gmail.com
#   Hartmut Goebel, h.goebel@goebel-consult.de
#   Frederic Mohier, frederic.mohier@gmail.com
#   Guillaume Subiron, maethor@subiron.org
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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Shinken.  If not, see <http://www.gnu.org/licenses/>.


"""
This Class is a plugin for the Shinken Broker. It is in charge
to get broks and recreate real objects, and propose a Web User Interface :)
"""

WEBUI_VERSION = "2.7.2"
WEBUI_COPYRIGHT = "2009-2018"
WEBUI_LICENSE = "License GNU AGPL as published by the FSF, minimum version 3 of the License."

import os
import json
import string
import random
import traceback
import sys
import time
import threading
import imp
import logging
import requests

from collections import deque

try:
    from setproctitle import setproctitle
except ImportError as err:
    setproctitle = lambda s: None

# Check if Alignak is installed
# An environment variable must be set when this UI module is to be used with Alignak
# This variable must contain a value different from 0
ALIGNAK = False
if os.environ.get('ALIGNAK_SHINKEN_UI', None):
    if os.environ.get('ALIGNAK_SHINKEN_UI') not in ['0']:
        ALIGNAK = True

# Shinken logger configuration
from shinken.log import BrokHandler, ColorStreamHandler, logger, defaultFormatter_named, humanFormatter_named
from shinken.log import TimedRotatingFileHandler

# Alignak / Shinken base module are slightly different
if ALIGNAK:
    from alignak.basemodule import BaseModule
else:
    from shinken.basemodule import BaseModule

# Regenerate objects from the received broks
from regenerator import Regenerator

from shinken.modulesctx import modulesctx
from shinken.modulesmanager import ModulesManager
from shinken.daemon import Daemon
from shinken.util import to_bool

# Bottle import
from bottle import route, request, response, template
import bottle

# Local import
from datamanager import WebUIDataManager
from ui_user import User
from helper import helper

# Sub modules
from submodules.prefs import PrefsMetaModule
from submodules.auth import AuthMetaModule
from submodules.logs import LogsMetaModule
from submodules.graphs import GraphsMetaModule
from submodules.helpdesk import HelpdeskMetaModule

# WebUI application
root_app = bottle.default_app()
webui_app = bottle.Bottle()

# Debug
SHINKEN_UI_DEBUG = False
if os.environ.get('SHINKEN_UI_DEBUG', None):
    SHINKEN_UI_DEBUG = True
    bottle.debug(True)

# Look at the webui module root dir too
webuimod_dir = os.path.abspath(os.path.dirname(__file__))
htdocs_dir = os.path.join(webuimod_dir, 'htdocs')

bottle.TEMPLATE_PATH.append(os.path.join(webuimod_dir, 'views'))
bottle.TEMPLATE_PATH.append(webuimod_dir)

properties = {
    'daemons': ['broker', 'scheduler'],
    'type': 'webui2',
    'phases': ['running'],
    'external': True
}


# called by the plugin manager to get an instance
def get_instance(plugin):
    # Only add template if we CALL webui
    logger.info("[WebUI] Webui_broker directory: %s", webuimod_dir)

    logger.info("[WebUI] configuration: %s", plugin.__dict__)
    instance = Webui_broker(plugin)
    logger.info("[WebUI] got an instance of Webui_broker for module: %s", plugin.get_name())
    return instance


# Read auth_secret from conf or file, if one exists, or autogenerate one
def resolve_auth_secret(modconf):
    candidate = getattr(modconf, 'auth_secret', None)
    if not candidate:
        # Look for file
        auth_secret_file = getattr(modconf, 'auth_secret_file', '/var/lib/shinken/auth_secret')
        if os.path.exists(auth_secret_file):
            with open(auth_secret_file) as secret:
                candidate = secret.read()
        else:
            # Autogenerate a secret
            chars = string.ascii_letters + string.digits
            candidate = ''.join([random.choice(chars) for _ in range(32)])
            try:
                with os.fdopen(os.open(auth_secret_file, os.O_WRONLY | os.O_CREAT, 0o600), 'w') as secret:
                    secret.write(candidate)
            except Exception as e:
                logger.error(
                    "[WebUI] Authentication secret file creation failed: %s, error: %s",
                    auth_secret_file, str(e)
                )
    return candidate


# Class for the WebUI Broker
class Webui_broker(BaseModule, Daemon):
    def __init__(self, modconf):
        BaseModule.__init__(self, modconf)

        if SHINKEN_UI_DEBUG:
            logger.warning("Using Bottle Web framework in debug mode.")

        # For Alignak ModulesManager...
        # ---
        self.alignak = False
        if ALIGNAK:
            self.alignak = True
            # A daemon must have these properties
            self.type = 'webui'
            self.name = 'webui'

            # Configure Alignak Arbiter API endpoint
            self.alignak_endpoint = getattr(modconf, 'alignak_endpoint', 'http://127.0.0.1:7770')
            self.alignak_check_period = int(getattr(modconf, 'alignak_check_period', '10'))
            self.alignak_livestate = {}
            self.alignak_events_count = int(getattr(modconf, 'alignak_events_count', '1000'))
            self.alignak_events = deque(maxlen=int(os.environ.get('ALIGNAK_EVENTS_LOG_COUNT',
                                                                 self.alignak_events_count)))

            # Shinken logger configuration
            log_console = (getattr(modconf, 'log_console', '0') == '1')
            if not log_console:
                # Remove the forced color log handler
                for hdlr in logger.handlers:
                    if isinstance(hdlr, ColorStreamHandler):
                        logger.removeHandler(hdlr)

            log_level = getattr(modconf, 'log_level', 'INFO')
            log_file = getattr(modconf, 'log_file', '/var/log/alignak/shinken-webui.log')
            logger.register_local_log(log_file, log_level)
            logger.set_human_format()
            logger.setLevel(log_level)

            # I may have some modules in my configuration or not...
            self.module_type = getattr(modconf, 'module_type', 'unset')
            self.module_name = getattr(modconf, 'module_name', 'unset')
            self.modules = getattr(modconf, 'modules', [])
            if self.modules and not self.modules[0]:
                self.modules = []
            # todo: set default directory for the modules directory
            self.modules_dir = getattr(modconf, 'modules_dir', '/var/lib/shinken/modules')
            logger.info("[WebUI] modules: %s in %s", self.modules, self.modules_dir)
        else:
            # Shinken logger configuration dedicated for the webUI
            log_file = getattr(modconf, 'log_file', None)
            if log_file:
                log_level = getattr(modconf, 'log_level', 'INFO')
                log_human_date = (getattr(modconf, 'log_human_date', '0') == '1')
                log_backup_count = int(getattr(modconf, 'log_backup_count', '7'))
                logger.info("[WebUI] dedicated logger, level %s in %s", log_level, log_file)

                # Store the former configured log level
                former_log_level = logger.level
                log_level = getattr(logging, log_level, None)
                logger.level = log_level

                for handler in logger.handlers:
                    if isinstance(handler, BrokHandler):
                        continue
                    handler.setLevel(former_log_level)

                # Create and set-up a new handler
                handler = TimedRotatingFileHandler(log_file, 'midnight', backupCount=log_backup_count)
                handler.setLevel(log_level)
                handler.setFormatter(defaultFormatter_named)
                if log_human_date:
                    handler.setFormatter(humanFormatter_named)
                logger.addHandler(handler)

                logger.debug("--/-- former log level: %s / new: %s", former_log_level, log_level)
                for handler in logger.handlers:
                    logger.debug("Handler: %s", handler.__dict__)
        # ---

        self.plugins = []
        self.modconf = modconf

        # Web server configuration
        self.host = getattr(modconf, 'host', '0.0.0.0')
        self.port = int(getattr(modconf, 'port', '7767'))
        logger.info("[WebUI] server: %s:%d", self.host, self.port)
        # todo: remove this feature from source code!
        self.endpoint = getattr(modconf, 'endpoint', None)
        if self.endpoint:
            if self.endpoint.endswith('/'):
                self.endpoint = self.endpoint[:-1]
            logger.info("[WebUI] configured endpoint: %s", self.endpoint)
            logger.warning("[WebUI] endpoint feature is not implemented! "
                           "WebUI is served from root URL: http://%s:%d/", self.host, self.port)
            self.endpoint = None

        # Build session cookie
        self.session_cookie = getattr(modconf, 'cookie_name', 'user')
        self.auth_secret = resolve_auth_secret(modconf)
        logger.info("[WebUI] cookie: %s", self.session_cookie)
        # TODO : common preferences
        self.play_sound = to_bool(getattr(modconf, 'play_sound', '0'))
        # TODO : common preferences
        self.login_text = getattr(modconf, 'login_text', None)
        # TODO : common preferences
        self.company_logo = getattr(modconf, 'company_logo', 'undefined')
        if not self.company_logo:
            # Set a dummy value if value defined in the configuration is empty to force using the default logo ...
            self.company_logo = 'undefined'
        # TODO : common preferences
        self.gravatar = to_bool(getattr(modconf, 'gravatar', '0'))
        # TODO : common preferences
        self.allow_html_output = to_bool(getattr(modconf, 'allow_html_output', '0'))
        # TODO : common preferences
        # self.max_output_length = int(getattr(modconf, 'max_output_length', '100'))
        # TODO : common preferences
        self.refresh_period = int(getattr(modconf, 'refresh_period', '60'))
        self.refresh = False if self.refresh_period == 0 else True
        # Use element tag as image or use text
        self.tag_as_image = to_bool(getattr(modconf, 'tag_as_image', '0'))

        # Manage user's ACL
        self.manage_acl = to_bool(getattr(modconf, 'manage_acl', '1'))
        self.allow_anonymous = to_bool(getattr(modconf, 'allow_anonymous', '0'))

        # Allow to customize default downtime duration
        self.default_downtime_hours = int(getattr(modconf, 'default_downtime_hours', '48'))
        self.shinken_downtime_fixed = int(getattr(modconf, 'shinken_downtime_fixed', '1'))
        self.shinken_downtime_trigger = int(getattr(modconf, 'shinken_downtime_trigger', '0'))
        self.shinken_downtime_duration = int(getattr(modconf, 'shinken_downtime_duration', '0'))

        # Allow to customize default acknowledge parameters
        self.default_ack_sticky = int(getattr(modconf, 'default_ack_sticky', '2'))
        self.default_ack_notify = int(getattr(modconf, 'default_ack_notify', '1'))
        self.default_ack_persistent = int(getattr(modconf, 'default_ack_persistent', '1'))

        # MongoDB connection
        self.uri = getattr(modconf, "uri", "mongodb://localhost")
        if not self.uri:
            logger.warning("You defined an empty MongoDB connection URI. Features like user's preferences, or system"
                           "log and hosts availability will not be available.")

        # Advanced options
        self.http_backend = getattr(modconf, 'http_backend', 'auto')
        self.remote_user_enable = getattr(modconf, 'remote_user_enable', '0')
        self.remote_user_variable = getattr(modconf, 'remote_user_variable', 'X_REMOTE_USER')
        self.serveropts = {}
        umask = getattr(modconf, 'umask', None)
        if umask is not None:
            self.serveropts['umask'] = int(umask)
        bindAddress = getattr(modconf, 'bindAddress', None)
        if bindAddress:
            self.serveropts['bindAddress'] = str(bindAddress)

        # Apache htpasswd file for authentication
        self.htpasswd_file = getattr(modconf, 'htpasswd_file', None)
        if self.htpasswd_file:
            if not os.path.exists(self.htpasswd_file):
                logger.warning("[WebUI] htpasswd file '%s' does not exist.", self.htpasswd_file)
                self.htpasswd_file = None

        # Load the config dir and make it an absolute path
        self.config_dir = getattr(modconf, 'config_dir', 'share')
        self.config_dir = os.path.abspath(self.config_dir)
        logger.info("[WebUI] Config dir: %s", self.config_dir)

        # Load the share dir and make it an absolute path
        self.share_dir = getattr(modconf, 'share_dir', 'share')
        self.share_dir = os.path.abspath(self.share_dir)
        logger.info("[WebUI] Share dir: %s", self.share_dir)

        # Load the photo dir and make it an absolute path
        self.photo_dir = getattr(modconf, 'photos_dir', 'photos')
        self.photo_dir = os.path.abspath(self.photo_dir)
        logger.info("[WebUI] Photo dir: %s", self.photo_dir)

        # User information
        self.user_session = None
        self.user_info = None

        # @mohierf: still useful ? No value in webui.cfg, so always False ...
        # self.embeded_graph = to_bool(getattr(modconf, 'embeded_graph', '0'))

        # Look for an additional pages dir
        self.additional_plugins_dir = getattr(modconf, 'additional_plugins_dir', '')
        if self.additional_plugins_dir:
            self.additional_plugins_dir = os.path.abspath(self.additional_plugins_dir)
        logger.info("[WebUI] Additional plugins dir: %s", self.additional_plugins_dir)

        # Web UI timezone
        self.timezone = getattr(modconf, 'timezone', 'Europe/Paris')
        if self.timezone:
            logger.info("[WebUI] Setting our timezone to %s", self.timezone)
            os.environ['TZ'] = self.timezone
            time.tzset()
        logger.info("[WebUI] parameter timezone: %s", self.timezone)

        # Visual alerting thresholds
        # Used in the dashboard view to select background color for percentages
        self.hosts_states_warning = int(getattr(modconf, 'hosts_states_warning', '95'))
        self.hosts_states_critical = int(getattr(modconf, 'hosts_states_critical', '90'))
        self.services_states_warning = int(getattr(modconf, 'services_states_warning', '95'))
        self.services_states_critical = int(getattr(modconf, 'services_states_critical', '90'))

        # Web UI information
        self.app_version = getattr(modconf, 'about_version', WEBUI_VERSION)
        self.app_copyright = getattr(modconf, 'about_copyright', WEBUI_COPYRIGHT)
        self.app_license = WEBUI_LICENSE

        # We will save all widgets
        self.widgets = {}

        # We need our regenerator now (before main) so if we are in a scheduler,
        # rg will be able to skip some broks
        self.rg = Regenerator()

        # My bottle object ...
        self.bottle = bottle

        bottle.BaseTemplate.defaults['app'] = self
        bottle.BaseTemplate.defaults['alignak'] = ALIGNAK

    # Called by Broker so we can do init stuff
    def init(self):
        logger.info("[WebUI] Initializing ...")
        if ALIGNAK:
            logger.warning("Running the Web UI for the Alignak framework.")
        else:
            logger.warning("Running the Web UI for the Shinken framework.")

        self.rg.load_external_queue(self.from_q)
        return True

    # This is called only when we are in a scheduler
    # and just before we are started. So we can gain time, and
    # just load all scheduler objects without fear :) (we
    # will be in another process, so we will be able to hack objects
    # if need)
    def hook_pre_scheduler_mod_start(self, sched):
        self.rg.load_from_scheduler(sched)

    # In a scheduler we will have a filter of what we really want as a brok
    def want_brok(self, b):
        return self.rg.want_brok(b)

    # pylint: disable=global-statement
    def main(self, stand_alone=False):
        """
            Module main function
        """
        global ALIGNAK
        self.stand_alone = stand_alone
        if self.stand_alone:
            setproctitle(self.name)
        else:
            self.set_proctitle(self.name)

        # Modules management
        # ---
        # I used a large If/Else to avoid breaking the existing behavior but I am quite sure
        # that the Alignak branch code is fully compatible with Shinken. I prefer separating
        # to avoid too many testings...
        if not ALIGNAK:
            self.debug_output = []
            self.modules_dir = modulesctx.get_modulesdir()
            self.modules_manager = ModulesManager('webui', self.find_modules_path(), [])
            self.modules_manager.set_modules(self.modules)
            logger.info("[WebUI] modules %s", self.modules)

            # We can now output some previously silenced debug output
            self.do_load_modules()
            for inst in self.modules_manager.instances:
                f = getattr(inst, 'load', None)
                if f and callable(f):
                    f(self)
            for debug_log in self.debug_output:
                logger.debug("[WebUI] debug: %s", debug_log)
            del self.debug_output
            logger.info("[WebUI] loaded modules %s", self.modules)

        else:
            self.debug_output = []

            logger.info("[WebUI] configured modules %s", self.modules)
            self.modules_manager = ModulesManager('webui', self.find_modules_path(), [])
            self.modules_manager.set_modules(self.modules)
            # This function is loading all the installed 'webui' daemon modules...
            self.do_load_modules()
            logger.info("[WebUI] imported %d modules", len(self.modules_manager.imported_modules))

            for inst in self.modules_manager.instances:
                logger.info("[WebUI] loading %s", inst)
                f = getattr(inst, 'load', None)
                if f and callable(f):
                    logger.info("[WebUI] running module load function")
                    f(self)
            logger.info("[WebUI] loaded modules %s", self.modules)

            # We can now output some previously silenced debug output
            for debug_log in self.debug_output:
                logger.debug("[WebUI] debug: %s", debug_log)
            del self.debug_output

        # Check if the Bottle view dir really exist
        if not os.path.exists(bottle.TEMPLATE_PATH[0]):
            logger.error("[WebUI] The view path do not exist at %s", bottle.TEMPLATE_PATH)
            sys.exit(2)

        # Load internal sub modules
        self.auth_module = AuthMetaModule(AuthMetaModule.find_modules(
            self.modules_manager.get_internal_instances()), self)
        self.prefs_module = PrefsMetaModule(PrefsMetaModule.find_modules(
            self.modules_manager.get_internal_instances()), self)
        self.logs_module = LogsMetaModule(LogsMetaModule.find_modules(
            self.modules_manager.get_internal_instances()), self)
        self.graphs_module = GraphsMetaModule(GraphsMetaModule.find_modules(
            self.modules_manager.get_internal_instances()), self)
        self.helpdesk_module = HelpdeskMetaModule(HelpdeskMetaModule.find_modules(
            self.modules_manager.get_internal_instances()), self)

        # Data manager
        self.datamgr = WebUIDataManager(self.rg)
        self.helper = helper

        # Check directories
        # We check if the photo directory exists. If not, try to create it
        for dir in [self.share_dir, self.photo_dir, self.config_dir]:
            logger.debug("[WebUI] Checking dir: %s", dir)
            if not os.path.exists(dir):
                try:
                    # os.mkdir(dir)
                    os.makedirs(dir, mode=0o777)
                    logger.info("[WebUI] Created directory: %s", dir)
                except Exception as e:
                    logger.error("[WebUI] Directory creation failed: %s, error: %s", dir, str(e))
            else:
                logger.debug("[WebUI] Still existing directory: %s", dir)

        # Bottle objects
        self.request = bottle.request
        self.response = bottle.response

        try:
            # I register my exit function
            self.set_exit_handler()

            # Set our current installation path to the Python Path
            # This will allow to resolve some tricky importation ;)
            sys.path.append(os.path.abspath(os.path.dirname(__file__)))

            # First load the additional plugins so they will have the lead on URI routes
            if self.additional_plugins_dir:
                self.load_plugins(self.additional_plugins_dir)

            # Modules can also override some views if need
            for inst in self.modules_manager.instances:
                f = getattr(inst, 'get_webui_plugins_path', None)
                if f and callable(f):
                    mod_plugins_path = os.path.abspath(f(self))
                    self.load_plugins(mod_plugins_path)

            # Then look at the plugins into core and load all we can there
            core_plugin_dir = os.path.join(os.path.abspath(os.path.dirname(__file__)), 'plugins')
            self.load_plugins(core_plugin_dir)

            # Declare the whole app static files AFTER the plugin ones
            self.declare_common_static()

            logger.info("[WebUI] declared routes:")
            for route in webui_app.routes:
                logger.debug("[WebUI] - %s", route.__dict__)
                if route.name:
                    if route.config:
                        logger.info("[WebUI] - %s for %s, configuration: %s", route.name, route.rule, route.config)
                    else:
                        logger.info("[WebUI] - %s for %s", route.name, route.rule)

            # We will protect the operations on
            # the non read+write with a lock and
            # 2 int
            self.global_lock = threading.RLock()
            self.nb_readers = 0
            self.nb_writers = 0

            self.data_thread = None
            self.ls_thread = None

            # Launch the data thread ...
            self.data_thread = threading.Thread(None, self.manage_brok_thread, 'datathread')
            self.data_thread.start()
            # TODO: look for alive and killing

            # Launch the Alignak arbiter data thread ...
            if self.alignak and self.alignak_endpoint:
                self.fmwk_thread = threading.Thread(None, self.fmwk_thread, 'fmwk_hread')
                self.fmwk_thread.start()

            logger.info("[WebUI] starting Web UI server on %s:%d ...", self.host, self.port)
            bottle.TEMPLATES.clear()
            webui_app.run(host=self.host, port=self.port, server=self.http_backend, **self.serveropts)
        except Exception as e:
            logger.error("[WebUI] do_main exception: %s", str(e))
            logger.error("[WebUI] traceback: %s", traceback.format_exc())
            exit(1)

    # External commands
    # -----------------------------------------------------
    # pylint: disable=global-statement
    def push_external_command(self, e):
        """
            A plugin sends us an external command. Notify this command to the monitoring framework ...
        """
        global ALIGNAK
        logger.debug("[WebUI] Got an external command: %s", e.__dict__)
        if self.stand_alone:
            logger.warning("[WebUI] --------------------------------------------------")
            logger.warning("[WebUI] TODO: notify external command: %s", e.__dict__)
            logger.warning("[WebUI] --------------------------------------------------")
        else:
            if self.alignak:
                logger.info("Sending command to Alignak: %s", e)
                req = requests.Session()
                raw_data = req.get("%s/command" % self.alignak_endpoint,
                                   params={'command': e.cmd_line})
                logger.info("Result: %s", raw_data.content)
            else:
                try:
                    self.from_q.put(e)
                except Exception as exp:
                    logger.error("[WebUI] External command push, exception: %s", str(exp))

    # Shinken broker module only
    # -----------------------------------------------------
    # It will say if we can launch a page rendering or not.
    # We can only if there is no writer running from now
    def wait_for_no_writers(self):
        while True:
            self.global_lock.acquire()
            # We will be able to run
            if self.nb_writers == 0:
                # Ok, we can run, register us as readers
                self.nb_readers += 1
                self.global_lock.release()
                break
            # Oups, a writer is in progress. We must wait a bit
            self.global_lock.release()
            # Before checking again, we should wait a bit
            # like 1ms
            time.sleep(0.001)

    # Shinken broker module only
    # -----------------------------------------------------
    # It will say if we can launch a brok management or not
    # We can only if there is no readers running from now
    def wait_for_no_readers(self):
        start = time.time()
        while True:
            self.global_lock.acquire()
            # We will be able to run
            if self.nb_readers == 0:
                # Ok, we can run, register us as writers
                self.nb_writers += 1
                self.global_lock.release()
                break
            # Ok, we cannot run now, wait a bit
            self.global_lock.release()
            # Before checking again, we should wait a bit
            # like 1ms
            time.sleep(0.001)
            # We should warn if we cannot update broks
            # for more than 30s because it can be not good
            if time.time() - start > 30:
                logger.warning("[WebUI] wait_for_no_readers, we are in lock/read since more than 30s!")
                start = time.time()

    # Shinken broker module only
    # -----------------------------------------------------
    # We want a lock manager version of the plugin functions
    def lockable_function(self, f):
        def lock_version(**args):
            self.wait_for_no_writers()
            try:
                return f(**args)
            finally:
                # We can remove us as a reader from now. It's NOT an atomic operation
                # so we REALLY not need a lock here (yes, I try without and I got
                # a not so accurate value there....)
                self.global_lock.acquire()
                self.nb_readers -= 1
                self.global_lock.release()

        return lock_version

    # Shinken broker module only
    # -----------------------------------------------------
    # It's the thread function that will get broks and update data. Will lock the whole thing
    # while updating
    def manage_brok_thread(self):
        logger.debug("[WebUI] manage_brok_thread start ...")

        while not self.interrupted:
            start = time.clock()
            # Get messages in the queue
            try:
                message = self.to_q.get()
            except EOFError:
                # Broken queue ... the broker deleted the module queue
                time.sleep(1.0)
                continue
            except Exception as exp:
                logger.warning("Broken module queue: %s", str(exp))
                continue

            # try to relaunch dead module
            self.check_and_del_zombie_modules()

            if not message:
                continue

            logger.debug("[WebUI] manage_brok_thread got %d broks, queue length: %d",
                         len(message), self.to_q.qsize())
            for b in message:
                b.prepare()
                self.wait_for_no_readers()
                try:
                    self.rg.manage_brok(b)

                    # Question:
                    # Do not send broks to internal modules ...
                    # No internal WebUI modules have something to do with broks!
                    for mod in self.modules_manager.get_internal_instances():
                        try:
                            mod.manage_brok(b)
                        except Exception as exp:
                            logger.warning("[WebUI] The mod %s raise an exception: %s, "
                                           "I'm tagging it to restart later", mod.get_name(), str(exp))
                            logger.debug("[WebUI] Back trace of this kill: %s", traceback.format_exc())
                            self.modules_manager.set_to_restart(mod)
                except Exception as exp:
                    logger.error("[WebUI] manage_brok_thread exception: %s", str(exp))
                    logger.error("[WebUI] Exception type: %s", type(exp))
                    logger.error("[WebUI] Back trace of this kill: %s", traceback.format_exc())
                    # No need to raise here, we are in a thread, exit!
                    os._exit(2)
                finally:
                    # logger.debug("[WebUI] manage_brok_thread finally")
                    # We can remove us as a writer from now. It's NOT an atomic operation
                    # so we REALLY not need a lock here (yes, I try without and I got
                    # a not so accurate value there....)
                    self.global_lock.acquire()
                    self.nb_writers -= 1
                    self.global_lock.release()

            logger.debug("[WebUI] time to manage %d broks (time %.2gs)",
                         len(message), time.clock() - start)

        logger.debug("[WebUI] manage_brok_thread end ...")

    def fmwk_thread(self):
        """A thread function that periodically gets its state from the Alignak arbiter

        This function gets Alignak status in our alignak_livestate and
        then it gets the Alignak events in our alignak_events queue
        """
        logger.debug("[WebUI] fmwk_thread start ...")

        req = requests.Session()
        alignak_timestamp = 0
        while not self.interrupted:
            # Get Alignak status
            try:
                raw_data = req.get("%s/status" % self.alignak_endpoint)
                data = json.loads(raw_data.content)
                self.alignak_livestate = data.get('livestate', 'Unknown')
                logger.debug("[WebUI-fmwk_thread] Livestate: %s", data)
            except Exception as exp:
                logger.info("[WebUI-system] alignak_status, exception: %s", exp)

            try:
                # Get Alignak most recent events
                # count is the maximum number of events we will be able to get
                # timestamp is the most recent event we got
                raw_data = req.get("%s/events_log?details=1&count=%d&timestamp=%d"
                                   % (self.alignak_endpoint, self.alignak_events_count, alignak_timestamp))
                data = json.loads(raw_data.content)
                logger.debug("[WebUI-fmwk_thread] got %d event log", len(data))
                for log in data:
                    # Data contains: {
                    #   u'date': u'2018-11-24 16:28:03', u'timestamp': 1543073283.434844,
                    #   u'message': u'RETENTION LOAD: scheduler-master', u'level': u'info'
                    # }
                    alignak_timestamp = max(alignak_timestamp, log['timestamp'])
                    if log not in self.alignak_events:
                        logger.debug("[WebUI-fmwk_thread] New event log: %s", log)
                        self.alignak_events.appendleft(log)
                logger.debug("[WebUI-fmwk_thread] %d log events", len(self.alignak_events))
            except Exception as exp:
                logger.info("[WebUI-system] alignak_status, exception: %s", exp)

            # Sleep for a while...
            time.sleep(self.alignak_check_period)

        logger.debug("[WebUI] fmwk_thread end ...")

    # Here we will load all plugins (pages) under the webui/plugins
    # directory. Each one can have a page, views and htdocs dir that we must
    # route correctly
    def load_plugins(self, plugin_dir):
        logger.info("[WebUI] load plugins directory: %s", plugin_dir)

        # Load plugin directories
        if not os.path.exists(plugin_dir):
            logger.error("[WebUI] load plugins directory does not exist: %s", plugin_dir)
            return

        plugin_dirs = [fname for fname in os.listdir(plugin_dir)
                       if os.path.isdir(os.path.join(plugin_dir, fname))]

        # todo: Hmmm..... confirm it is necessary!
        # sys.path.append(plugin_dir)

        # Try to import all found plugins
        for fdir in plugin_dirs:
            self.load_plugin(fdir, plugin_dir)

    # Load a WebUI plugin
    def load_plugin(self, fdir, plugin_dir):
        logger.debug("[WebUI] loading plugin %s ...", fdir)
        try:
            # Put the full qualified path of the module we want to load
            # for example we will give  webui/plugins/eltdetail/
            mod_path = os.path.join(plugin_dir, fdir)
            # Then we load the plugin.py inside this directory
            m = imp.load_module(fdir, *imp.find_module(fdir, [mod_path]))
            m_dir = os.path.abspath(os.path.dirname(m.__file__))

            # todo: Hmmm..... confirm it is necessary!
            # sys.path.append(m_dir)

            for (f, entry) in m.pages.items():
                logger.debug("[WebUI] entry: %s", entry)
                # IMPORTANT: apply VIEW BEFORE route!
                view = entry.get('view', None)
                if view:
                    f = bottle.view(view)(f)

                # Maybe there is no route to link, so pass
                route = entry.get('route', None)
                name = entry.get('name', None)
                search_engine = entry.get('search_engine', False)
                if route:
                    method = entry.get('method', 'GET')

                    # Ok, we will just use the lock for all
                    # plugin page, but not for static objects
                    # so we set the lock at the function level.
                    f = webui_app.route(route, callback=self.lockable_function(f),
                                        method=method, name=name, search_engine=search_engine)

                # If the plugin declare a static entry, register it
                # and remember: really static! because there is no lock
                # for them!
                static = entry.get('static', False)
                if static:
                    self.add_static_route(fdir, m_dir)

                # It's a valid widget entry if it got all data, and at least one route
                # ONLY the first route will be used for Add!
                widget_lst = entry.get('widget', [])
                widget_name = entry.get('widget_name', None)
                widget_desc = entry.get('widget_desc', widget_name)
                widget_alias = entry.get('widget_alias', widget_name)
                widget_picture = entry.get('widget_picture', None)
                deprecated = entry.get('deprecated', False)
                if widget_name and widget_lst and route:
                    for place in widget_lst:
                        if place not in self.widgets:
                            self.widgets[place] = []
                        self.widgets[place].append({
                            'widget_name': widget_name,
                            'widget_alias': widget_alias,
                            'widget_desc': widget_desc,
                            'base_uri': route,
                            'widget_picture': widget_picture,
                            'deprecated': deprecated
                        })

            # And we add the views dir of this plugin in our TEMPLATE
            # PATH
            logger.debug("[WebUI] plugin views dir: %s", os.path.join(m_dir, 'views'))
            bottle.TEMPLATE_PATH.append(os.path.join(m_dir, 'views'))

            # And finally register me so the pages can get data and other
            # useful stuff
            m.app = self

            # Load/set plugin configuration
            f = getattr(m, 'load_config', None)
            if f and callable(f):
                logger.debug("[WebUI] calling plugin %s, load configuration", fdir)
                f(self)

            logger.info("[WebUI] loaded plugin %s", fdir)

        except Exception as exp:
            logger.error("[WebUI] loading plugin %s, exception: %s", fdir, str(exp))

    # Get URL for a named route
    def get_url(self, name):
        logger.debug("[WebUI] get_url for '%s'", name)

        try:
            if self.endpoint:
                logger.debug("[WebUI] get_url, url name: %s, route: %s -> %s",
                             name, webui_app.get_url(name), ''.join([self.endpoint, webui_app.get_url(name)]))
                return ''.join([self.endpoint, webui_app.get_url(name)])
            return webui_app.get_url(name)
        except Exception as e:
            logger.error("[WebUI] get_url, exception: %s", str(e))

        return '/'

    # Add static route in the Web server
    # pylint: disable=no-self-use
    def add_static_route(self, fdir, m_dir):
        logger.debug("[WebUI] add static route: %s", fdir)
        static_route = '/static/' + fdir + '/:path#.+#'

        def plugin_static(path):
            return bottle.static_file(path, root=os.path.join(m_dir, 'htdocs'))
        webui_app.route(static_route, callback=plugin_static)

    # Common static routes
    def declare_common_static(self):
        @webui_app.route('/static/photos/:path#.+#')
        def give_photo(path):
            # If the file really exist, give it. If not, give a dummy image.
            if os.path.exists(os.path.join(self.photo_dir, path + '.png')):
                return bottle.static_file(path + '.png', root=self.photo_dir)

            return bottle.static_file('images/default_user.png', root=htdocs_dir)

        @webui_app.route('/static/logo/:path#.+#')
        def give_logo(path):
            """
            Returns the configured company logo if it exists, else
            it returns the logo according to the Shinken/Alignak framework configuration

            The company logo must be a png file located in the configured `photos_dir`
            :return:
            """
            # If the file really exist, give it. If not, give a dummy image.
            if os.path.exists(os.path.join(self.photo_dir, path + '.png')):
                return bottle.static_file(path + '.png', root=self.photo_dir)

            if ALIGNAK:
                return bottle.static_file('images/logos/logo_alignak.png', root=htdocs_dir)

            return bottle.static_file('images/logos/logo_shinken.png', root=htdocs_dir)

        @webui_app.route('/tag/:path#.+#')
        def give_tag(path):
            # TODO: Should be more logical to locate tags images in tags directory !
            # tag_path = "/images/tags/%s" % path
            # BUT: implies modifications in all Shinken packages ...

            # If a tag image (tag.png) exists in the share dir, give it ...
            tag_path = "%s/images/sets/%s" % (self.share_dir, path)
            logger.debug("[WebUI] searching tag: %s", os.path.join(tag_path, 'tag.png'))
            if os.path.exists(os.path.join(tag_path, 'tag.png')):
                return bottle.static_file('tag.png', root=tag_path)

            # Default tags icons are located in images/tags directory ...
            tag_path = "%s/images/tags/%s" % (htdocs_dir, path)
            logger.debug("[WebUI] searching for: %s", os.path.join(tag_path, 'tag.png'))
            if os.path.exists(os.path.join(tag_path, 'tag.png')):
                return bottle.static_file('tag.png', root=tag_path)

            return bottle.static_file('images/default_tag.png', root=htdocs_dir)

        # Route static files css files
        @webui_app.route('/static/:path#.+#')
        def server_static(path):
            # By default give from the root in bottle_dir/htdocs. If the file is missing,
            # search in the share dir
            # TODO: should be more logical to search in share_dir first ?
            root = htdocs_dir
            p = os.path.join(root, path)
            if not os.path.exists(p):
                root = self.share_dir
            return bottle.static_file(path, root=root)

        @webui_app.route('/favicon.ico')
        def give_favicon():
            """
            Returns the favicon patha according to the Shinken/Alignak framework configuration
            :return:
            """
            if ALIGNAK:
                return bottle.static_file('alignak.ico', root=os.path.join(htdocs_dir, 'images/logos'))

            return bottle.static_file('shinken.ico', root=os.path.join(htdocs_dir, 'images/logos'))

        # And add the opensearch xml
        @webui_app.route('/opensearch.xml')
        def give_opensearch():
            base_url = self.request.url.replace('opensearch.xml', '')
            response.headers['Content-Type'] = 'text/xml'
            return bottle.template('opensearch', base_url=base_url)

        @webui_app.route('/modal/:path#.+#')
        def give_modal(path):
            logger.debug("[WebUI] get modal window content: %s", path)
            return bottle.template('modal_' + path)

    ##
    # Check if provided username/password is accepted for login the Web UI
    #
    # Several steps:
    # 1/ one of the WebUI modules providing a 'check_auth' method must authenticate the user
    # 2/ username must be in the known contacts of Shinken
    ##
    # :TODO:maethor:150727: Remove this method - @mohierf: why?
    def check_authentication(self, username, password):
        logger.info("[WebUI] Checking authentication for user: %s", username)
        self.user_session = None
        self.user_info = None

        logger.info("[WebUI] Requesting authentication for user: %s", username)
        user = self.auth_module.check_auth(username, password)
        if user:
            # logger.info("[WebUI] user authenticated through %s", self.auth_module._authenticator)
            # Check existing contact ...
            c = self.datamgr.get_contact(name=username)
            if not c:
                logger.error("[WebUI] You need to have a contact having the same name as your user: %s", username)
                return False

            user = User.from_contact(c)

            self.user_session = self.auth_module.get_session()
            logger.info("[WebUI] User session: %s", self.user_session)
            self.user_info = self.auth_module.get_user_info()
            logger.info("[WebUI] User information: %s", self.user_info)

            return True

        logger.warning("[WebUI] The user '%s' has not been authenticated.", username)
        return False

    ##
    # For compatibility with previous defined views ...
    ##
    # pylint: disable=undefined-variable
    def get_user_auth(self):
        logger.warning("[WebUI] Deprecated - Getting authenticated user ...")
        self.user_session = None
        self.user_info = None

        cookie_value = webui_app.request.get_cookie(str(app.session_cookie), secret=app.auth_secret)
        if cookie_value:
            if 'session' in cookie_value:
                self.user_session = cookie_value['session']
                logger.debug("[WebUI] user session: %s", cookie_value['session'])
            if 'info' in cookie_value:
                self.user_info = cookie_value['info']
                logger.debug("[WebUI] user info: %s", cookie_value['info'])
            if 'login' in cookie_value:
                logger.debug("[WebUI] user login: %s", cookie_value['login'])
                contact = app.datamgr.get_contact(name=cookie_value['login'])
            else:
                contact = app.datamgr.get_contact(name=cookie_value)
        else:
            contact = app.datamgr.get_contact(name='anonymous')
        if not contact:
            return None

        user = User.from_contact(contact)
        return user

    ##
    # Current user can launch commands ?
    # If username is provided, check for the specified user ...
    ##
    def can_action(self, username=None):
        if username:
            user = User.from_contact(self.datamgr.get_contact(name=username))
        else:
            user = request.environ.get('USER', None)

        try:
            retval = user and ((not self.manage_acl) or user.is_administrator() or user.is_commands_allowed())
        except Exception:
            retval = False
        return retval

    # TODO : move this function to dashboard plugin
    # For a specific place like dashboard we return widget lists
    def get_widgets_for(self, place):
        return self.widgets.get(place, [])

    ##
    # External UI links for other modules
    # ------------------------------------------------------------------------------------------
    # Web UI modules may implement a 'get_external_ui_link' function to provide an extra menu
    # in the Web UI. This function must return:
    # {'label': 'Menu item', 'uri': 'http://...'}
    ##
    def get_ui_external_links(self):
        logger.debug("[WebUI] Fetching UI external links ...")

        lst = []
        for mod in self.modules_manager.get_internal_instances():
            try:
                f = getattr(mod, 'get_external_ui_link', None)
                if f and callable(f):
                    lst.append(f())
            except Exception as exp:
                logger.warning("[WebUI] Warning: The mod %s raise an exception: %s, "
                               "I'm tagging it to restart later", mod.get_name(), str(exp))
                logger.debug("[WebUI] Exception type: %s", type(exp))
                logger.debug("Back trace of this kill: %s", traceback.format_exc())
                self.modules_manager.set_to_restart(mod)

        return lst

    def get_search_string(self, default=""):
        return self.request.query.get('search', default)

    def redirect404(self, msg="Not found"):
        raise self.bottle.HTTPError(404, msg)

    def redirect403(self, msg="Forbidden"):
        raise self.bottle.HTTPError(403, msg)

    # pylint: disable=no-self-use
    def get_user(self):
        return request.environ['USER']


@webui_app.hook('before_request')
def login_required():
    # :COMMENT:maethor:150718: This hack is crazy, but I don't know how to do it properly
    app = bottle.BaseTemplate.defaults['app']

    logger.debug("[WebUI] login_required, requested URL: %s", request.urlparts.path)
    if request.urlparts.path == "/user/logout" or request.urlparts.path == app.get_url("Logout"):
        return
    if request.urlparts.path == "/user/login" or request.urlparts.path == app.get_url("GetLogin"):
        return
    if request.urlparts.path == "/user/auth" or request.urlparts.path == app.get_url("SetLogin"):
        return
    if request.urlparts.path.startswith('/static'):
        return

    logger.debug("[WebUI] login_required, getting user cookie ...")
    cookie_value = bottle.request.get_cookie(str(app.session_cookie), secret=app.auth_secret)
    if not cookie_value and not app.allow_anonymous:
        bottle.redirect('/user/login')
    if cookie_value:
        if 'session' in cookie_value:
            app.user_session = cookie_value['session']
            logger.debug("[WebUI] user session: %s", cookie_value['session'])
        if 'info' in cookie_value:
            app.user_info = cookie_value['info']
            logger.debug("[WebUI] user info: %s", cookie_value['info'])
        if 'login' in cookie_value:
            logger.debug("[WebUI] user login: %s", cookie_value['login'])
            contact = app.datamgr.get_contact(name=cookie_value['login'])
        else:
            contact = app.datamgr.get_contact(name=cookie_value)
    else:
        # Only the /dashboard/currently should be accessible to anonymous users
        if request.urlparts.path != "/dashboard/currently":
            bottle.redirect("/user/login")
        contact = app.datamgr.get_contact(name='anonymous')

    if not contact:
        app.redirect403()
        bottle.redirect('/user/login')

    user = User.from_contact(contact)
    if app.user_session and app.user_info:
        user.set_information(app.user_session, app.user_info)
    app.datamgr.set_logged_in_user(user)

    logger.debug("[WebUI] update current user: %s", user)
    request.environ['USER'] = user
