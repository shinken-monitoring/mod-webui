<!-- DOCUMENTATION MODAL -->
<div class="modal-header">
  <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
  <h3 class="modal-title">Searching hosts and services</h3>
</div>

<div class="modal-body">
  To search for services and hosts (elements), use the following search qualifiers in any combination.

  <h4>Search hosts or services</h4>
  <p>
    By default, searching for elements will return both hosts and services. However, you can use the type qualifier to restrict search results to hosts or services only.
  </p>
  <code>www type:host</code> Matches hosts with "www" in their hostname.

  <h4>Search by the state of an element</h4>
  <p>The <code>is</code> and <code>isnot</code> qualifiers finds elements by a certain state. For example:</p>
  <code>is:DOWN</code> Matches hosts that are DOWN.<br>
  <code>isnot:0</code> Matches services and hosts that are not OK or UP (all the problems). Equivalent to <code>isnot:OK isnot:UP</code><br>
  <code>load isnot:ok</code> Matches services with the word "load", in states warning, critical, unknown or pending.<br>
  <code>is:ack</code> Matches elements that are acknownledged.<br>
  <code>is:downtime</code> Matches elements that are in a scheduled downtime.<br>

  <h4>Search by the business impact of an element</h4>
  <p>The <code>bp</code> qualifier finds elements by it's business priority. For example:</p>
  <code>bp:5</code> Matches hosts and services that are top for business.<br>
  <code>bp:>1</code> Matches hosts and services with a business impact greater than 1.<br>

  <h4>Search by host group, service group, contact, host tag and service tag</h4>
  Examples:
  <code>hg:infra</code> Matches hosts in the group "infra".<br>
  <code>sg:shinken</code> Matches services in the group "shinken".<br>
  <code>cg:admin</code> Matches hosts and services related to "admin" contact.<br>
  <code>htag:linux</code> Matches hosts tagged "linux".<br>
  <code>stag:mysql</code> Matches services tagged "mysql".<br>
  Obviously, you can't combine htag and stag qualifiers in a search and expect to get results.

  <h4>Find hosts and services by realm</h4>
  <p>The <code>realm</code> qualifier finds elements by a certain realm. For example:</p>
  <code>realm:aws</code> Matches all AWS hosts and services.
</div>
