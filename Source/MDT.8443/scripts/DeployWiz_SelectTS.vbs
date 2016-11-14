' // ***************************************************************************
' // 
' // Copyright (c) Microsoft Corporation.  All rights reserved.
' // 
' // Microsoft Deployment Toolkit Solution Accelerator
' //
' // File:      DeployWiz_Initialization.vbs
' // 
' // Version:   6.3.8443.1000
' // 
' // Purpose:   Main Client Deployment Wizard Initialization routines
' // 
' // ***************************************************************************


Option Explicit


'''''''''''''''''''''''''''''''''''''
'  Image List
'

Dim g_AllOperatingSystems

Function AllOperatingSystems


	Dim oOSes

	If isempty(g_AllOperatingSystems) then
	
		set oOSes = new ConfigFile
		oOSes.sFileType = "OperatingSystems"
		oOSes.bMustSucceed = false
		
		set g_AllOperatingSystems = oOSes.FindAllItems
		
	End if

	set AllOperatingSystems = g_AllOperatingSystems

End function


Function InitializeTSList
	Dim oItem, sXPathOld
	
	If oEnvironment.Item("TaskSequenceID") <> "" and oProperties("TSGuid") = "" then
		
		sXPathOld = oTaskSequences.xPathFilter
		for each oItem in oTaskSequences.oControlFile.SelectNodes( "/*/*[ID = '" & oEnvironment.Item("TaskSequenceID")&"']")
			oLogging.CreateEntry "TSGuid changed via TaskSequenceID = " & oEnvironment.Item("TaskSequenceID"), LogTypeInfo
			oEnvironment.Item("TSGuid") = oItem.Attributes.getNamedItem("guid").value
			exit for
		next
		
		oTaskSequences.xPathFilter = sXPathOld 
		
	End if

	TSListBox.InnerHTML = oTaskSequences.GetHTMLEx ( "Radio", "TSGuid" )
	
	PopulateElements
	TSItemChange

End function


Function TSItemChange

	Dim oInput
	ButtonNext.Disabled = TRUE
	
	for each oInput in document.getElementsByName("TSGuid")
		If oInput.Checked then
			oLogging.CreateEntry "Found CHecked Item: " & oInput.Value, LogTypeVerbose
		
			ButtonNext.Disabled = FALSE
			exit function
		End if
	next

End function


'''''''''''''''''''''''''''''''''''''
'  Validate task sequence List
'

Function ValidateTSList

	Dim oTS
	
	set oTS = new ConfigFile
	oTS.sFileType = "TaskSequences"

	SaveAllDataElements

	If Property("TSGuid") = "" then
		oLogging.CreateEntry "No valid TSGuid found in the environment.", LogTypeWarning
		ValidateTSList = false
	End if

	oLogging.CreateEntry "TSGuid Found: " & Property("TSGuid"), LogTypeVerbose

	If oTS.FindAllItems.Exists(Property("TSGuid")) then
		oEnvironment.Item("TaskSequenceID") = oUtility.SelectSingleNodeString(oTS.FindAllItems.Item(Property("TSGuid")),"./ID")
	End if


	' Set the related properties

	oUtility.SetTaskSequenceProperties oEnvironment.Item("TaskSequenceID")

	If oEnvironment.Item("OSGUID") <> "" and oEnvironment.Item("ImageProcessor") = "" then
		' There was an OSGUID defined within the TS.xml file, however the GUID was not found 
		' within the OperatingSystems.xml file. Which is a dependency error. Block the wizard.
		ValidateTSList = False
		ButtonNext.Disabled = True
		Bad_OSGUID.style.display = "inline"
	Else
		ValidateTSList = True
		ButtonNext.Disabled = False
		Bad_OSGUID.style.display = "none"
	End if

End Function
