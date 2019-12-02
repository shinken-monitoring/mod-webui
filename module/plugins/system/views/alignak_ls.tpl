%rebase("layout", title='Alignak livesynthesis', css=['system/css/alignak.css'], js=['system/js/jquery.floatThead.min.js'], breadcrumb=[ ['Alignak livesynthesis', '/alignak/ls'] ])

%helper = app.helper

<div class="col-sm-12 panel panel-default">
   <div class="panel-body">
   %if not ls:
      <center>
         <h3>No live synthesis information is available.</h3>
      </center>
   %else:
   %end
   </div>
</div>
