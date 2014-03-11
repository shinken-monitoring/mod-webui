
// when we show a tab, we put the #hash on the windows address so the refresh will go here
$(window).ready(function(){
	var gotoHashTab = function (customHash) {
		// console.log('Current hash: '+window.location.hash);
		var hash = customHash || location.hash;
		var hashPieces = hash.split('?'),
			activeTab = $('[href=' + hashPieces[0] + ']');
		// console.log('activeTab'+activeTab);
		activeTab && activeTab.tab('show');
	}

	// onready go to the tab requested in the page hash
	gotoHashTab();

	// when the nav item is selected update the page hash
	$('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
		window.location.hash = $(e.target).attr('href');
	})
});
