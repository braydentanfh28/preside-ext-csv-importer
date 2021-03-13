<cfscript>
	objectList = prc.objectList ?: [];
	formId     = "csvimport-" & createUUID();
</cfscript>

<cfoutput>
	<form class="form-horizontal"
		  id="#formId#"
		  method="post"
		  action="#event.buildAdminLink( linkTo="csvImporter.uploadFileAction" )#"
		  enctype="multipart/form-data"
	>
		#renderForm(
			  formName = "csvImporter.csv.file.upload"
			, formId   = formId
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-upload bigger-110"></i>
					#translateResource( "csvImporter:upload.file.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>