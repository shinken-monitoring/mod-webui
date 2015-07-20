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


WEBUI_VERSION = "2.0 alpha"
WEBUI_COPYRIGHT = "(c) 2009-2015 - License GNU AGPL as published by the FSF, minimum version 3 of the License."
WEBUI_RELEASENOTES = "Bootstrap 3 User Interface"


"""
This Class is a plugin for the Shinken Broker. It is in charge
to get brok and recreate real objects, and propose a Web interface :)
"""

import traceback
import sys
import os
import time
import threading
import imp
import json

from shinken.basemodule import BaseModule
from shinken.message import Message
from shinken.misc.regenerator import Regenerator
# from webui_regenerator import WebUIRegenerator
from shinken.log import logger
from shinken.modulesctx import modulesctx
from shinken.modulesmanager import ModulesManager
from shinken.daemon import Daemon
from shinken.util import to_bool

# Local import
from lib.bottle import run, static_file, view, route, request, response, template
import lib.bottle as bottle
from datamanager import WebUIDataManager
from user import User
from helper import helper

# Debug
bottle.debug(True)

# Import bottle lib to make bottle happy
bottle_dir = os.path.abspath(os.path.dirname(bottle.__file__))
sys.path.insert(0, bottle_dir)

# Look at the webui module root dir too
webuimod_dir = os.path.abspath(os.path.dirname(__file__))
htdocs_dir = os.path.join(webuimod_dir, 'htdocs')

properties = {
    'daemons': ['broker', 'scheduler'],
    'type': 'webui',
    'phases': ['running'],
    'external': True}


# called by the plugin manager to get an instance
def get_instance(plugin):
    # Only add template if we CALL webui
    bottle.TEMPLATE_PATH.append(os.path.join(webuimod_dir, 'views'))
    bottle.TEMPLATE_PATH.append(webuimod_dir)

    instance = Webui_broker(plugin)
    logger.info("[WebUI] got an instance for plugin: %s", plugin.get_name())
    return instance


# Class for the WebUI Broker
class Webui_broker(BaseModule, Daemon):
    def __init__(self, modconf):
        BaseModule.__init__(self, modconf)

        self.plugins = []

        # Web server configuration
        self.host = getattr(modconf, 'host', '0.0.0.0')
        self.port = int(getattr(modconf, 'port', '7767'))
        self.auth_secret = getattr(modconf, 'auth_secret', 'secret').encode('utf8', 'replace')

        # TODO : common preferences
        self.play_sound = to_bool(getattr(modconf, 'play_sound', '0'))
        # TODO : common preferences
        self.login_text = getattr(modconf, 'login_text', None)
        # TODO : common preferences
        self.company_logo = getattr(modconf, 'company_logo', 'default_company')
        if self.company_logo == '':
            # Set a dummy value if webui.cfg value is empty to force using the default logo ...
            self.company_logo = 'abcdef'
        # TODO : common preferences
        self.gravatar = to_bool(getattr(modconf, 'gravatar', '0'))
        # TODO : common preferences
        self.allow_html_output = to_bool(getattr(modconf, 'allow_html_output', '0'))
        # TODO : common preferences
        self.max_output_length = int(getattr(modconf, 'max_output_length', '100'))
        # TODO : common preferences
        self.refresh_period = int(getattr(modconf, 'refresh_period', '60'))
        # Use element tag as image or use text
        self.tag_as_image = bool(getattr(modconf, 'tag_as_image', False))

        # Manage user's ACL
        self.manage_acl = to_bool(getattr(modconf, 'manage_acl', '1'))
        self.allow_anonymous = to_bool(getattr(modconf, 'allow_anonymous', '0'))

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

        self.user_picture = ''

        self.embeded_graph = to_bool(getattr(modconf, 'embeded_graph', '0'))

        # Look for an additional pages dir
        self.additional_plugins_dir = getattr(modconf, 'additional_plugins_dir', '')
        if self.additional_plugins_dir:
            self.additional_plugins_dir = os.path.abspath(self.additional_plugins_dir)

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
        self.app_release = getattr(modconf, 'about_release', WEBUI_RELEASENOTES)

        # We will save all widgets
        self.widgets = {}

        # We need our regenerator now (before main) so if we are in a scheduler,
        # rg will be able to skip some broks
        # self.rg = WebUIRegenerator()
        self.rg = Regenerator()

        # Mu bottle object ...
        self.bottle = bottle

        bottle.BaseTemplate.defaults['app'] = self

    # Called by Broker so we can do init stuff
    def init(self):
        logger.info("[WebUI] Initializing ...")
        self.rg.load_external_queue(self.from_q)

    # This is called only when we are in a scheduler
    # and just before we are started. So we can gain time, and
    # just load all scheduler objects without fear :) (we
    # will be in another process, so we will be able to hack objects
    # if need)
    def hook_pre_scheduler_mod_start(self, sched):
        print "pre_scheduler_mod_start::", sched.__dict__
        self.rg.load_from_scheduler(sched)

    # In a scheduler we will have a filter of what we really want as a brok
    def want_brok(self, b):
        return self.rg.want_brok(b)

    def main(self):
        self.set_proctitle(self.name)

        # self.log = logger
        # self.log.load_obj(self)

        # Daemon like init
        self.debug_output = []
        self.modules_dir = modulesctx.get_modulesdir()
        self.modules_manager = ModulesManager('webui', self.find_modules_path(), [])
        self.modules_manager.set_modules(self.modules)
        # We can now output some previously silenced debug output
        self.do_load_modules()
        for inst in self.modules_manager.instances:
            f = getattr(inst, 'load', None)
            if f and callable(f):
                f(self)
        for s in self.debug_output:
            print s
        del self.debug_output

        # Check if the Bottle view dir really exist
        if not os.path.exists(bottle.TEMPLATE_PATH[0]):
            logger.error("[WebUI] The view path do not exist at %s" % bottle.TEMPLATE_PATH)
            sys.exit(2)

        # Check directories
        # We check if the photo directory exists. If not, try to create it
        logger.debug("[WebUI] Checking photo dir: %s", self.photo_dir)
        if not os.path.exists(self.photo_dir):
            try:
                os.mkdir(self.photo_dir)
                logger.info("[WebUI] Created photo dir: %s", self.photo_dir)
            except Exception, exp:
                logger.error("[WebUI] Photo dir creation failed: %s", exp)

        # We check if the share directory exists. If not, try to create it
        logger.debug("[WebUI] Checking share dir: %s", self.share_dir)
        if not os.path.exists(self.share_dir):
            try:
                os.mkdir(self.share_dir)
                logger.info("[WebUI] Created share dir: %s", self.share_dir)
            except Exception, exp:
                logger.error("[WebUI] Share dir creation failed: %s", exp)

        # We check if the config directory exists. If not, try to create it
        logger.debug("[WebUI] Checking config dir: %s", self.config_dir)
        if not os.path.exists(self.config_dir):
            try:
                os.mkdir(self.config_dir)
                logger.info("[WebUI] Created config dir: %s", self.config_dir)
            except Exception, exp:
                logger.error("[WebUI] Config dir creation failed: %s", exp)

        # We check if we have an user authentication module
        if not self.has_user_authentication_module():
            logger.error("[WebUI] No user authentication module configured. Please configure at least 'modules auth-cfg-password' in webui.cfg file")
            sys.exit(2)

        # We check if we have an availability module
        self.get_availability = None
        if not self.has_availability_module():
            logger.warning("[WebUI] No availability module configured. You should configure the module 'mongo-logs' in your broker and the module 'mongodb' in webui.cfg file to get hosts availability information.")

        # We check if we have an history module
        self.get_history = None
        if not self.has_history_module():
            logger.warning("[WebUI] No history module configured. You should configure the module 'mongo-logs' in your broker and the module 'mongodb' in webui.cfg file to get hosts history information.")

        # We check if we have an helpdesk module
        self.get_helpdesk = None
        if not self.has_helpdesk_module():
            logger.warning("[WebUI] No helpdesk module configured. You should configure the module 'glpi-tickets' in webui.cfg file to get helpdesk information.")

        # We check if we have an user preference module
        if not self.has_user_preference_module():
            logger.warning("[WebUI] No user preference module configured. Preferences will be stored in %s directory. Else, you may configure 'modules mongodb' or 'modules SQLitedb' in webui.cfg file", self.config_dir)

        # Data manager
        self.datamgr = WebUIDataManager(self.rg)
        self.helper = helper

        self.request = request
        self.response = response
        self.template_call = template

        # :TODO:maethor:150717: Doesn't work
        username = self.request.get_cookie("user", secret=self.auth_secret)
        if username:
            self.user = User.from_contact(self.datamgr.get_contact(username), self.gravatar)
        else:
            self.user = None

        try:
            self.do_main()
        except Exception, exp:
            msg = Message(id=0, type='ICrash', data={'name': self.get_name(), 'exception': exp, 'trace': traceback.format_exc()})
            self.from_q.put(msg)
            # wait 2 sec so we know that the broker got our message, and die
            time.sleep(2)
            raise

    # A plugin send us en external command. We just put it
    # in the good queue
    def push_external_command(self, e):
        logger.info("[WebUI] Got an external command: %s", e.__dict__)
        try:
            self.from_q.put(e)
        except Exception, exp:
            logger.error("[WebUI] External command push, exception: %s", str(exp))

    # Real main function
    def do_main(self):
        # I register my exit function
        self.set_exit_handler()

        # We will protect the operations on
        # the non read+write with a lock and
        # 2 int
        self.global_lock = threading.RLock()
        self.nb_readers = 0
        self.nb_writers = 0

        self.data_thread = None

        # First load the additional plugins so they will have the lead on
        # URI routes
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

        # Launch the data thread"
        self.data_thread = threading.Thread(None, self.manage_brok_thread, 'datathread')
        self.data_thread.start()
        # TODO: look for alive and killing

        # Ok, you want to know why we are using a data thread instead of
        # just call for a select with q._reader, the underlying file
        # handle of the Queue()? That's just because under Windows, select
        # only manage winsock (so network) file descriptor! What a shame!
        logger.info("[WebUI] starting Web UI server ...")
        run(host=self.host, port=self.port, server=self.http_backend, **self.serveropts)

        # ^ IMPORTANT ^
        # We are not managing the lock at this
        # level because we got 2 types of requests:
        # static images/css/js: no need for lock
        # pages: need it. So it's managed at a
        # function wrapper at loading pass

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
                print "WARNING: we are in lock/read since more than 30s!"
                start = time.time()

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

    # It's the thread function that will get broks
    # and update data. Will lock the whole thing
    # while updating
    def manage_brok_thread(self):
        logger.debug("[WebUI] manage_brok_thread start ...")

        while True:
            l = self.to_q.get()

            # try to relaunch dead module (like mongo one when mongo is not available at startup for example)
            self.check_and_del_zombie_modules()

            logger.debug("[WebUI] manage_brok_thread got %d broks", len(l))
            for b in l:
                b.prepare()
                self.wait_for_no_readers()
                try:
                    self.rg.manage_brok(b)

                    for mod in self.modules_manager.get_internal_instances():
                        try:
                            mod.manage_brok(b)
                        except Exception, exp:
                            logger.warning("[WebUI] The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                            logger.debug("[WebUI] Exception type: %s", self.name, type(exp))
                            logger.debug("[WebUI] Back trace of this kill: %s", traceback.format_exc())
                            self.modules_manager.set_to_restart(mod)
                except Exception, exp:
                    logger.error("[WebUI] manage_brok_thread exception")
                    msg = Message(id=0, type='ICrash', data={'name': self.get_name(), 'exception': exp, 'trace': traceback.format_exc()})
                    self.from_q.put(msg)
                    # wait 2 sec so we know that the broker got our message, and die
                    time.sleep(2)
                    # No need to raise here, we are in a thread, exit!
                    os._exit(2)
                finally:
                    logger.debug("[WebUI] manage_brok_thread finally")
                    # We can remove us as a writer from now. It's NOT an atomic operation
                    # so we REALLY not need a lock here (yes, I try without and I got
                    # a not so accurate value there....)
                    self.global_lock.acquire()
                    self.nb_writers -= 1
                    self.global_lock.release()

        logger.debug("[WebUI] manage_brok_thread end ...")

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

        sys.path.append(plugin_dir)

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
            # Then we load the eltdetail.py inside this directory
            m = imp.load_module('%s' % (fdir), *imp.find_module(fdir, [mod_path]))
            m_dir = os.path.abspath(os.path.dirname(m.__file__))
            sys.path.append(m_dir)

            pages = m.pages
            for (f, entry) in pages.items():
                routes = entry.get('routes', None)
                v = entry.get('view', None)
                static = entry.get('static', False)
                widget_lst = entry.get('widget', [])
                widget_desc = entry.get('widget_desc', None)
                widget_name = entry.get('widget_name', None)
                widget_picture = entry.get('widget_picture', None)

                # IMPORTANT: apply VIEW BEFORE route!
                if v:
                    f = view(v)(f)

                # Maybe there is no route to link, so pass
                if routes:
                    for r in routes:
                        method = entry.get('method', 'GET')

                        # Ok, we will just use the lock for all
                        # plugin page, but not for static objects
                        # so we set the lock at the function level.
                        lock_version = self.lockable_function(f)
                        f = route(r, callback=lock_version, method=method)

                # If the plugin declare a static entry, register it
                # and remember: really static! because there is no lock
                # for them!
                if static:
                    self.add_static_route(fdir, m_dir)

                # It's a valid widget entry if it got all data, and at least one route
                # ONLY the first route will be used for Add!
                if widget_name and widget_desc and widget_lst != [] and routes:
                    for place in widget_lst:
                        if place not in self.widgets:
                            self.widgets[place] = []
                        w = {'widget_name': widget_name, 'widget_desc': widget_desc, 'base_uri': routes[0],
                             'widget_picture': widget_picture}
                        self.widgets[place].append(w)

            # And we add the views dir of this plugin in our TEMPLATE
            # PATH
            bottle.TEMPLATE_PATH.append(os.path.join(m_dir, 'views'))

            # And finally register me so the pages can get data and other
            # useful stuff
            m.app = self

            # Load plugin configuration
            f = getattr(m, 'load_config', None)
            if f and callable(f):
                logger.debug("[WebUI] calling plugin %s, load configuration", fdir)
                f(self)

            logger.info("[WebUI] loaded plugin %s", fdir)

        except Exception, exp:
            logger.error("[WebUI] loading plugin %s, exception: %s", fdir, str(exp))

    # Add static route in the Web server
    def add_static_route(self, fdir, m_dir):
        logger.debug("[WebUI] add static route: %s", fdir)
        static_route = '/static/' + fdir + '/:path#.+#'

        def plugin_static(path):
            return static_file(path, root=os.path.join(m_dir, 'htdocs'))
        route(static_route, callback=plugin_static)

    def declare_common_static(self):
        @route('/static/photos/:path#.+#')
        def give_photo(path):
            # If the file really exist, give it. If not, give a dummy image.
            if os.path.exists(os.path.join(self.photo_dir, path + '.png')):
                return static_file(path + '.png', root=self.photo_dir)
            else:
                return static_file('images/default_user.png', root=htdocs_dir)

        @route('/static/logo/:path#.+#')
        def give_logo(path):
            # If the file really exist, give it. If not, give a dummy image.
            if os.path.exists(os.path.join(self.photo_dir, path + '.png')):
                return static_file(path + '.png', root=self.photo_dir)
            else:
                return static_file('images/default_company.png', root=htdocs_dir)

        @route('/tag/:path#.+#')
        def give_tag(path):
            # TODO: Should be more logical to locate tags images in tags directory !
            # tag_path = "/images/tags/%s" % path
            # BUT: implies modifications in all Shinken packages ...

            # If a tag image (tag.png) exists in the share dir, give it ...
            tag_path = "%s/images/sets/%s" % (self.share_dir, path)
            logger.debug("[WebUI] searching tag: %s", os.path.join(tag_path, 'tag.png'))
            if os.path.exists(os.path.join(tag_path, 'tag.png')):
                return static_file('tag.png', root=tag_path)
            else:
                # Default tags icons are located in images/tags directory ...
                tag_path = "%s/images/tags/%s" % (htdocs_dir, path)
                logger.debug("[WebUI] searching for: %s", os.path.join(tag_path, 'tag.png'))
                if os.path.exists(os.path.join(tag_path, 'tag.png')):
                    return static_file('tag.png', root=tag_path)
                else:
                    return static_file('images/default_tag.png', root=htdocs_dir)

        # Route static files css files
        @route('/static/:path#.+#')
        def server_static(path):
            # By default give from the root in bottle_dir/htdocs. If the file is missing,
            # search in the share dir
            # TODO: should be more logical to search in share_dir first ?
            root = htdocs_dir
            p = os.path.join(root, path)
            if not os.path.exists(p):
                root = self.share_dir
            return static_file(path, root=root)

        # And add the favicon ico too
        @route('/favicon.ico')
        def give_favicon():
            return static_file('favicon.ico', root=os.path.join(htdocs_dir, 'images'))

        # And add the opensearch xml
        @route('/opensearch.xml')
        def give_opensearch():
            base_url = self.request.url.replace('opensearch.xml', '')
            response.headers['Content-Type'] = 'text/xml'
            return template('opensearch', base_url=base_url)

    # --------------------------------------------------------------------------------
    # User authentication / management
    # --------------------------------------------------------------------------------
    # Do we have an user authentication module
    def has_user_authentication_module(self):
        for mod in self.modules_manager.get_internal_instances():
            f = getattr(mod, 'check_auth', None)
            if f and callable(f):
                return True
        return False

    ##
    # Check if provided username/password is accepted for login the Web UI
    #
    # Several steps:
    # 1/ username must be in the known contacts of Shinken
    # 2/ one of the WebUI modules providing a 'check_auth'
    #   method must accept the username/password couple
    ##
    def check_authentication(self, username, password):
        logger.info("[WebUI] Checking authentication for user: %s", username)
        self.user_picture = None

        c = self.datamgr.get_contact(username)
        if not c:
            logger.error("[WebUI] You need to have a contact having the same name as your user: %s", username)
            return False

        is_ok = False
        for mod in self.modules_manager.get_internal_instances():
            try:
                f = getattr(mod, 'check_auth', None)
                logger.debug("[WebUI] Check auth with: %s, for %s", mod.get_name(), username)
                if f and callable(f):
                    r = f(username, password)
                    if r:
                        is_ok = True
                        # No need for other modules
                        logger.info("[WebUI] User '%s' is authenticated by %s", username, mod.get_name())

                        # Define user picture
                        self.user_picture = '/static/photos/%s' % username
                        if self.gravatar:
                            gravatar = self.get_gravatar(c.email, 32)
                            if gravatar is not None:
                                self.user_picture = gravatar
                        logger.info("[WebUI] User picture: %s", self.user_picture)
                        break
            except Exception, exp:
                print exp.__dict__
                logger.warning("[WebUI] The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                logger.debug("[WebUI] Exception type: %s", type(exp))
                logger.debug("Back trace of this kill: %s" % (traceback.format_exc()))
                self.modules_manager.set_to_restart(mod)

        # Ok if we got a real contact, and if a module auth it
        return (is_ok and c is not None)

    ##
    # Current user can launch commands ?
    # If username is provided, check for the specified user ...
    ##
    # :TODO:maethor:150717: find a better name for this method
    def can_action(self, username=None):
        if username:
            user = User.from_contact(self.datamgr.get_contact(username), self.gravatar)
        else:
            user = request.environ['USER']
        return user and ((not self.manage_acl) or user.is_admin or user.can_submit_commands)

    # ------------------------------------------------------------------------------------------
    # Manage embedded graphs
    # ------------------------------------------------------------------------------------------
    # Try to got for an element the graphs uris from modules
    # The source variable describes the source of the calling. Are we displaying
    # graphs for the element detail page (detail), or a widget in the dashboard (dashboard) ?
    def get_graph_uris(self, elt, graphstart, graphend, source='detail'):
        logger.debug("[WebUI] Fetching graph URIs for %s (%s)", elt.host_name, source)

        uris = []
        for mod in self.modules_manager.get_internal_instances():
            try:
                logger.debug("[WebUI] module %s, get_graph_uris", mod)
                f = getattr(mod, 'get_graph_uris', None)
                if f and callable(f):
                    r = f(elt, graphstart, graphend, source)
                    logger.debug("[WebUI] Fetched: %s", r)
                    uris.extend(r)
            except Exception, exp:
                logger.warning("[WebUI] The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                logger.debug("[WebUI] Exception type: %s", type(exp))
                logger.debug("Back trace of this kill: %s", traceback.format_exc())
                self.modules_manager.set_to_restart(mod)

        return uris


    def get_graph_img_src(self,uri,link):
        url=uri
        lk=link
        if self.embeded_graph:
            data = urllib.urlopen(uri, 'rb').read().encode('base64').replace('\n', '')
            url="data:image/png;base64,{0}".format(data)
            lk=''
        return (url,lk)


    # ------------------------------------------------------------------------------------------
    # Manage external availability logs
    # ------------------------------------------------------------------------------------------
    ##
    # Check if an availability storage module is declared in webui.cfg
    ##
    def has_availability_module(self):
        logger.debug("[WebUI] searching external module for availability ...")
        self.get_availability = None
        for mod in self.modules_manager.get_internal_instances():
            f = getattr(mod, 'get_ui_availability', None)
            if f and callable(f):
                logger.info("[WebUI] Found availability module: %s", mod.get_name())
                self.get_availability = f
                return True
        return False


    # ------------------------------------------------------------------------------------------
    # Manage external shinken logs
    # ------------------------------------------------------------------------------------------
    ##
    # Check if a logs storage module is declared in webui.cfg
    ##
    def has_history_module(self):
        logger.debug("[WebUI] searching external module for history ...")
        self.get_history = None
        for mod in self.modules_manager.get_internal_instances():
            f = getattr(mod, 'get_ui_logs', None)
            if f and callable(f):
                logger.info("[WebUI] Found history module: %s", mod.get_name())
                self.get_history = f
                return True
        return False


    # ------------------------------------------------------------------------------------------
    # Manage helpdesk data
    # ------------------------------------------------------------------------------------------
    ##
    # Check if an helpdesk module is declared in webui.cfg
    ##
    def has_helpdesk_module(self):
        logger.debug("[WebUI] searching external module for helpdesk ...")
        self.get_tickets = None
        self.create_ticket = None
        self.get_helpdesk_configuration = None
        for mod in self.modules_manager.get_internal_instances():
            f = getattr(mod, 'get_ui_tickets', None)
            if f and callable(f):
                logger.info("[WebUI] Found helpdesk module: %s, get_ui_tickets", mod.get_name())
                self.get_tickets = f
                
                f = getattr(mod, 'get_ui_helpdesk_configuration', None)
                if f and callable(f):
                    logger.info("[WebUI] Found helpdesk module: %s, get_ui_helpdesk_configuration", mod.get_name())
                    self.get_helpdesk_configuration = f
                    
                    f = getattr(mod, 'set_ui_ticket', None)
                    if f and callable(f):
                        logger.info("[WebUI] Found helpdesk module: %s, set_ui_ticket", mod.get_name())
                        self.create_ticket = f
                        
                        return True
        return False


    # ------------------------------------------------------------------------------------------
    # Manage common / user's preferences
    # ------------------------------------------------------------------------------------------
    ##
    # Check if a user preference storage module is declared in webui.cfg
    ##
    def has_user_preference_module(self):
        for mod in self.modules_manager.get_internal_instances():
            f = getattr(mod, 'get_ui_user_preference', None)
            if f and callable(f):
                return True
        return False


    ##
    # Get all user preferences
    ##
    def get_user_preferences(self):
        logger.debug("[WebUI] Fetching all user preferences ...")

        user = request.environ['USER']
        return self.get_user_preference(user)

    ##
    # Get a user preference by name
    ##
    def get_user_preference(self, user, key=None, default=None):
        logger.debug("[WebUI] Fetching user preference for: %s / %s", user.get_name(), key)

        if not self.has_user_preference_module():
            result = {} if key is None else default
            # Preferences are stored in self.config_dir/user.get_name()/key
            for subdir, dirs, files in os.walk("%s/%s" % (self.config_dir, user.get_name())):
                for file in files:
                    logger.debug("[WebUI] found %s file, key = %s", file, key)
                    try:
                        f = open("%s/%s/%s" % (self.config_dir, user.get_name(), file), 'r')
                        lines = f.read()
                        f.close()
                    except:
                        pass

                    if key is not None and file == "%s" % key:
                        logger.debug("[WebUI] found key = %s", lines)
                        return lines
                    elif key is None:
                        # result.append( { file: lines } )
                        result[file] = lines

            logger.debug("[WebUI] User preference %s, returning: %s", key, result)
            return result

        for mod in self.modules_manager.get_internal_instances():
            try:
                logger.debug("[WebUI] Trying to get preference %s from %s", key, mod.get_name())
                f = getattr(mod, 'get_ui_user_preference', None)
                if f and callable(f):
                    r = f(user, key)
                    logger.debug("[WebUI] Found '%s', %s = %s", user.get_name(), key, r)
                    if r is not None:
                        return r
            except Exception, exp:
                logger.warning("[WebUI] The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                logger.warning("[WebUI] Exception type: %s", type(exp))
                logger.warning("Back trace of this kill: %s", traceback.format_exc())
                self.modules_manager.set_to_restart(mod)

        logger.debug("[WebUI] No user preferences found, returning default value: %s", default)
        return default

    ##
    # Set a user preference by name / value
    ##
    def set_user_preference(self, user, key, value):
        logger.debug("[WebUI] Saving user preference for: %s / %s", user.get_name(), key)

        if not self.has_user_preference_module():
            dir = "%s/%s" % (self.config_dir, user.get_name())
            if not os.path.exists(dir):
                try:
                    os.mkdir(dir)
                    logger.debug("[WebUI] Created user preferences directory: %s", dir)
                except Exception, exp:
                    logger.error("[WebUI] User preference directory creation failed: %s", exp)

            # Preferences are stored in self.config_dir/user.get_name()/key
            f = open("%s/%s" % (dir, key), 'w')
            f.write(value)
            f.close()
            logger.debug("[WebUI] Updated '%s', %s = %s", user.get_name(), key, value)

        else:
            for mod in self.modules_manager.get_internal_instances():
                try:
                    f = getattr(mod, 'set_ui_user_preference', None)
                    if f and callable(f):
                        f(user, key, value)
                        logger.debug("[WebUI] Updated '%s', %s = %s", user.get_name(), key, value)
                except Exception, exp:
                    logger.warning("[WebUI] The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                    logger.warning("[WebUI] Exception type: %s", type(exp))
                    logger.warning("Back trace of this kill: %s", traceback.format_exc())
                    self.modules_manager.set_to_restart(mod)

    ##
    # Get a common preference by name
    ##
    def get_common_preference(self, key, default=None):
        logger.debug("[WebUI] Fetching common preference for: %s", key)

        if not self.has_user_preference_module():
            result = [] if key is None else default
            # Preferences are stored in self.config_dir/user.get_name()/key
            for subdir, dirs, files in os.walk("%s/%s" % (self.config_dir, 'common')):
                for file in files:
                    logger.debug("[WebUI] found %s file, key = %s", file, key)
                    try:
                        f = open("%s/%s/%s" % (self.config_dir, 'common', file), 'r')
                        lines = f.read()
                        f.close()
                    except:
                        pass

                    if key is not None and file == "%s" % key:
                        logger.debug("[WebUI] found key = %s", lines)
                        return lines
                    elif key is None:
                        result.append(lines)

            logger.debug("[WebUI] No common preferences found for %s, returning default value: %s", key, default)
            return result

        for mod in self.modules_manager.get_internal_instances():
            try:
                logger.debug("[WebUI] Trying to get common preference %s from %s", key, mod.get_name())
                f = getattr(mod, 'get_ui_common_preference', None)
                if f and callable(f):
                    r = f(key)
                    logger.debug("[WebUI] Found 'common', %s = %s", key, r)
                    if r is not None:
                        return r
            except Exception, exp:
                logger.warning("[WebUI] The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                logger.warning("[WebUI] Exception type: %s", type(exp))
                logger.warning("Back trace of this kill: %s", traceback.format_exc())
                self.modules_manager.set_to_restart(mod)

        logger.debug("[WebUI] No common preferences found, returning default value: %s", default)
        return default

    ##
    # Set a common preference by name / value
    ##
    def set_common_preference(self, key, value):
        logger.debug("[WebUI] Saving common preference: %s = %s", key, value)

        if not self.has_user_preference_module():
            dir = "%s/common" % (self.config_dir)
            if not os.path.exists(dir):
                try:
                    os.mkdir(dir)
                    logger.debug("[WebUI] Created common preferences directory: %s", dir)
                except Exception, exp:
                    logger.error("[WebUI] Common preference directory creation failed: %s", exp)

            # Preferences are stored in self.config_dir/user.get_name()/key
            f = open("%s/%s" % (dir, key), 'w')
            f.write(value)
            f.close()
            logger.debug("[WebUI] Updated '%s', %s = %s", 'common', key, value)

        else:
            for mod in self.modules_manager.get_internal_instances():
                try:
                    f = getattr(mod, 'set_ui_common_preference', None)
                    if f and callable(f):
                        f(key, value)
                        logger.debug("[WebUI] Updated 'common', %s = %s", key, value)
                except Exception, exp:
                    logger.warning("[WebUI] The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                    logger.warning("[WebUI] Exception type: %s", type(exp))
                    logger.warning("Back trace of this kill: %s", traceback.format_exc())
                    self.modules_manager.set_to_restart(mod)

    ##
    # Get/set user's bookmarks
    ##
    def get_user_bookmarks(self, user):
        ''' Returns the user bookmarks. '''
        return json.loads(self.get_user_preference(user, 'bookmarks') or '[]')

    def get_common_bookmarks(self):
        ''' Returns the common bookmarks. '''
        return json.loads(self.get_common_preference('bookmarks') or '[]')


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
                    r = f()
                    lst.append(r)
            except Exception, exp:
                logger.warning("[WebUI] Warning: The mod %s raise an exception: %s, I'm tagging it to restart later", mod.get_name(), str(exp))
                logger.debug("[WebUI] Exception type: %s", type(exp))
                logger.debug("Back trace of this kill: %s", traceback.format_exc())
                self.modules_manager.set_to_restart(mod)

        return lst


@bottle.hook('before_request')
def login_required():
    # :COMMENT:maethor:150718: This hack is crazy, but I don't know how to do it properly
    app = bottle.BaseTemplate.defaults['app']
    request.environ['APP'] = app

    if request.urlparts.path == '/user/login':
        return
    if request.urlparts.path.startswith('/static'):
        return

    username = bottle.request.get_cookie("user", secret=app.auth_secret)
    if not username and not app.allow_anonymous:
        app.bottle.redirect("/user/login")
    contact = app.datamgr.get_contact(username or 'anonymous')
    if not contact:
        app.bottle.redirect("/user/login")

    request.environ['USER'] = User.from_contact(contact, app.gravatar)
    bottle.BaseTemplate.defaults['user'] = request.environ['USER']
