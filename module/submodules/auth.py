#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ai ts=4 sts=4 et sw=4 nu

import traceback
import crypt

from shinken.log import logger

from .metamodule import MetaModule

# TODO: use md5 functions from passlib library instead of this specific library ...
md5_available = False
try:
    from ..lib.md5crypt import apache_md5_crypt, unix_md5_crypt
    md5_available = True
except ImportError:
    logger.warning('[WebUI-auth-htpasswd] Can not import md5 password authentication.')
except ValueError:
    logger.warning('[WebUI-auth-htpasswd] Can not import md5 password authentication!')

passlib_available = False
try:
    from passlib.hash import bcrypt
    from passlib.hash import sha256_crypt
    from passlib.hash import sha512_crypt
    passlib_available = True
except ImportError:
    logger.warning("[WebUI-auth-htpasswd] Can not import bcrypt password authentication. "
                   "You should 'pip install passlib' if you intend to use it.")


class AuthMetaModule(MetaModule):

    _functions = ['check_auth']
    _authenticator = None
    _session = None
    _user_login = None
    _user_info = None

    def __init__(self, modules, app):
        super(AuthMetaModule, self).__init__(modules=modules, app=app)

    def check_auth(self, username, password):
        """ Check username/password.
            If there is submodules, this method calls them one by one until one of them returns
            True. If no submodule can authenticate the user, then we try with internal
            authentication methods: htpasswd file, then contact password.

            This method returns a User object if authentication succeeded, else it returns None
        """
        self._user_login = None
        self._authenticator = None
        self._session = None
        self._user_info = None
        logger.info("[WebUI] Authenticating user '%s'", username)

        self.app.request.environ['MSG'] = "Unable to authenticate a user"

        if self.modules:
            for mod in self.modules:
                try:
                    logger.info("[WebUI] Authenticating user '%s' with %s",
                                username, mod.get_name())
                    if mod.check_auth(username, password):
                        logger.debug("[WebUI] User '%s' is authenticated thanks to %s",
                                     username, mod.get_name())
                        self._authenticator = mod.get_name()
                        self._user_login = username

                        # Session identifier ?
                        f = getattr(mod, 'get_session', None)
                        if f and callable(f):
                            self._session = mod.get_session()
                            logger.info("[WebUI] User session: %s", self._session)

                        # User information ?
                        f = getattr(mod, 'get_user_info', None)
                        if f and callable(f):
                            self._user_info = mod.get_user_info()
                            logger.info("[WebUI] User info: %s", self._user_info)
                except Exception as exp:
                    logger.warning("[WebUI] Exception: %s", str(exp))
                    logger.warning("[WebUI] Back trace: %s", traceback.format_exc())

        if not self._user_login:
            logger.info("[WebUI] Internal htpasswd authentication")
            if self.app.htpasswd_file and self.check_apache_htpasswd_auth(username, password):
                self._authenticator = 'htpasswd'
                self._user_login = username

        if not self._user_login:
            logger.info("[WebUI] Internal contact authentication")
            if self.check_cfg_password_auth(username, password):
                self._authenticator = 'contact'
                self._user_login = username

        if self._user_login:
            logger.info("[WebUI] user authenticated thanks to %s", self._authenticator)
            self.app.request.environ['MSG'] = "Welcome to the WebUI"
            return self._user_login

        return None

    def is_available(self):
        """ Always returns True because this MetaModule have a default behavior. """
        return True

    def get_session(self):
        """
        Get the session identifier
        """
        return self._session

    def get_user_login(self):
        """
        Get the user login
        """
        return self._user_login

    def get_user_info(self):
        """
        Get the user information
        """
        return self._user_info

    def check_cfg_password_auth(self, username, password):
        """ Embedded authentication with password stored in contact definition.
            Function imported from auth-cfg-password module.
        """
        logger.info("[WebUI-auth-cfg-password] Authenticating user '%s'", username)

        c = self.app.datamgr.get_contact(name=username)
        if not c:
            c = self.app.datamgr.get_contacts()
            if not c:
                logger.error("[WebUI] the WebUI do not know any user! "
                             "Are you sure it is correctly initialized?")
            else:
                logger.error("[WebUI-auth-cfg-password] You need to have a contact "
                             "having the same name as your user: %s", username)
            self.app.request.environ['MSG'] = "You are not allowed to connect."
            return False
        p = None
        if isinstance(c, dict):
            p = c.get('password', None)
        else:
            p = c.password

        # basic checks
        if not p:
            logger.error("[WebUI-auth-cfg-password] User %s does not have a password: connection refused",
                         username)
            self.app.request.environ['MSG'] = "No user password set"
            return False

        if p == 'NOPASSWORDSET':
            logger.error("[WebUI-auth-cfg-password] User %s still has the default password: connection refused",
                         username)
            self.app.request.environ['MSG'] = "Default user password set"
            return False

        if p == password:
            logger.info("[WebUI-auth-cfg-password] Authenticated")
            return True

        self.app.request.environ['MSG'] = "Access denied"
        logger.warning("[WebUI-auth-cfg-password] Authentication failed, password mismatch ")
        return False

    def check_apache_htpasswd_auth(self, username, password):
        """ Embedded authentication with password in Apache htpasswd file.
            Function imported from auth-htpasswd module.
        """
        logger.info("[WebUI-auth-htpasswd] Authenticating user '%s'", username)

        try:
            f = open(self.app.htpasswd_file, 'r')
            for line in f.readlines():
                line = line.strip()
                # Bypass bad lines
                if ':' not in line:
                    continue
                if line.startswith('#'):
                    continue
                elts = line.split(':')
                name = elts[0]
                my_hash = elts[1]

                if my_hash[:5] == '$apr1' or my_hash[:3] == '$1$':
                    h = my_hash.split('$')
                    magic = h[1]
                    salt = h[2]
                elif my_hash[0] == '$':
                    h = my_hash.split('$')
                    magic = h[1]
                else:
                    magic = None
                    salt = my_hash[:2]

                # If we match the username, look at the crypt
                if name == username:
                    if md5_available and magic == 'apr1':
                        valid_hash = (apache_md5_crypt(password, salt) == my_hash)
                    elif md5_available and magic == '1':
                        valid_hash = (unix_md5_crypt(password, salt) == my_hash)
                    elif passlib_available and (magic[0] == '2'):
                        valid_hash = bcrypt.verify(password, my_hash)
                    elif passlib_available and magic == '5':
                        valid_hash = sha256_crypt.verify(password, my_hash)
                    elif passlib_available and magic == '6':
                        valid_hash = sha512_crypt.verify(password, my_hash)
                    elif magic is None:
                        valid_hash = (crypt.crypt(password, salt) == my_hash)

                    if valid_hash:
                        logger.info("[WebUI-auth-htpasswd] Authenticated")
                        return True
                else:
                    logger.debug("[WebUI-auth-htpasswd] Authentication failed, "
                                 "invalid name: %s / %s", name, username)
        except Exception as exp:
            logger.info("[WebUI-auth-htpasswd] Authentication against apache passwd "
                        "file failed, exception: %s", str(exp))
        finally:
            try:
                f.close()
            except Exception:
                pass

        return False
