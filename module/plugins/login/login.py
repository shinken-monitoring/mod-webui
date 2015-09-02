#!/usr/bin/python

# -*- coding: utf-8 -*-

# Copyright (C) 2009-2014:
#    Gabes Jean, naparuba@gmail.com
#    Gerhard Lausser, Gerhard.Lausser@consol.de
#    Gregory Starck, g.starck@gmail.com
#    Hartmut Goebel, h.goebel@goebel-consult.de
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

### Will be populated by the UI with it's own value
app = None

from shinken.log import logger

# Our page
def get_page():
    return user_login()


def user_login():
    if app.request.get_cookie("user", secret=app.auth_secret):
        app.bottle.redirect("/")

    err = app.request.GET.get('error', None)
    login_text = app.login_text
    company_logo = app.company_logo

    return {'error': err, 'login_text': login_text, 'company_logo': company_logo}


def user_login_redirect():
    app.bottle.redirect("/user/login")
    return {}


def user_logout():
    # To delete it, send the same, with different date
    user_name = app.request.get_cookie("user", secret=app.auth_secret)
    if user_name:
        app.response.set_cookie('user', False, secret=app.auth_secret, path='/')
    else:
        app.response.set_cookie('user', '', secret=app.auth_secret, path='/')
        
    logger.info("[WebUI]  user '%s' signed out", user_name)
    app.bottle.redirect("/user/login")
    return {}


def user_auth():
    login = app.request.forms.get('login', '')
    password = app.request.forms.get('password', '')
    logger.info("[WebUI]  user '%s' is signing in ...", login)
    
    # Tries to authenticate user
    is_authenticated = app.check_authentication(login, password)
    if is_authenticated:
        app.response.set_cookie('user', login, secret=app.auth_secret, path='/')
        logger.info("[WebUI]  user '%s' signed in", login)
        app.bottle.redirect("/dashboard")
    else:
        logger.warning("[WebUI]  user '%s' access denied", login)
        app.bottle.redirect("/user/login?error=Invalid user or Password")

    return {'is_auth': is_authenticated}


# manage the /. If the user is known, go to home page.
# Should be /dashboard in the future. If not, go login :)
def get_root():
    user = app.request.get_cookie("user", secret=app.auth_secret)
    if user:
        app.bottle.redirect("/dashboard")
    elif app.remote_user_enable in ['1', '2']:
        user_name=None
        if app.remote_user_variable in app.request.headers and app.remote_user_enable == '1':
            user_name = app.request.headers[app.remote_user_variable]
        elif app.remote_user_variable in app.request.environ and app.remote_user_enable == '2':
            user_name = app.request.environ[app.remote_user_variable]
        if not user_name:
            logger.warning("[WebUI] remote user enabled but no user name found")
            app.bottle.redirect("/user/login")
        c = app.datamgr.get_contact(user_name)
        if not c:
            logger.warning("Warning: You need to have a contact having the same name as your user %s", user_name)
            app.bottle.redirect("/user/login")
        else:
            app.response.set_cookie('user', user_name, secret=app.auth_secret, path='/')
            app.bottle.redirect("/")
    else:
        app.bottle.redirect("/user/login")


pages = { 
    user_login: {'routes': ['/user/login', '/user/login/'], 'view': 'login', 'static': True},
    user_login_redirect: {'routes': ['/login'], 'static': True},
    user_auth: {'routes': ['/user/auth'], 'method': 'POST', 'static': True},
    user_logout: {'routes': ['/user/logout', '/logout'], 'static': True},
    get_root: {'routes': ['/'], 'static': True},
}
