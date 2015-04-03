%rebase layout title='Shinken UI login', print_menu=False



%# " If the auth succeed, we go in the /problems page "
%if is_auth:
<script type="text/javascript">
  window.location.replace("/dashboard");
</script>
%else: # " Ok, not good, came back at login page."
<script type="text/javascript">
  window.location.replace("/login");
</script>
%end
