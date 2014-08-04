%title='All commands (%d commands)' % len(app.datamgr.get_commands())
%rebase layout globals(), css=['commands/css/commands.css'], js=['commands/js/commands-overview.js'], title=title, refresh=True

%helper = app.helper
%datamgr = app.datamgr
%display_all = True if params['display']=='all' else False

<div class="row">
  <div class="pull-right col-sm-2">
    <span class="btn-group pull-right">
      <a href="#" id="listview" class="btn btn-small switcher pull-right active" data-original-title='List'> <i class="fa fa-align-justify"></i> </a>
      <a href="#" id="gridview" class="btn btn-small switcher pull-right" data-original-title='Grid'> <i class="fa fa-th"></i> </a>
    </span>
  </div>
</div>
<div class="row">
  <ul id="commands" class="list row pull-right">
    %even=''
    %for command in app.datamgr.get_commands():
      %if even =='':
        %even='alt'
      %else:
        %even=''
      %end
      
      <li class="clearfix {{even}} ">
        <section class="left">
          <h3>{{command.command_name}}</h3>
          <div class="meta">
            <table class="table table-condensed pull-left" style="table-layout: fixed; word-wrap: break-word;">
              <colgroup>
                <col style="width: 120px" />
                <col style="width: 60%" />
              </colgroup>
              <thead>
                <tr>
                  <th colspan="2"></td>
                </tr>
              </thead>
              <tbody style="font-size:x-small;">
                %if hasattr(command, 'command_line'):
                <tr>
                  <td><strong>Command line:</strong></td>
                  <td>{{command.command_line}}</td>
                </tr>
                %else:
                <tr>
                  <td colspan="2"><strong>No command line defined!</strong></td>
                </tr>
                %end
              </tbody>
            </table>
          </div>
        </section>
      </li>
    %end
  </ul>
</div>