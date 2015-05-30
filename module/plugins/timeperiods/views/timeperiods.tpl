%timeperiods = app.get_timeperiods()
%title='All timeperiods (%d time periods)' % len(timeperiods)
%rebase("layout", css=['timeperiods/css/timeperiods.css'], js=['timeperiods/js/timeperiods-overview.js'], title=title, refresh=True)

%import time

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
  <ul id="timeperiods" class="list row pull-right">
    %even=''
    %for timeperiod in timeperiods:
      %if even =='':
        %even='alt'
      %else:
        %even=''
      %end
      
      <li class="clearfix {{even}} ">
        <section class="left">
          <h3>{{timeperiod.timeperiod_name}}</h3>
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
                %if hasattr(timeperiod, 'alias'):
                <tr>
                  <td><strong>Alias:</strong></td>
                  <td>{{timeperiod.alias}}</td>
                </tr>
                %end
                <tr>
                  <td><strong>Valid:</strong></td>
                  <td><span class="{{'glyphicon glyphicon-ok font-green' if timeperiod.is_correct() else 'glyphicon glyphicon-remove font-red'}}"></span></td>
                </tr>
                %if len(timeperiod.dateranges) > 0:
                <tr>
                  <td colspan="2"><strong>Periods:</strong></td>
                </tr>
                %for elt in timeperiod.dateranges:
                %(dr_start, dr_end) = elt.get_start_and_end_time()
                %dr_start = time.strftime("%d %b %Y", time.localtime(dr_start))
                %dr_end = time.strftime("%d %b %Y", time.localtime(dr_end))
                <tr>
                  <td></td>
                  <td>
                    From: <strong>{{dr_start}}</strong> to:<strong>{{dr_end}}</strong>
                    %if len(elt.timeranges) > 0:
                    &nbsp;(
                    %idx=0
                    %for timerange in elt.timeranges:
                    %hr_start = ("%02d:%02d" % (timerange.hstart, timerange.mstart))
                    %hr_end = ("%02d:%02d" % (timerange.hend, timerange.mend))
                    <strong>{{hr_start}}-{{hr_end}}&nbsp;</strong>
                    %', ' if idx == 0 else ''
                    %idx = idx+1
                    %end
                    )
                    %end
                  </td>
                </tr>
                %end
                %end
                <tr>
                  <td><strong>Active:</strong></td>
                  <td><span class="{{'glyphicon glyphicon-ok font-green' if timeperiod.is_time_valid(int(time.time())) else 'glyphicon glyphicon-remove font-red'}}"></span></td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>
      </li>
    %end
  </ul>
</div>
