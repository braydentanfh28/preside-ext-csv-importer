/**
 * @singleton      true
 * @presideService true
 */
component {

	/**
	 * @formsService.inject          FormsService
	 * @csvStorageProvider.inject    CsvImporterStorageProvider
	 * @csvImporterConfig.inject     coldbox:setting:csvImporter
	 */
	public any function init(
		  required any    formsService
		, required any    csvStorageProvider
		, required struct csvImporterConfig
	) {
		_setFormsService( arguments.formsService );
		_setCsvStorageProvider( arguments.csvStorageProvider );
		_setCsvImporterConfig( arguments.csvImporterConfig );

		return this;
	}

// PUBLIC FUNCTIONS
	public array function getImportEnabledObjects() {
		var objs    = [];
		var allObjs = $getPresideObjectService().listObjects();

		for ( var obj in allObjs ) {
			var importEnabled = $getPresideObjectService().getObjectAttribute( objectName=obj, attributeName="csvImportEnabled" );

			if ( $helpers.isTrue( importEnabled ) ) {
				var uriRoot = $getPresideObjectService().getResourceBundleUriRoot( objectName=obj );

				objs.append( {
					  value = obj
					, label = $translateResource(
						  uri          = uriRoot & "title.singular"
						, defaultValue = $translateResource(
							  uri          = uriRoot & "title"
							, defaultValue = obj
						)
					)
				} );
			}
		}

		return objs;
	}

	public string function createCsvMappingForm( required string filePath ) {
		var pathSplit = listToArray( arguments.filePath, "|" );

		if ( arrayLen( pathSplit ) eq 3 ) {
			var object     = pathSplit[1];
			var props      = $getPresideObjectService().getObjectProperties( objectName=object );
			var i18nRoot   = $getPresideObjectService().getResourceBundleUriRoot( objectName=object );
			var withHeader = ( pathSplit[2] eq "wheader" ) ? true : false;
			var uuid       = replace( pathSplit[3], ".csv", "" );

			var allowFields  = $getPresideObjectService().getObjectAttribute( objectName=object, attributeName="csvImportAllowFields" );
			var isAllAllowed = $helpers.isEmptyString( allowFields );

			return _getFormsService().createForm( basedOn="csvImporter.csv.mapping.base", formName="csv-mapping-#uuid#", generator=function( definition ) {
				for ( var prop in props ) {
					if ( ( props[prop].generator eq "none"   ) and
						 ( props[prop].generate neq "insert" ) and
						 ( props[prop].control  neq "none"   )
					) {
						if ( isAllAllowed or listFind( allowFields, prop ) ) {
							definition.addField(
								  tab      = "default"
								, fieldset = "default"
								, name     = props[prop].name
								, label    = $translateResource( uri="#i18nRoot#field.#props[prop].name#.title", defaultValue=props[prop].name )
								, control  = "textinput"
								, required = props[prop].required ?: false
								, class    = "csv-import-mapping-drop"
							);
						}
					}
				}
			});
		}

		return "";
	}

	public array function getCsvFileColumns( required string filePath ) {
		var availCols  = [];
		var csvFileObj = fileOpen( expandPath( "uploads/csv-import/#filePath#" ) );

		try {
			availCols = listToArray( fileReadLine( csvFileObj ) );
		} catch (any e) {
			$raiseError( e );
		} finally {
			fileClose( csvFileObj );
		}

		return availCols;
	}

	public void function runCsvImport(
		  required string filePath
		, required struct mapping
		,          any    logger = nullValue()
	) {
		var canLog    = StructKeyExists( arguments, "logger" );
		var canInfo   = canLog && arguments.logger.canInfo();
		var canWarn   = canLog && arguments.logger.canWarn();
		var canError  = canLog && arguments.logger.canError();
		var pathSplit = listToArray( arguments.filePath, "|" );

		if ( arrayLen( pathSplit ) eq 3 ) {
			var lineNo       = 1;
			var mappedConfig = {};
			var object       = pathSplit[1];
			var props        = $getPresideObjectService().getObjectProperties( objectName=object );
			var withHeader   = ( pathSplit[2] eq "wheader" ) ? true : false;
			var csvFileObj   = fileOpen( expandPath( "uploads/csv-import/#arguments.filePath#" ) );

			for ( var prop in props ) {
				if ( !$helpers.isEmptyString( arguments.mapping[ prop ] ?: "" ) ) {
					mappedConfig[ prop ] = right( left( arguments.mapping[ prop ], "-1" ), "-2" );
				}
			}

			if ( !isEmpty( mappedConfig ) and $getPresideObjectService().objectExists( objectName=object ) ) {
				try {
					var mappedArrIds = {};

					while ( !fileIsEOF( csvFileObj ) ) {
						var mappedData = {};
						var line       = listToArray( fileReadLine( csvFileObj ) );

						if ( lineNo eq 1 ) {
							mappedArrIds = _mapCsvLineArrayIds(
								  config = mappedConfig
								, line   = line
							);

							if ( isEmpty( mappedArrIds ) ) {
								if ( canError ) {
									arguments.logger.error( "Unable to map the configuration with uploaded CSV file!" );
								}

								break;
							}
						}

						mappedData = _processCsvConfigMappedData(
							  arrIds = mappedArrIds
							, line   = line
						);

						if ( withHeader and lineNo eq 1 ) {
							arguments.logger.info( "Imported file has header, skipping header row during import." );
						} else {
							if ( !isEmpty( mappedData ) ) {
								$getPresideObject( object ).insertData( data=mappedData );
							}
						}

						if ( ( ( lineNo % 10 ) eq 0 ) and canInfo ) {
							arguments.logger.info( "Processed #lineNo# lines..." );
						}

						lineNo++;
					}
				} catch (any e) {
					$raiseError( e );

					if ( canError ) {
						arguments.logger.error( e.message );
					}
				} finally {
					fileClose( csvFileObj );
				}

				if ( canInfo ) {
					if ( withHeader ) {
						arguments.logger.info( "Successfully import #lineNo - 2# record(s)" );
					} else {
						arguments.logger.info( "Successfully import #lineNo - 1# record(s)" );
					}
				}
			} else {
				if ( canWarn ) {
					arguments.logger.warn( "Mapped configuration with uploaded CSV file!is empty! Import process had stopped without any actions." );
				}
			}
		} else {
			if ( canError ) {
				arguments.logger.error( "Error occur during mapping and import the content of the uploaded CSV file!" );
				arguments.logger.error( "Please try upload and map the column(s) again" );
			}
		}
	}

	public boolean function cleanUpOldUploadedFiles( any logger ) {
		var canLog        = StructKeyExists( arguments, "logger" );
		var canInfo       = canLog && logger.canInfo();
		var canWarn       = canLog && logger.canWarn();
		var canError      = canLog && logger.canError();
		var persistInDays = _getCsvImporterConfig().files.persistInDays ?: 14;
		var allFiles      = _getCsvStorageProvider().listObjects( path="/" );

		if ( allFiles.recordcount ) {
			var cleaned = 0;
			if ( canInfo ) {
				arguments.logger.info( "Start checking through #allFiles.recordcount# files." );
			}

			for ( var file in allFiles ) {
				try {
					if ( dateDiff( "d", file.lastmodified, now() ) gt persistInDays ) {
						_getCsvStorageProvider().deleteObject( path=file.path );
						cleaned ++;

						if ( canWarn ) {
							arguments.logger.warn( "Removing #file.name# ..." );
						}
					}
				} catch (any e) {
					if ( canError ) {
						arguments.logger.error( e.message );
					}
				}
			}

			if ( cleaned gt 0 ) {
				if ( canInfo ) {
					arguments.logger.info( "Cleaned #cleaned# file(s) which uploaded more than #persistInDays# days ago." );
				}
			} else {
				if ( canInfo ) {
					arguments.logger.info( "No file required to be cleaned." );
				}
			}
		} else {
			if ( canInfo ) {
				arguments.logger.info( "There isn't any uploaded file to clean up. :)" );
			}
		}

		return true;
	}

// PRIVATE HELPERS
	private struct function _processCsvConfigMappedData(
		  required struct arrIds
		, required array  line
	) {
		var mapped = {};

		for ( var field in arguments.arrIds ) {
			mapped[ field ] = arguments.line[ arguments.arrIds[ field ] ];
		}

		return mapped;
	}

	private struct function _mapCsvLineArrayIds(
		  required struct config
		, required array  line
	) {
		var arrayIds = {};

		for ( var c in arguments.config ) {
			for ( var i=1; i<=arrayLen( arguments.line ); i++ ) {
				if ( arguments.config[c] eq arguments.line[i] ) {
					arrayIds[c] = i;
				}
			}
		}

		return arrayIds;
	}

// GETTER AND SETTER
	private any function _getFormsService() {
		return _formsService;
	}
	private void function _setFormsService( required any formsService ) {
		_formsService = arguments.formsService;
	}

	private any function _getCsvStorageProvider() {
		return _csvStorageProvider;
	}
	private void function _setCsvStorageProvider( required any csvStorageProvider ) {
		_csvStorageProvider = arguments.csvStorageProvider;
	}

	private any function _getCsvImporterConfig() {
		return _csvImporterConfig;
	}
	private void function _setCsvImporterConfig( required struct csvImporterConfig ) {
		_csvImporterConfig = arguments.csvImporterConfig;
	}
}