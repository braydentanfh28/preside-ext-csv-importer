component extends="preside.system.base.AdminHandler" {
	property name="csvImportService" inject="CsvImportService";
	property name="csvFileProvider"  inject="CsvImporterStorageProvider";

	public void function preHandler( event, rc, prc, args={} ) {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "csvImporter" ) ) {
			event.notFound();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:csvImporter.title" )
			, link  = event.buildAdminLink( linkto="csvImporter.index" )
		);

		prc.pageIcon = "upload";

		// include assets
		event.include( "/css/admin/specific/csv-import/" )
			 .include( "/js/admin/specific/csv-import/"  );
	}

	public void function index( event, rc, prc, args={} ) {
		prc.pageTitle    = translateResource( "cms:csvImporter.title" );
		prc.pageSubtitle = translateResource( "cms:csvImporter.subtitle" );
	}

	public void function uploadFileAction( event, rc, prc, args={} ) {
		var formData         = event.getCollectionForForm();
		var validationResult = validateForms();

		if ( !validationResult.validated() ) {
			messageBox.warn( translateResource( uri="csvImporter:error.upload.file.message" ) );

			setNextEvent(
				  url           = event.buildAdminLink( linkto="csvImporter.index" )
				, persistStruct = formData
			);
		}

		var filePath = formData.object & "|" & ( isTrue( formData.has_header ) ? "wheader" : "woheader" ) & "|" & createUUID() & ".csv";

		csvFileProvider.putObject(
			  object = fileReadBinary( formData.file )
			, path   = filePath
		)

		setNextEvent( url=event.buildAdminLink(
			  linkto      = "csvImporter.importMapping"
			, queryString = "file_path=#filePath#"
		) );
	}

	public void function importMapping( event, rc, prc, args={} ) {
		_csvImportMappingCheck( argumentCollection=arguments );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:csvImporter.filemapping.title" )
			, link  = event.buildAdminLink( linkto="csvImporter.importMapping", queryString="file_path=#rc.file_path#" )
		);

		prc.pageTitle = translateResource( "cms:csvImporter.filemapping.title" );
		prc.formName  = csvImportService.createCsvMappingForm( filePath=rc.file_path );

		if ( isEmptyString( prc.formName ) ) {
			messageBox.warn( translateResource( uri="csvImporter:error.missing.mapping.form.message" ) );

			setNextEvent( url=event.buildAdminLink( linkto="csvImporter.index" ) );
		}

		prc.availCols  = csvImportService.getCsvFileColumns( filePath=rc.file_path );
		prc.withHeader = ( ( listToArray( rc.file_path, "|" )[2] ?: "" ) eq "wheader" ) ? true : false;
	}

	public void function importMappingAction( event, rc, prc, args={} ) {
		_csvImportMappingCheck( argumentCollection=arguments );

		var formData         = event.getCollectionForForm();
		var validationResult = validateForms();

		if ( !validationResult.validated() ) {
			setNextEvent(
				  url           = event.buildAdminLink( linkto="csvImporter.importMapping", queryString="file_path=#rc.file_path ?: ""#" )
				, persistStruct = formData
			);
		}

		var taskId = createTask(
			  event      = "admin.CsvImporter._runCsvImportInBgThread"
			, runNow     = true
			, adminOwner = event.getAdminUserId()
			, title      = "csvImporter:import.csv.task.title"
			, returnUrl  = event.buildAdminLink( linkto="csvImporter.importMapping" )
			, args       = {
				  filePath = rc.file_path
				, mapping  = formData
			}
		);

		setNextEvent( url=event.buildAdminLink(
			  linkTo      = "adhoctaskmanager.progress"
			, queryString = "taskId=#taskId#"
		) );
	}

// PRIVATE HELPERS
	private void function _runCsvImportInBgThread( event, rc, prc, args={}, logger, progress ) {
		csvImportService.runCsvImport(
			  filePath = args.filePath
			, mapping  = args.mapping
			, logger   = arguments.logger ?: nullValue()
		);
	}

	private void function _csvImportMappingCheck( event, rc, prc, args={} ) {
		if ( !csvFileProvider.objectExists( path=rc.file_path ?: "" ) ) {
			messageBox.warn( translateResource( uri="csvImporter:error.missing.file.message" ) );

			setNextEvent( url=event.buildAdminLink( linkto="csvImporter.index" ) );
		}
	}
}