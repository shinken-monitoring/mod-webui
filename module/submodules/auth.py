#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ai ts=4 sts=4 et sw=4 nu

import traceback
import crypt

from shinken.log import logger

from .metamodule import MetaModule

#TODO: use md5 functions from passlib library instead of this specific library ...
try:
    from ..lib.md5crypt import apache_md5_crypt, unix_md5_crypt
    md5_available = True
except ImportError:
    logger.warning('[WebUI-auth-htpasswd] Can not import md5 password authentication.')
    md5_available = False
except ValueError:
    logger.warning('[WebUI-auth-htpasswd] Can not import md5 password authentication!')
    md5_available = False

try:
    from passlib.hash import bcrypt
    bcrypt_available = True
except ImportError:
    logger.warning('[WebUI-auth-htpasswd] Can not import bcrypt password authentication. '
                 'You should \'pip install passlib\' if you intend to use it.')
    bcrypt_available = False


class AuthMetaModule(MetaModule):

    _functions = ['check_auth']
    _authenticator = None
    _session = None
    _user_login = None
    _user_info = None

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

        if self.modules:
            for mod in self.modules:
                try:
                    logger.info("[WebUI] Authenticating user '%s' with %s", username, mod.get_name())
                    if mod.check_auth(username, password):
                        logger.info("[WebUI] User '%s' is authenticated by %s", username, mod.get_name())
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
                    logger.warning("[WebUI] The mod %s raised an exception: %s", str(exp))
                    logger.warning("[WebUI] Back trace: %s" % (traceback.format_exc()))

        if not self._user_login:
            logger.info("[WebUI] Internal htpasswd authentication")
            if self.app.htpasswd_file and self.check_apache_htpasswd_auth(username, password):
                self._authenticator = 'htpasswd'
                self._user_login = username

        if not self._user_login:
            logger.info("[WebUI] Internal alignak backend authentication")
            if self.app.alignak_backend_endpoint:
                if self.check_alignak_auth(username, password):
                    self._authenticator = 'alignak'
                    self._user_login = username
                    self._session = self.app.frontend.get_logged_user_token()
                    self._user_info = self.app.frontend.get_logged_user()

        if not self._user_login:
            logger.info("[WebUI] Internal contact authentication")
            if self.check_cfg_password_auth(username, password):
                self._authenticator = 'contact'
                self._user_login = username

        if self._user_login:
            logger.info("[WebUI] user authenticated thanks to %s", self._authenticator)
            return self._user_login

        return None

    def is_available(self):
        ''' Always returns True because this MetaModule have a default behavior. '''
        return True

    def get_session(self):
        '''
        Get the session identifier
        '''
        return self._session

    def get_user_login(self):
        '''
        Get the user login
        '''
        return self._user_login

    def get_user_info(self):
        '''
        Get the user information
        '''
        return self._user_info

    def check_alignak_auth(self, username, password):
        ''' Embedded authentication against Alignak backend.
        '''
        logger.info("[WebUI-auth-alignak] Authenticating user '%s'", username)

        try:
            self.app.frontend.logout()
            self.app.frontend.login(username, password)
            logger.info("[WebUI-auth-alignak] Authenticated")
            return True
        except:
            logger.error("[WebUI-auth-alignak] could not connect to Alignak backend")
            return False

        logger.warning("[WebUI-auth-alignak] Authentication failed %s != %s", p, password)
        return False

    def check_cfg_password_auth(self, username, password):
        ''' Embedded authentication with password stored in contact definition.
            Function imported from auth-cfg-password module.
        '''
        logger.info("[WebUI-auth-cfg-password] Authenticating user '%s'", username)

        c = self.app.datamgr.get_contact(name=username)
        if not c:
            logger.error("[WebUI-auth-cfg-password] You need to have a contact having the same name as your user: %s", username)
            return False
        p = None
        if isinstance(c, dict):
            p = c.get('password', None)
        else:
            p = c.password

        if p == password:
            logger.info("[WebUI-auth-cfg-password] Authenticated")
            return True

        logger.warning("[WebUI-auth-cfg-password] Authentication failed %s != %s", p, password)
        return False

    def check_apache_htpasswd_auth(self, username, password):
        ''' Embedded authentication with password in Apache htpasswd file.
            Function imported from auth-htpasswd module.
        '''
        logger.info("[WebUI-auth-htpasswd] Authenticating user '%s'", username)

        try:
            f = open(self.app.htpasswd_file, 'r')
            for line in f.readlines():
                line = line.strip()
                # Bypass bad lines
                if not ':' in line:
                    continue
                if line.startswith('#'):
                    continue
                elts = line.split(':')
                name = elts[0]
                hash = elts[1]
                if md5_available and hash[:5] == '$apr1' or hash[:3] == '$1$':
                    h = hash.split('$')
                    magic = h[1]
                    salt = h[2]
                elif bcrypt_available and hash[:4] == '$2y$':
                    h = hash.split('$')
                    magic = h[1]
                else:
                    magic = None
                    salt = hash[:2]

                # If we match the username, look at the crypt
                if name == username:
                    if md5_available and magic == 'apr1':
                        compute_hash = apache_md5_crypt(password, salt)
                    elif md5_available and magic == '1':
                        compute_hash = unix_md5_crypt(password, salt)
                    elif bcrypt_available and magic == '2y':
                        compute_hash = bcrypt.verify(password, hash) and hash
                    else:
                        compute_hash = crypt.crypt(password, salt)
                    if compute_hash == hash:
                        logger.info("[WebUI-auth-htpasswd] Authenticated")
                        return True
                else:
                    logger.debug("[WebUI-auth-htpasswd] Authentication failed, invalid name: %s / %s", name, username)
        except Exception as exp:
            logger.info("[WebUI-auth-htpasswd] Authentication against apache passwd file failed, exception: %s", str(exp))
        finally:
            try:
                f.close()
            except:
                pass

        return False
