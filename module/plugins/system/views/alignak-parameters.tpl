%rebase("layout", breadcrumb=[ ['System parameters', '/system-parameters'] ], title='System parameters')

<div class="panel panel-default">
   %if not configuration['_schedulers']:
   <div class="text-center">
     <h3>No system information is available.</h3>
   </div>
   %else:

   %include("_dump_dict_panel.tpl", id="c1", title='Global configuration', dump_dict=configuration['_config'])

   %include("_dump_dict_panel.tpl", id="c2", title='Global macros', dump_dict=configuration['_macros'])

   %for config in configuration['_schedulers']:
   %include("_dump_dict_panel.tpl", id=config.get('id'), title="Scheduler %s" % config.get('instance_name', 'Unnamed'), dump_dict=config)
   %end

   %end
</div>
