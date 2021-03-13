<cfif isFeatureEnabled( "csvImporter" )>
	<cfoutput>
		<li>
			<a href="#event.buildAdminLink( linkto="CsvImporter" )#">
				<i class="fa fa-fw fa-upload"></i>
				#translateResource( 'cms:csvImporter' )#
			</a>
		</li>
	</cfoutput>
</cfif>