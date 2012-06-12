<cfcomponent extends="wheelsMapping.Test">

	<cffunction name="setup">
		<cfset loc.controller = controller(name="dummy")>
		<cfset loc.formbuilder = $createObjectFromRoot(
			path = "wheels"
			,fileName="FormBuilder"
			,method = "init"
		)>
		<cfset user = model("user").findOne(where="lastname = 'Petruzzi'")>		
	</cffunction>
	
	<cffunction name="test_basic_start_and_end_form_tag_with_post_method">
		<cfset loc.argsction = loc.controller.urlfor()>
		<cfset loc.e = '<form action="#loc.argsction#" method="post"></form>'>
		<cfset loc.r = loc.formbuilder.start(model="User").end()>
		<cfset assert('loc.e eq loc.r')>
	</cffunction>
	
	<cffunction name="test_basic_start_and_end_tag_with_get_method">
		<cfset loc.argsction = loc.controller.urlfor()>
		<cfset loc.e = '<form action="#loc.argsction#" method="get"></form>'>
		<cfset loc.r = loc.formbuilder.start(model="User", method="get").end()>
		<cfset assert('loc.e eq loc.r')>
	</cffunction>
	
	<cffunction name="test_basic_form_tag_to_external_site_explicit_http">
		<cfset loc.e = '<form action="http://www.google.com" method="post"></form>'>
		<cfset loc.r = loc.formbuilder.start(model="User", action="http://www.google.com").end()>
		<cfset assert('loc.e eq loc.r')>
	</cffunction>
	
	<cffunction name="test_basic_form_tag_with_put_method">
		<cfset loc.argsction = loc.controller.urlfor()>
		<cfset loc.e = '<form action="#loc.argsction#" method="post"><input id="_method" name="_method" type="hidden" value="put" /></form>'>
		<cfset loc.r = loc.formbuilder.start(model="User", method="put").end()>
		<cfset assert('loc.e eq loc.r')>
	</cffunction>
	
	<cffunction name="test_basic_start_and_end_tag_with_pout_method">
		<cfset loc.argsction = loc.controller.urlfor()>
		<cfset loc.e = '<form action="#loc.argsction#" method="get"></form>'>
		<cfset loc.r = loc.formbuilder.start(model="User", method="get").end()>
		<cfset assert('loc.e eq loc.r')>
	</cffunction>
	
	<cffunction name="test_basic_form_tag_to_external_site_using_urlfor">
		<cfset loc.e = '<form action="http://www.google.com" method="post"></form>'>
		<cfset loc.r = loc.formbuilder.start(model="User", action="http://www.google.com").end()>
		<cfset assert('loc.e eq loc.r')>
	</cffunction>
	
	<cffunction name="test_basic_form_with_input_tag">
		<cfset loc.argsction = loc.controller.urlfor()>
		<cfset loc.e = '<form action="#loc.argsction#" method="post"><label for="firstName">First Name<input id="firstName" name="firstName" type="text" value="Tony" /></label></form>'>
		<cfset loc.r = loc.formbuilder
						.start(model=user)
						.textField(label="First Name", property="firstName")
						.end()>
		<cfset assert('loc.e eq loc.r')>
	</cffunction>

	<cffunction name="test_create_hidden_method_field_for_put_and_push_with_post_as_main_method">
		<cfset loc.argsction = loc.controller.urlfor()>
		<cfset loc.e = '<form action="#loc.argsction#" enctype="multipart/form-data" method="post"><label for="firstName">First Name<input id="firstName" name="firstName" type="file" /></label></form>'>
		<cfset loc.r = loc.formbuilder
						.start(model=user)
						.fileField(label="First Name", property="firstName")
						.end()>
		<cfset assert('loc.e eq loc.r')>
	</cffunction>

</cfcomponent>