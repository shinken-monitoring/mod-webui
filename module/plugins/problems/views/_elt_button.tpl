%import urllib
<a class="js-open-elt" href="{{ urllib.quote(helper.get_link_dest(elt)) }}" title="{{!aka}}">{{ elt.display_name if elt.display_name else elt.get_name() }}</a>
