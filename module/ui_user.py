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


from shinken.objects import Contact
from shinken.log import logger


class User(Contact):
    session = None

    def set_information(self, session, *information):
        """
        Set user attributes from provided information
        """
        self.session = session
        for dictionary in information:
            for key in dictionary:
                logger.debug("[WebUI] user information: %s = %s", key, dictionary[key])
                setattr(self, key, dictionary[key])

    def get_session(self):
        return getattr(self, 'session', None)

    def get_username(self):
        if getattr(self, 'contact_name', None):
            return self.contact_name

        return getattr(self, 'name', 'Unnamed')

    def get_name(self):
        name = self.get_username()
        if getattr(self, 'realname', None):
            name = "%s %s" % (getattr(self, 'firstname'), getattr(self, 'realname'))
        elif getattr(self, 'alias', None) and getattr(self, 'alias', None) != 'none':
            name = getattr(self, 'alias', name)
        return name

    def is_administrator(self):
        """
        Is contact an administrator?
        """
        if isinstance(getattr(self, 'is_admin', '0'), bool):
            return self.is_admin

        return getattr(self, 'is_admin', '0') == '1'

    def is_commands_allowed(self):
        """
        Is contact allowed to use commands?
        """
        if self.is_administrator():
            return True

        if isinstance(getattr(self, 'can_submit_commands', '0'), bool):
            return self.can_submit_commands

        return getattr(self, 'can_submit_commands', '0') == '1'

    def _is_related_to(self, item):
        """ Is the item (host, service, group,...) related to the user?

            In other words, can the user see this item in the WebUI?

            :returns: True or False
        """
        logger.debug("[WebUI - relation], item: %s", item)

        # if the user is an admin, always consider there is a relation
        if self.is_administrator():
            return True

        if isinstance(item, list):
            logger.warning("[WebUI - relation], item is a list: %s %s", item, item.__class__)
            return True

        # is it me as a Contact object ?
        if item.__class__.my_type == 'contact':
            return item.contact_name == self.contact_name

        # Am I member of the contacts group?
        if item.__class__.my_type == 'contactgroup':
            for contact in item.members:
                if contact.contact_name == self.contact_name:
                    logger.debug("[WebUI - relation], member of contactgroup")
                    return True

        # May be the user is a direct contact
        if hasattr(item, 'contacts'):
            for contact in item.contacts:
                if contact.contact_name == self.contact_name:
                    logger.debug("[WebUI - relation], user is a direct contact")
                    return True

        # May be it's a contact of a linked item
        if item.__class__.my_type == 'hostgroup':
            for host in item.get_hosts():
                for contact in host.contacts:
                    if contact.contact_name == self.contact_name:
                        logger.debug("[WebUI - relation], user is a contact through an hostgroup")
                        return True

        # May be it's a contact of a sub item ...
        if item.__class__.my_type == 'servicegroup':
            for service in item.get_services():
                for contact in service.contacts:
                    if contact.contact_name == self.contact_name:
                        logger.debug("[WebUI - relation], user is a contact through a servicegroup")
                        return True

        # May be it's a contact of a linked item
        # (source problems or impacts)
        if hasattr(item, 'source_problems'):
            for source_problem in item.source_problems:
                for contact in source_problem.contacts:
                    if contact.contact_name == self.contact_name:
                        logger.debug("[WebUI - relation], user is a contact of a source problem")
                        return True

        # May be it's a contact of service's host
        if item.__class__.my_type == 'service':
            for contact in item.host.contacts:
                if contact.contact_name == self.contact_name:
                    logger.debug("[WebUI - relation], user is a contact of the main host")
                    return True

        # Now impacts related maybe?
        if hasattr(item, 'impacts'):
            for impact in item.impacts:
                for contact in impact.contacts:
                    if contact.contact_name == self.contact_name:
                        logger.debug("[WebUI - relation], user is a contact of an impact")
                        return True

        logger.debug("[WebUI - relation] user is not related to item")
        return False

    @property
    def avatar_url(self):
        return '/avatar/%s' % self.get_username()

    @classmethod
    def from_contact(cls, contact):
        user = contact
        try:
            user.__class__ = User
        except Exception:
            raise Exception(user)

        return user
