( function( $ ){
	var dropableInput   = $( "input.csv-import-mapping-drop" )
	  , dragableContent = $( ".draggable-content" );

	dragableContent.on( "dragstart", function(event) {
		event.originalEvent.dataTransfer.setData( "text", event.target.id );
	});

	dropableInput.on( "drop", function(event) {
		event.preventDefault();
		event.stopPropagation();

		var data = event.originalEvent.dataTransfer.getData("text");
		$(this).val( $( "#" + data ).text().trim() );
	});

	dropableInput.on( "dragover", function(event) {
		event.preventDefault();
	});
} )( presideJQuery );