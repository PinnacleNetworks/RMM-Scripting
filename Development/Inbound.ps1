$ErrorActionPreference = "Stop"
####Set up Log File Rotation
####Keeps the last 10 days of log files
$LogDate = Get-Date -Format yyyy-MM-dd
$LogFile = "C:\Scripts\Logs\Inbound-$LogDate.log"
$Logcount = 10
Function LogWrite
{
    Param ([string]$logstring)
    Add-Content $LogFile -Value $logstring
}
Function Get-TimeStamp
{
    Return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}
####Variables for Script usage
$SourceFolder = '\\<NAS>\Recordings\AutoRecords'
$DestinationFolder = '\\<NAS>\Recordings\Processed'
$delim = '-'
$delim2 = '@'
$SMTPUsername = "<username>"
$EncryptedPasswordFile = "C:\Scripts\Password.txt"
$EmailCredential = New-Object -TypeName Management.Automation.PSCredential($SMTPUsername, (Get-Content $EncryptedPasswordFile | ConvertTo-SecureString))
$FType = "wav"
$FTypeNew = "aac"
$extensions =
@{
      '999' = 'email';
      '201' = 'email';
      '202' = 'email';
      '203' = 'email';
      '204' = 'email';
	  '205' = 'email';
      '206' = 'email';
	  '208' = 'email';
      '209' = 'email';
	  '210' = 'email';
	  '211' = 'email';
	  '212' = 'email';
	  '213' = 'email';
	  '214' = 'email';
	  '215' = 'email';
}
$Recordings = Get-ChildItem -Path $SourceFolder -Filter *.$FType -Recurse
ForEach ($Recording in $Recordings)
{
    $Date = Get-Date
    $FileDate = $Recording.LastWriteTime
    $Duration = $Date - $FileDate
    $DurationTotal = $Duration.TotalMinutes
    if ($DurationTotal -lt 5){Continue}
    Try
    {
        $Base = Join-Path $Recording.DirectoryName $Recording.BaseName
        $Old = $Base+".$FType"
        $New = $Base+".$FTypeNew"
        ffmpeg -i $Old $New
        LogWrite "$(Get-TimeStamp) Converted $($Recording.FullName) Successfully"
    }
    Catch
    {
       LogWrite "$(Get-TimeStamp) Error Converting $($Recording.FullName)"
    }
    Finally
    {
    }
}
ForEach ($Recording in $Recordings)
{
    Try
    {
        $Base = Join-Path $Recording.DirectoryName $Recording.BaseName
        $NewRecording = $Base+".$FTypeNew"
        $ArraySearch = $Recording.BaseName
        $NameArray = $ArraySearch.Split($delim)
        $ext = $NameArray[3]
        $CallerID = $NameArray[2]
        $DateStamp = ($NameArray[0].substring(0,8))
        $EmailAddress = $extensions[$ext]
        $FirstNameArray = $emailAddress.Split($delim2)
        $FirstName = $FirstNameArray[0]
        $Dest = $DestinationFolder+"\"+$ext
        $SMTPProperties =
            @{
                To = $EmailAddress
                From = '<emailaddress>'
                Body = 'New Call Recording'
                BodyAsHtml = $true
                Subject = "Call Recording on $DateStamp from ($CallerID) to $FirstName"
                smtpserver = '<emailserver>'
                attachment = $NewRecording
                Port = '25'
            }
		If(!(Test-Path $Dest))
            {
                New-Item -ItemType Directory $Dest
            }
        If (($ext -eq '201') -or ($ext -eq '205') -or ($ext -eq '206') -or ($ext -eq '209') -or ($ext -eq '235'))
            {
                Move-Item -Path $NewRecording -Destination $Dest
                LogWrite "$(Get-TimeStamp) Moved Recording $NewRecording for $ext to Processed Folder"
            }
        Else
        {
        Send-MailMessage @SMTPProperties
        LogWrite "$(Get-TimeStamp) Sent Recording $NewRecording to $emailaddress"
        Move-Item -Path $NewRecording -Destination $Dest
        LogWrite "$(Get-TimeStamp) Moved Recording $NewRecording for $ext to Processed Folder"

        }
    }
    Catch
    {
        LogWrite "$(Get-TimeStamp) Error Processing $NewRecording"
    }
    Finally
    {
    }
ForEach ($Recording in $Recordings)
{
    Try
    {
       $Base = Join-Path $Recording.DirectoryName $Recording.BaseName
       $OriginalFile = $Base+".$FType"
       $ArraySearch = $Recording.BaseName
       $NameArray = $ArraySearch.Split($delim)
       $ext = $NameArray[3]
       $NewPath = $DestinationFolder+"\"+$ext+"\"+(($Recording.BaseName)+".$FTypeNew")
       $TestPath = '\\<NAS>\Recordings\Test'
       if(Test-Path -Path $NewPath){Remove-Item $OriginalFile -force}
       #if(Test-Path -Path $NewPath){Move-Item -Path $OriginalFile -Destination $TestPath -force}
       LogWrite "$(Get-TimeStamp) Successfully removed $Recording from Source Folder"
    }
    Catch
    {
        LogWrite "$(Get-TimeStamp) Error removing old Recording $($Recording.FullName)"
    }
    Finally {}
    }

}