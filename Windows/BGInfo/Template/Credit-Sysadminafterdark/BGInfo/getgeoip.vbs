'Thanks to: 
'	https://stackoverflow.com/a/51434454
'	https://stackoverflow.com/a/5904831
'	https://stackoverflow.com/a/11600385
'	https://stackoverflow.com/a/251125

On Error Resume Next 	' enable error handling
Err.Clear

service = "seeip.org"	' seeip.org | ifconfig.co
retries = 5 			' number of retries in case of request failure
retryTimeout = 1000 	' sleep between requests, ms

Select Case service		
	Case "seeip.org" 	' appears to not be up to date as wrong location is sometimes returned
		url = "http://api.seeip.org/geoip"
		
	Case "ifconfig.co" 	' doesn't work because of CloudFlare protection, only left here as demo for multiple providers
		url = "https://ifconfig.co/json"
		
	Case Else
		Echo "Unknown service"
		Quit
End Select

Set http = CreateObject("Msxml2.ServerXMLHTTP")

http.SetOption 2, objHTTP.GetOption(2) 	' ignore SXH_SERVER_CERT_IGNORE_ALL_SERVER_ERRORS 

Do While retries > 0

	Call http.Open("GET", url, False) 	'method, url, async
	Call http.Send()

	If Err.Number <> 0 Then
		response = Err.Number & ": " & Err.Description
		
		Err.Clear
		
		If (retries > 1) Then
			Sleep(retryTimeout)
		Else
			Echo response
			Exit Do
		End If
	Else
		Set json = ParseJson(http.responseText)
		
		Select Case service				
			Case "seeip.org"
				If SupportsMember(json, "city") Then
					Echo json.city & ", " & json.country & ", " & json.organization
				Else
					Echo json.country & ", " & json.organization
				End If
				
			Case "ifconfig.co" ' doesn't work because of CloudFlare protection
				Echo http.responseText
				'Echo json.city & ", " & json.country '& ", " & json.asn_org
		End Select
		
		Exit Do
	End If
	On Error GoTo 0 ' disable any error handlers
	
	retries = retries - 1	
Loop

'--------------------------------------------------------
Function ParseJson(strJson)
    Set html = CreateObject("htmlfile")
    Set window = html.parentWindow
    window.execScript "var json = " & strJson, "JScript"
    Set ParseJson = window.json
End Function
'--------------------------------------------------------
Function SupportsMember(object, memberName)
	On Error Resume Next

	Dim x
	Eval("x = object." + memberName)

	If Err = 438 Then 
		SupportsMember = False
	Else 
		SupportsMember = True
	End If

	On Error Goto 0 'clears error
End Function
'--------------------------------------------------------