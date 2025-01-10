%# Default is to consider that the underlying framework is not Alignak (hence Shinken)
%setdefault('alignak', False)
%setdefault('fmwk', 'Shinken')

%if alignak:
%from alignak.version import VERSION
%fmwk="Alignak"
%else:
%from shinken.bin import VERSION
%end

<div class="modal-header">
  <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
  <h3 class="modal-title">About this</h3>
</div>
<div class="modal-body">
  <dl class="dl-horizontal">
    <dt>Framework</dt><dd>{{fmwk}} v{{VERSION}}</dd>
    <dt>WebUI module</dt><dd>{{fmwk}} WebUI v{{app.app_version if app is not None else ''}}</dd>
    <dt>Copyright</dt><dd>© {{app.app_copyright if app is not None else ''}} - {{app.app_license if app is not None else ''}}</dd>
    <dt>Release notes</dt><dd><a href="https://github.com/shinken-monitoring/mod-webui/releases">https://github.com/shinken-monitoring/mod-webui/releases</a></dd>
    <dt>Documentation</dt><dd><a href="https://github.com/shinken-monitoring/mod-webui/wiki" target="_blank">https://github.com/shinken-monitoring/mod-webui/wiki</a></dd>
  </dl>
</div>
