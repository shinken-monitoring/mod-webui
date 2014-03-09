%rebase layout globals(), css=['system/css/log.css'], title='System Log', menu_part='/system'

%from shinken.bin import VERSION
%helper = app.helper
%import time
%import datetime

%today = datetime.datetime.now()
%today_beginning = datetime.datetime(today.year, today.month, today.day,0,0,0,0)
%today_beginning_time = int(time.mktime(today_beginning.timetuple()))
%today_end = datetime.datetime(today.year, today.month, today.day,23,59,59,999)
%today_end_time = int(time.mktime(today_end.timetuple()))

%yesterday = datetime.datetime.now() - datetime.timedelta(days = 1)
%yesterday_beginning = datetime.datetime(yesterday.year, yesterday.month, yesterday.day,0,0,0,0)
%yesterday_beginning_time = int(time.mktime(yesterday_beginning.timetuple()))
%yesterday_end = datetime.datetime(yesterday.year, yesterday.month, yesterday.day,23,59,59,999)
%yesterday_end_time = int(time.mktime(yesterday_end.timetuple()))

%thisweek = datetime.datetime.now() - datetime.timedelta(days = 7)
%thisweek_beginning = datetime.datetime(thisweek.year, thisweek.month, thisweek.day,0,0,0,0)
%thisweek_beginning_time = int(time.mktime(thisweek_beginning.timetuple()))
%thisweek_end = thisweek_beginning + datetime.timedelta(days = 7)
%thisweek_end_time = int(time.mktime(thisweek_end.timetuple()))

%lastweek = datetime.datetime.now() - datetime.timedelta(days = 14)
%lastweek_beginning = datetime.datetime(lastweek.year, lastweek.month, lastweek.day,0,0,0,0)
%lastweek_beginning_time = int(time.mktime(lastweek_beginning.timetuple()))
%lastweek_end = lastweek_beginning + datetime.timedelta(days = 7)
%lastweek_end_time = int(time.mktime(lastweek_end.timetuple()))


<div id="content_container">
	<ul class="nav nav-tabs" id="myTab">
		<li class="active"><a href="#today" data-toggle="tab">Today</a></li>
		<li><a href="#yesterday" data-toggle="tab">Yesterday</a></li>
		<li><a href="#thisweek" data-toggle="tab">This week</a></li>
		<li><a href="#lastweek" data-toggle="tab">Last week</a></li>
		<li><a href="#custom" data-toggle="tab">Custom</a></li>
	</ul>

	<div class="tab-content">
		<div class="tab-pane active" id="today">
			<table class="table table-striped">
				<tbody>
					<!--
					<tr>
						<td colspan="4"><em>{{message}}</em></td>
					</tr>
					-->
					<tr>
						<td colspan="4"><strong>From {{time.asctime(time.localtime(today_beginning_time))}} to {{time.asctime(time.localtime(today_end_time))}}</strong></td>
					</tr>
%for log in records:
%if log['date'] >= today_beginning_time and log['date'] <= today_end_time:
					<tr>
						<td>{{time.asctime(time.localtime(log['date']))}}</td>
						<td>{{log['host']}}</td>
						<td>{{log['service']}}</td>
						<td>{{log['message']}}</td>
					</tr>
%end
%end
				</tbody>
			</table>
		</div>
		<div class="tab-pane" id="yesterday">
			<table class="table table-striped">
				<tbody>
					<tr>
						<td colspan="4"><strong>From {{time.asctime(time.localtime(yesterday_beginning_time))}} to {{time.asctime(time.localtime(yesterday_end_time))}}</strong></td>
					</tr>
%for log in records:
%if log['date'] >= yesterday_beginning_time and log['date'] <= yesterday_end_time:
					<tr>
						<td>{{time.asctime(time.localtime(log['date']))}}</td>
						<td>{{log['host']}}</td>
						<td>{{log['service']}}</td>
						<td>{{log['message']}}</td>
					</tr>
%end
%end
				</tbody>
			</table>
		</div>
		<div class="tab-pane" id="thisweek">
			<table class="table table-striped">
				<tbody>
					<tr>
						<td colspan="4"><strong>From {{time.asctime(time.localtime(thisweek_beginning_time))}} to {{time.asctime(time.localtime(thisweek_end_time))}}</strong></td>
					</tr>
%for log in records:
%if log['date'] >= thisweek_beginning_time and log['date'] <= thisweek_end_time:
					<tr>
						<td>{{time.asctime(time.localtime(log['date']))}}</td>
						<td>{{log['host']}}</td>
						<td>{{log['service']}}</td>
						<td>{{log['message']}}</td>
					</tr>
%end
%end
				</tbody>
			</table>
		</div>
		<div class="tab-pane" id="lastweek">
			<table class="table table-striped">
				<tbody>
					<tr>
						<td colspan="4"><strong>From {{time.asctime(time.localtime(lastweek_beginning_time))}} to {{time.asctime(time.localtime(lastweek_end_time))}}</strong></td>
					</tr>
%for log in records:
%if log['date'] >= lastweek_beginning_time and log['date'] <= lastweek_end_time:
					<tr>
						<td>{{time.asctime(time.localtime(log['date']))}}</td>
						<td>{{log['host']}}</td>
						<td>{{log['service']}}</td>
						<td>{{log['message']}}</td>
					</tr>
%end
%end
				</tbody>
			</table>
		</div>
		<div class="tab-pane" id="custom">
			<label>Custom log range</label>
			<div class="row-fluid input">
				<div class="inline-inputs">
					From
					<input name='from_day' data-datepicker="datepicker" class="input input-small" type="text" value="" />
					<input name='from_hour' class="input input-mini" type="text" value="" />
					to
					<input name='to_day' data-datepicker="datepicker" class="input input-small" type="text" value="" />
					<input name='to_hour' class="intput input-mini" type="text" value="" />
				</div>
			</div>
		</div>
	</div>

</div>

