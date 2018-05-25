try
{
    $value = 1/0
}
catch
{
    $ErrorMessage = $_.Exception.Message
    #Send-MailMessage -From <EMAIL> -To <EMAIL> -Subject "Some error" -Body "We failed to read file. The error message was $ErrorMessage"
    
    $o = New-Object -com Outlook.Application 
    $mail = $o.CreateItem(0)

    #2 = high importance email header
    $mail.importance = 2
    $mail.subject = “Subject here“
    $mail.body = “Message body here“

    #for multiple email, use semi-colon ; to separate
    $mail.To = “<EMAIL>“
    $mail.Send()
    
    Write-Host $ErrorMessage
}