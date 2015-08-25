<!-- DOCUMENTATION MODAL -->
<div class="modal-header">
  <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
  <h3 class="modal-title">Searching hosts and services</h3>
</div>

<div class="modal-body">
  <p>To search for services and hosts (elements), use the following search qualifiers in any combination.</p>

  <h4>Search hosts or services</h4>
  <p>
    By default, searching for elements will return both hosts and services. However, you can use the type qualifier to restrict search results to hosts or services only.
  </p>
  <ul>
    <li><code>www type:host</code> Matches hosts with "www" in their hostname.</li>
  </ul>

  <h4>Search by the state of an element</h4>
  <p>The <code>is</code> and <code>isnot</code> qualifiers finds elements by a certain state. For example:</p>
  <ul>
    <li><code>is:DOWN</code> Matches hosts that are DOWN.</li>
    <li><code>isnot:0</code> Matches services and hosts that are not OK or UP (all the problems). Equivalent to <code>isnot:OK isnot:UP</code></li>
    <li><code>load isnot:ok</code> Matches services with the word "load", in states warning, critical, unknown or pending.</li>
    <li><code>is:ack</code> Matches elements that are acknownledged.</li>
    <li><code>is:downtime</code> Matches elements that are in a scheduled downtime.</li>
  </ul>

  <h4>Search by the business impact of an element</h4>
  <p>The <code>bp</code> qualifier finds elements by it's business priority. For example:</p>
  <ul>
    <li><code>bp:5</code> Matches hosts and services that are top for business.</li>
    <li><code>bp:>1</code> Matches hosts and services with a business impact greater than 1.</li>
  </ul>

  <h4>Search by duration</h4>
  <p>You can also search by the duration of the last state change. This is very useful to find elements that are warning or critical for a long time. For example:</p>
  <ul>
    <li><code>isnot:OK duration:>1w</code> Matches hosts and services not OK for at least one week.</li>
    <li><code>isnot:OK duration:<1h</code> Matches hosts and services not OK for less than one hour.</li>
  </ul>
  <p>You can use the following time units: s(econds), m(inutes), h(ours), d(ays), w(eeks).</p>

  <p>Of course, you can't use the "=" sign here. Finding something that is exactly matching would be a huge luck.</p>

  <h4>Search by host group, service group, host tag and service tag</h4>
  <p>Examples:</p>
  <ul>
    <li><code>hg:infra</code> Matches hosts in the group "infra".</li>
    <li><code>sg:shinken</code> Matches services in the group "shinken".</li>
    <li><code>htag:linux</code> Matches hosts tagged "linux".</li>
    <li><code>stag:mysql</code> Matches services tagged "mysql".</li>
  </ul>

  <p>Obviously, you can't combine htag and stag qualifiers in a search and expect to get results.</p>

  <h4>Search by contact group and contact tag</h4>
  <p>Examples:</p>
  <ul>
    <li><code>cg:admins</code> Matches hosts and services related to contacts in contact group "admins".</li>
    <li><code>ctag:client</code> Matches hosts and services related to contacts tagged "client".</li>
  </ul>

  <h4>Find hosts and services by realm</h4>
  <p>The <code>realm</code> qualifier finds elements by a certain realm. For example:</p>
  <ul>
    <li><code>realm:aws</code> Matches all AWS hosts and services.</li>
  </ul>
</div>
