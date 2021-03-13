component {
	public void function configure( required any binder ) {
		var settings = arguments.binder.getColdbox().getSettingStructure();

		arguments.binder.map( "CsvImporterStorageProvider" ).asSingleton().to( "preside.system.services.fileStorage.FileSystemStorageProvider" ).noAutoWire()
			.initArg( name="rootDirectory"   , value=settings.uploads_directory & "/csv-import"  )
			.initArg( name="privateDirectory", value=settings.uploads_directory & "/csv-import"  )
			.initArg( name="trashDirectory"  , value=settings.uploads_directory & "/.trash" )
			.initArg( name="rootUrl"         , value="" );
	}
}