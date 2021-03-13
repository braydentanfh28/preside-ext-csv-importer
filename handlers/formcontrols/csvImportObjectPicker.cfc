component {
	property name="csvImportService" inject="CsvImportService";

	private string function index( event, rc, prc, args={} ) {
		var items = csvImportService.getImportEnabledObjects();

		if ( !items.len() ) {
			return "";
		}

		args.labels = [ "" ];
		args.values = [ "" ];

		for ( var item in items ) {
			args.labels.append( item.label );
			args.values.append( item.value );
		}

		return renderView( view="/formcontrols/select/index", args=args );
	}
}