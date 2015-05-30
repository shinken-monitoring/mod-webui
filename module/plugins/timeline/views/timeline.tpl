%rebase("layout", js=['timeline/js/timeline.js'], css=['timeline/css/timeline.css'], title='Timeline')

<h3>Downtimes timeline for {{hostname}}</h3>
<div id="mytimeline"> Test de fred ...</div>

<script>
	$(document).ready(function() {
		var timeline;
		var data;

		// Called when the Visualization API is loaded.
		function drawTimeline() {
			// specify options
			var options = {
				'width':  '100%',
				'height': 'auto',
				'editable': false,
				'style': 'box'
			};

			// Instantiate our timeline object.
			timeline = new links.Timeline(document.getElementById('mytimeline'));

			function onRangeChanged(properties) {
				document.getElementById('info').innerHTML += 'rangechanged ' +
						properties.start + ' - ' + properties.end + '<br>';
			}

			// attach an event listener using the links events handler
			links.events.addListener(timeline, 'rangechanged', onRangeChanged);

			$.ajax({
				url: '/timeline/json/{{hostname}}',
				success: function(html){
					timeline.draw(html, options);
				},
				error: function(xhr) {
					this.html('Error loading data !');
					console.log( xhr);
				}
			});
		}

		drawTimeline();
	});
</script>
