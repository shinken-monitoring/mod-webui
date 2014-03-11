%rebase layout globals(), js=['timeline/js/timeline.js', 'timeline/js/storyjs-embed.js'], css=['timeline/css/timeline.css'], title='Timeline'

<div id="timeline"></div>

<script>
	$(document).ready(function() {
		createStoryJS({
			type:			'timeline',
			width:			'1024',
			height:			'600',
			source:			"/timeline/json/{{hostname}}",
			embed_id:		'timeline',
			start_at_end:	false
		});
	});

</script>
