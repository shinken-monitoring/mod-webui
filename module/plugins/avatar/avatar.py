#!/usr/bin/python

# -*- coding: utf-8 -*-

# make_svg() comes from https://github.com/Bekt/invatar/

from random import randint, seed


### Will be populated by the UI with it's own value
app = None


defaults = {
    'size': 100,
    'font_size': 60,
    'font_family': 'Arial',
    'bg': 'black',
    'color': 'white',
    'text': 'KB'
}


def make_svg(**options):
    """
        Builds a simple SVG text square with a centered text.
        options: size, font_size, font_family, bg, color, text
        :return (str)
    """
    if options is not None and not isinstance(options, dict):
        raise ValueError('options should be None or a type of dict.')

    if 'size' in options and 'font_size' not in options:
        options['font_size'] = int(options['size'] * 0.6)

    dc = defaults.copy()
    dc.update(options)
    options = dc

    svg = u"""
    <svg xmlns="http://www.w3.org/2000/svg"
         width="{size}px" height="{size}px">
      <g>
        <rect x="0" y="0" fill="{bg}" width="{size}px" height="{size}px">
        </rect>
        <text y="50%" x="50%" fill="{color}"
              text-anchor="middle" dominant-baseline="central"
              style="font-family: {font_family}; font-size: {font_size}px">
          {text}
        </text>
      </g>
    </svg>
    """.format(**options)

    return svg


def _background_color(s):
    """
        Generate a random background color.
        Brighter colors are dropped because text is white.

        :param s: Seed used by the random generator
        (same seed will produce same color every time)
    """
    seed(s)
    r = g = b = 255
    while r + g + b > 255*2:
        r = randint(0, 255)
        g = randint(0, 255)
        b = randint(0, 255)
    return '#{:02x}{:02x}{:02x}'.format(r, g, b)


def get_avatar(username="#"):
    app.response.content_type = 'image/svg+xml'

    options = dict()
    options['text'] = username[0].upper()
    options['bg'] = _background_color(username)

    return make_svg(**options)


pages = {
    get_avatar: {
        'name': 'GetAvatar', 'route': '/avatar/<username:path>'
    }
}
