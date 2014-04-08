$(document).ready(function(){

	$('#toggle-switcher').click(function(){
		if($(this).hasClass('opened')){
			$(this).removeClass('opened');
			$('#style-switcher').animate({'right':'-222px'});
		}else{
			$(this).addClass('opened');
			$('#style-switcher').animate({'right':'-10px'});
		}
	});
	
	$('#style-switcher li').click(function(e){
		e.preventDefault();
		
		$elem = $(this);
		
		$('link#theme').attr('href', 'css/qubico-'+$elem.attr('id')+'.css');
		
		$('.logo-small img').attr('src', 'assets/logo-small-'+$elem.attr('id')+'.png');
		
		$('link#theme').load(function(){
			$('link#main').attr('href', 'css/qubico-'+$elem.attr('id')+'.css');
		});
		
	});
});