$Recipient = 'user@domain.com'

while($true){

$normal = Get-MailboxStatistics -Identity $Recipient | select @{N="Type";E={"Normal"}},ItemCount,TotalItemSize
$archive = Get-MailboxStatistics -Identity $Recipient -Archive | select @{N="Type";E={"Archive"}},ItemCount,TotalItemSize

clear-host;
$result = @($normal) + @($archive)
write-host $Recipient ($result | out-string);

start-sleep -s 1;

}
