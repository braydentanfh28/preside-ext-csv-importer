<cfscript>
	formId     = "csvmapping-" & createUUID();
	formName   = prc.formName   ?: "";
	availCols  = prc.availCols  ?: [];
	withHeader = prc.withHeader ?: false;
</cfscript>

<cfoutput>
	<div class="row csv-import-mapping">
		<div class="col-md-8">
			<h3 class="header smaller lighter green">
				Object's fields
			</h3>

			<form class="form-horizontal csv-import-mapping-form"
				  id="#formId#"
				  method="post"
				  action="#event.buildAdminLink( linkTo="csvImporter.importMappingAction" )#"
			>
				<input type="hidden" name="file_path" value="#rc.file_path ?: ""#" />

				#renderForm(
					  formName = formName
					, formId   = formId
				)#

				<div class="form-actions row">
					<div class="col-md-offset-2">
						<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
							<i class="fa fa-upload bigger-110"></i>
							#translateResource( "csvImporter:import.csv.btn" )#
						</button>
					</div>
				</div>
			</form>
		</div>

		<div class="col-md-4">
			<h3 class="header smaller lighter green">
				<cfif isTrue( withHeader )>
					Available columns
				<cfelse>
					Previewing 1st row data
				</cfif>
			</h3>
			<div class="well csv-import-mapping-columns">

				<cfloop array="#availCols#" item="col" index="i">
					<h5 class="lighter">
						<code id="draggable-content-#i#" class="draggable-content" draggable="true">
							<i>${#col#}</i>
						</code>
					</h5>
					<hr />
				</cfloop>
			</div>
		</div>
	</div>
</cfoutput>