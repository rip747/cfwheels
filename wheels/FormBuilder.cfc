<cfcomponent output="false">
	
	<cfscript>
	variables.instance = {};
	// store the output for later rendering
	variables.instance.output = [];
	// track the level that we are at
	variables.instance.level = 1;
	variables.instance.startFormTagAttributes = {};
	variables.instance.FormFieldsObj = createobject("component", "FormFields").init();
	</cfscript>

	<cffunction name="init">
		<cfreturn this>
	</cffunction>
	
	<cffunction name="start" access="public" returntype="any" output="false">
		<cfargument name="model" type="any" required="true" hint="the model to generate the form for">
		<cfscript>
		variables.instance.model = arguments.model;
		// all other arguments passed in are used as default for the start form tag
		StructDelete(arguments, "model", false);
		variables.instance.startFormTagAttributes = arguments;
		</cfscript>
		<cfreturn this>
	</cffunction>
	
	<cffunction name="end" access="public" returntype="any" output="false">
		<cfscript>
		var loc = {};
		loc.ret = this;
		
		if ($atRootLevel())
		{
			// support put and push methods
			if (StructKeyExists(variables.instance.startFormTagAttributes, "method") && ListFindNoCase("put,push", variables.instance.startFormTagAttributes["method"]))
			{
				ArrayAppend(variables.instance.output, variables.instance.FormFieldsObj.hiddenFieldTag("_method", variables.instance.startFormTagAttributes["method"]));
				variables.instance.startFormTagAttributes["method"] = "post";
			}
			
			ArrayPrepend(variables.instance.output, variables.instance.FormFieldsObj.startFormTag(argumentCollection=variables.instance.startFormTagAttributes));
			ArrayAppend(variables.instance.output, variables.instance.FormFieldsObj.endFormTag());
			loc.ret = ArrayToList(variables.instance.output, "");
		}
		</cfscript>
		<cfreturn loc.ret>
	</cffunction>
	
	<cffunction name="$atRootLevel" access="public" returntype="boolean" output="false">
		<cfreturn variables.instance.level eq 1>
	</cffunction>
	
	<cffunction name="onMissingMethod" returntype="any" access="public" output="false">
		<cfargument name="missingMethodName" type="string" required="true">
		<cfargument name="missingMethodArguments" type="struct" required="true">
		<cfset var loc = {}>
		<cfset arguments.missingMethodArguments["objectName"] = variables.instance.model>
		<!--- mark the form as an upload --->
		<cfif arguments.missingMethodName eq "fileField">
			<cfset variables.instance.startFormTagAttributes["multipart"] = true>
		</cfif>
		<cfinvoke component="#variables.instance.FormFieldsObj#" method="#arguments.missingMethodName#" argumentcollection="#arguments.missingMethodArguments#" returnvariable="loc.ret">
		<cfset ArrayAppend(variables.instance.output, loc.ret)>
		<cfreturn this>
	</cffunction>

</cfcomponent>