'https://seeip.org - more options, also location info
'https://ifconfig.me/ip - just IP address

Set http = CreateObject("Msxml2.XMLHTTP")

Call http.Open("GET", "https://ifconfig.me/ip", False) 'method, url, async
Call http.Send()

Echo http.responseText