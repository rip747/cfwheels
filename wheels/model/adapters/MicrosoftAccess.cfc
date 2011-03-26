<cfcomponent extends="Base" output="false">

	<cffunction name="$generatedKey" returntype="string" access="public" output="false">
		<cfreturn "identitycol">
	</cffunction>
	

	<cffunction name="$randomOrder" returntype="string" access="public" output="false">
		<cfreturn "NEWID()">
	</cffunction>

	<!--- Phord change $getType --->	
	<cffunction name="$getType" returntype="string" access="public" output="false">
		<!--- Access data type:  Memo   to   LongText   to   cf_sql_clob . --->
		<!--- Using cf_sql_clob truncates a MSAccess Memo field to 65536 chars if submitted from a textarea. --->
		<!--- Using cf_sql_longvarchar throws a CF error if the MSAccess Memo field is more than 65536 chars.  --->
		<!--- Unfortunately COLUMN_SIZE returns 0 for a MS Access Memo field. It should return 65536. --->
		<!--- Therefore cf_sql_clob works best for Memo fields --->
		<!--- Currency might be better as cf_sql_decimal, however MSAccess stores Currency as double --->
		<!--- MSAccess Yes/No fields become cf_sql_bit. A default value (true or false) needs to be assigned to a Yes/No field in MSAccess or the table can't be accessed & throws a CF error' --->
		<cfargument name="type" type="string" required="true">
		<cfscript>
			var loc = {};
			switch(arguments.type)
			{
				case "": case "varchar": case "char": case "nvarchar": case "nchar": {loc.returnValue = "cf_sql_varchar"; break;}
				case "longtext": {loc.returnValue = "cf_sql_clob"; break;}
				case "byte": {loc.returnValue = "cf_sql_tinyint"; break;}
				case "decimal": {loc.returnValue = "cf_sql_decimal"; break;}
				case "short": {loc.returnValue = "cf_sql_smallint"; break;}
				case "long": {loc.returnValue = "cf_sql_integer"; break;}
				case "single": {loc.returnValue = "cf_sql_real"; break;}
				case "double": case "currency": {loc.returnValue = "cf_sql_double"; break;}
				case "bit": {loc.returnValue = "cf_sql_bit"; break;}
				case "longbinary": {loc.returnValue = "cf_sql_blob"; break;}
				case "datetime": {loc.returnValue = "cf_sql_timestamp"; break;}
			}
		</cfscript>	
		<cfreturn loc.returnValue>
	</cffunction>
	
	<!--- Phord change $query --->
	<cffunction name="$query" returntype="struct" access="public" output="false">
		<cfargument name="sql" type="array" required="true">
		<cfargument name="limit" type="numeric" required="false" default=0>
		<cfargument name="offset" type="numeric" required="false" default=0>
		<cfargument name="parameterize" type="boolean" required="true">
		<cfargument name="$primaryKey" type="string" required="false" default="">
		
		<cfscript>
			var loc = {};		
		</cfscript>
		
		<!--- MS ACCESS works better with square brackets around field names in SQL INSERT statements. Allows reserved words like password for field names --->
		<cfif IsSimpleValue(arguments.sql[1]) AND (Left(arguments.sql[1], 11) IS "INSERT INTO")>
			<cfloop index="i" from ="2" to="#arrayLen(arguments.sql)#" step="2">
				<cfif arguments.sql[i - 1] eq ")">
					<cfbreak >
				</cfif>
				<cfset arguments.sql[i] = "[" & arguments.sql[i] & "]">
			</cfloop>
		</cfif>
		
		<!--- MS ACCESS works better with square brackets around field names in SQL UPDATE statements. Allows reserved words like password for field names --->
		<cfif IsSimpleValue(arguments.sql[1]) AND Left(arguments.sql[1], 6) IS "UPDATE">
			<cfloop index="i" from ="2" to="#arrayLen(arguments.sql)#">
				<cfif IsSimpleValue(arguments.sql[i]) AND right(trim(arguments.sql[i]), 1) EQ "=">		
					<cfset arguments.sql[i] = "[" & replace(arguments.sql[i], " =","] =")>
				</cfif>		
			</cfloop>
		</cfif>

		<!--- MS ACCESS doesn't support limit and offset in sql --->
		<cfscript>
			if (arguments.limit + arguments.offset gt 0)
			{
				loc.containsGroup = false;
				loc.afterWhere = "";
	
				if (IsSimpleValue(arguments.sql[ArrayLen(arguments.sql) - 1]) and FindNoCase("GROUP BY", arguments.sql[ArrayLen(arguments.sql) - 1]))
					loc.containsGroup = true;
				if (arguments.sql[ArrayLen(arguments.sql)] Contains ",")
				{
					// fix for pagination issue when ordering multiple columns with same name
					loc.order = arguments.sql[ArrayLen(arguments.sql)];
					loc.newOrder = "";
					loc.doneColumns = "";
					loc.done = 0;
					loc.iEnd = ListLen(loc.order);
					for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
					{
						loc.item = ListGetAt(loc.order, loc.i);
						loc.column = SpanExcluding(Reverse(SpanExcluding(Reverse(loc.item), ".")), " ");
						if (ListFind(loc.doneColumns, loc.column))
						{
							loc.done++;
							loc.item = loc.item & " AS tmp" & loc.done;
						}
						loc.doneColumns = ListAppend(loc.doneColumns, loc.column);
						loc.newOrder = ListAppend(loc.newOrder, loc.item);
					}
					arguments.sql[ArrayLen(arguments.sql)] = loc.newOrder;
				}
	
				// select clause always comes first in the array, the order by clause last, remove the leading keywords leaving only the columns and set to the ones used in the inner most sub query
				loc.thirdSelect = ReplaceNoCase(ReplaceNoCase(arguments.sql[1], "SELECT DISTINCT ", ""), "SELECT ", "");
				loc.thirdOrder = ReplaceNoCase(arguments.sql[ArrayLen(arguments.sql)], "ORDER BY ", "");
				if (loc.containsGroup)
					loc.thirdGroup = ReplaceNoCase(arguments.sql[ArrayLen(arguments.sql) - 1], "GROUP BY ", "");
	
				// the first select is the outer most in the query and need to contain columns without table names and using aliases when they exist
				loc.firstSelect = $columnAlias(list=$tableName(list=loc.thirdSelect, action="remove"), action="keep");
	
				// we need to add columns from the inner order clause to the select clauses in the inner two queries
				loc.iEnd = ListLen(loc.thirdOrder);
				for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
				{
					loc.iItem = ReReplace(ReReplace(ListGetAt(loc.thirdOrder, loc.i), " ASC\b", ""), " DESC\b", "");
					if (!ListFindNoCase(loc.thirdSelect, loc.iItem))
						loc.thirdSelect = ListAppend(loc.thirdSelect, loc.iItem);
					if (loc.containsGroup) {
						loc.iItem = REReplace(loc.iItem, "[[:space:]]AS[[:space:]][A-Za-z1-9]+", "", "all");
						if (!ListFindNoCase(loc.thirdGroup, loc.iItem))
							loc.thirdGroup = ListAppend(loc.thirdGroup, loc.iItem);
					}
				}
	
				// the second select also needs to contain columns without table names and using aliases when they exist (but now including the columns added above)
				loc.secondSelect = $columnAlias(list=$tableName(list=loc.thirdSelect, action="remove"), action="keep");
	
				// first order also needs the table names removed, the column aliases can be kept since they are removed before running the query anyway
				loc.firstOrder = $tableName(list=loc.thirdOrder, action="remove");
	
				// second order clause is the same as the first but with the ordering reversed
				loc.secondOrder = Replace(ReReplace(ReReplace(loc.firstOrder, " DESC\b", chr(7), "all"), " ASC\b", " DESC", "all"), chr(7), " ASC", "all");
	
				// fix column aliases from order by clauses
				loc.thirdOrder = $columnAlias(list=loc.thirdOrder, action="remove");
				loc.secondOrder = $columnAlias(list=loc.secondOrder, action="keep");
				loc.firstOrder = $columnAlias(list=loc.firstOrder, action="keep");
	
				// build new sql string and replace the old one with it
				loc.beforeWhere = "SELECT " & loc.firstSelect & " FROM (SELECT TOP " & arguments.limit & " " & loc.secondSelect & " FROM (SELECT ";
				if (ListRest(arguments.sql[2], " ") Contains " ")
					loc.beforeWhere = loc.beforeWhere & "DISTINCT ";
				loc.beforeWhere = loc.beforeWhere & "TOP " & arguments.limit+arguments.offset & " " & loc.thirdSelect & " " & arguments.sql[2];
				if (loc.containsGroup)
					loc.afterWhere = "GROUP BY " & loc.thirdGroup & " ";
				loc.afterWhere = "ORDER BY " & loc.thirdOrder & ") AS tmp1 ORDER BY " & loc.secondOrder & ") AS tmp2 ORDER BY " & loc.firstOrder;
				ArrayDeleteAt(arguments.sql, 1);
				ArrayDeleteAt(arguments.sql, 1);
				ArrayDeleteAt(arguments.sql, ArrayLen(arguments.sql));
				if (loc.containsGroup)
					ArrayDeleteAt(arguments.sql, ArrayLen(arguments.sql));
				ArrayPrepend(arguments.sql, loc.beforeWhere);
				ArrayAppend(arguments.sql, loc.afterWhere);
	
			}
			else
			{
				arguments.sql = $removeColumnAliasesInOrderClause(arguments.sql);
			}
			// MS ACCESS doesn't support limit and offset in sql
			StructDelete(arguments, "limit", false);
			StructDelete(arguments, "offset", false);
			loc.returnValue = $performQuery(argumentCollection=arguments);
		</cfscript>
		
		<cfreturn loc.returnValue>
	</cffunction>

	<!--- Phord change $identitySelect --->
	<cffunction name="$identitySelect" returntype="any" access="public" output="false">
		<cfargument name="queryAttributes" type="struct" required="true">
		<cfargument name="result" type="struct" required="true">
		<cfargument name="primaryKey" type="string" required="true">
		<cfset var loc = {}>
		<cfset var query = {}>
		<cfset loc.sql = Trim(arguments.result.sql)>
		<cfif Left(loc.sql, 11) IS "INSERT INTO" AND NOT StructKeyExists(arguments.result, $generatedKey())>
			<cfset loc.startPar = Find("(", loc.sql) + 1>
			<cfset loc.endPar = Find(")", loc.sql)>
			<cfset loc.columnList = ReplaceList(Mid(loc.sql, loc.startPar, (loc.endPar-loc.startPar)), "#Chr(10)#,#Chr(13)#, ", ",,")>
			<cfif NOT ListFindNoCase(loc.columnList, ListFirst(arguments.primaryKey))>
				<cfset loc.returnValue = {}>
				<cfset loc.tbl = SpanExcluding(Right(loc.sql, Len(loc.sql)-12), " ")>
				<cfquery attributeCollection="#arguments.queryAttributes#">									
					SELECT TOP 1 #arguments.primaryKey# 
					AS lastId 
					FROM #loc.tbl# 
					ORDER BY #arguments.primaryKey# DESC
				</cfquery>
				<cfset loc.returnValue[$generatedKey()] = query.name.lastId>
				<cfreturn loc.returnValue>
			</cfif>
		</cfif>
	</cffunction>
	
	
	<!--- Phord replaces $getColumnInfo from base.cfc to deal with MSACCESS, to allow adding new records with the bit datatype--->
	<cffunction name="$getColumnInfo" returntype="query" access="public" output="false">
		<cfargument name="table" type="string" required="true">
		<cfargument name="datasource" type="string" required="true">
		<cfargument name="username" type="string" required="true">
		<cfargument name="password" type="string" required="true">
		<cfscript>
			var loc = {};		
		</cfscript>
		
		<cfset arguments.type = "columns">

		<!--- Make a copy of the query to work with --->
		<cfset loc.returnValue = $dbinfo(argumentCollection=arguments)>
		<!--- Loop through the columns & make corrections --->
		<cfloop query="loc.returnValue">
			<!--- Replace COLUMN_DEFAULT_VALUE [empty string] with 0 for the MSACCESS Yes/No datatype.	<cfdbinfo> returns an [empty string] if MSACCESS does not have a default set for Yes/No , which prevents CFWheels from adding new records	--->
			<cfif COLUMN_DEFAULT_VALUE IS "" And TYPE_NAME IS 'Bit'>
				<cfset QuerySetCell(loc.returnValue, "COLUMN_DEFAULT_VALUE", 0, loc.returnValue.currentRow)>								
			</cfif>
			<!--- Correct the COLUMN_SIZE to 65535 for the MSACCESS Memo datatype. <cfdbinfo> returns a 0 COLUMN_SIZE for the MSACCESS Memo datatypes  --->
			<cfif TYPE_NAME IS "LongText">
				<cfset QuerySetCell(loc.returnValue, "COLUMN_SIZE", 65535, loc.returnValue.currentRow)>								
			</cfif>			
		</cfloop>
		<!--- Returned the corrected query to CFWheels --->
		<cfreturn loc.returnValue>
	</cffunction>

	<cfinclude template="../../plugins/injection.cfm">

</cfcomponent>