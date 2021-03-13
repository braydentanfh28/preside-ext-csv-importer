component {

	public void function configure( required struct config ) {
		var interceptors = arguments.config.interceptors ?: {};
		var settings     = arguments.config.settings     ?: {};

		_setupExtConfig(     settings );
		_setupExtFeatures(   settings );
		_setupCongMenuItems( settings );
	}

	private void function _setupExtConfig( required any settings ) {
		settings.csvImporter = settings.csvImporter ?: {};

		settings.csvImporter.files.persistInDays = 14;
	}

	private void function _setupExtFeatures( any settings ) {
		settings.features = settings.features ?: {};

		settings.features.csvImporter = { enabled=true };
	}

	private void function _setupCongMenuItems( any settings ) {
		settings.adminConfigurationMenuItems = settings.adminConfigurationMenuItems ?: [];

		settings.adminConfigurationMenuItems.append( "csvImporter" );
	}
}