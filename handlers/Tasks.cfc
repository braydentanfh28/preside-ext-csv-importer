component {
	property name="csvImportService" inject="csvImportService";

	/**
	 * @priority        5
	 * @schedule        0 30 4 * * *
	 * @timeout         120
	 * @displayName     Clean up uploaded CSV files
	 * @displayGroup    CSV import
	 */
	private boolean function csvImportCleanUpOldFiles( event, rc, prc, logger ) {
		return csvImportService.cleanUpOldUploadedFiles( logger=arguments.logger ?: nullValue() );
	}
}