$(document).ready(function() {

	$('#notes').click(function() {
			$('.circles').removeClass('active');
			var id = '#s-' + $(this).attr('id');
			var $lefty = $(id);
			$('#slider-container > div.slider').animate({
				left: -1000
			});
			$('#slider-container').height(parseInt($lefty.css('height'),10));
			$lefty.animate({
				left: parseInt($lefty.css('left'),10) == 0 ?
				-$lefty.outerWidth() :
				0
			});
	});

	$('#header div').click(function() {
		if (!$(this).hasClass( 'active' )) {
			$('.circles').removeClass('active');
			$(this).addClass('active');
			var id = '#s-' + $(this).attr('id');
			var $lefty = $(id);
			$('#slider-container > div.slider').animate({
				left: -1000
			});
			$('#slider-container').height(parseInt($lefty.css('height'),10));
			$lefty.animate({
				left: parseInt($lefty.css('left'),10) == 0 ?
				-$lefty.outerWidth() :
				0
			});
		}
	});


	$('a[rel*=facebox]').facebox();
	
	$('.tooltip').poshytip({
		className: 'tip-twitter',
		showTimeout: 1,
		alignTo: 'target',
		alignX: 'center',
		offsetY: 20,
		allowTipHover: false,
		fade: false,
	});
	$('#contact-me a').poshytip({
		className: 'tip-twitter',
		showTimeout: 1,
		alignTo: 'target',
		alignX: 'center',
		offsetY: 5,
		allowTipHover: false,
		fade: false,
	});

});

