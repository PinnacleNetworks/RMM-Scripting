$ErrorActionPreference = "Stop"
####Set up Log File Rotation
####Keeps the last 10 days of log files
$LogDate = Get-Date -Format yyyy-MM-dd
$LogFile = "C:\Scripts\Logs\Inbound-$LogDate.log"
$Logcount = 10
Function LogWrite {
    Param ([string]$logstring)
    Add-Content $LogFile -Value $logstring
}
Function Get-TimeStamp {
    Return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}
####Variables for Script usage
$SourceFolder = '\\<NAS>\Recordings\AutoRecords'
$DestinationFolder = '\\<NAS>\Recordings\Processed'
$delim = '-'
$delim2 = '@'
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
ForEach ($Recording in $Recordings) {
    $Date = Get-Date
    $FileDate = $_.LastWriteTime
    $Duration = $Date - $FileDate
    $DurationTotal = $Duration.TotalMinutes
    if ($DurationTotal -lt 5) { Continue }
    Try {
        $Base = Join-Path $_.DirectoryName $_.BaseName
        $OldRecording = $Base + ".$FType"
        $NewRecording = $Base + ".$FTypeNew"
        Start-Process "ffmpeg" -arguementlist  "-i $OldRecording $NewRecording" -Wait
        LogWrite "$(Get-TimeStamp) Converted $($_.FullName) Successfully"
        #Splitting the Filename so we can use the pieces to extract information for later use
        #NameArray[0] contiains the datestamp in the first 8 characters
        #NameArray[2] contains the caller id of the source
        #NameArray[3] contains the destination internal extension
        $NameArray = $($_.BaseName).Split($delim)
        $EmailAddress = $extensions[$NameArray[3]]
        $FirstNameArray = $emailAddress.Split($delim2)
        $SMTPProperties =
        @{
            To         = $EmailAddress
            From       = '<emailaddress>'
            Body       = 'New Call Recording'
            BodyAsHtml = $true
            Subject    = "Call Recording on $($NameArray[0].substring(0,8)) from ($NameArray[2]) to $FirstNameArray[0]"
            smtpserver = '<emailserver>'
            attachment = $NewRecording
            Port       = '25'
        }
        $DestinationSubFolder = Join-Path $DestinationFolder $NameArray[3]
        If (!(Test-Path $DestinationSubFolder)) {
            New-Item -ItemType Directory $DestinationSubFolder
        }
        If (($NameArray[3] -eq '201') -or ($NameArray[3] -eq '205') -or ($NameArray[3] -eq '206') -or ($NameArray[3] -eq '209') -or ($NameArray[3] -eq '235')) {
            Move-Item -Path $NewRecording -Destination $DestinationSubFolder
            LogWrite "$(Get-TimeStamp) Moved Recording $NewRecording for $NameArray[3] to Processed Folder"
        }
        Else {
            Send-MailMessage @SMTPProperties
            LogWrite "$(Get-TimeStamp) Sent Recording $NewRecording to $emailaddress"
            Move-Item -Path $NewRecording -Destination $DestinationSubFolder
            LogWrite "$(Get-TimeStamp) Moved Recording $NewRecording for $NameArray[3] to Processed Folder"
        }
        Then {
                if (Test-Path -Path $NewRecording) {Remove-Item $OldRecording -force}
                LogWrite "$(Get-TimeStamp) Successfully removed $Recording from Source Folder"
        }
    }
    Catch {
        LogWrite "$(Get-TimeStamp) Error Converting $($_.FullName):$($_.Exception.Message)"
    }
    Catch {
        LogWrite "$(Get-TimeStamp) Error Processing $($NewRecording.FullName): $($_.Exception.Message)"
    }
    Catch {
            LogWrite "$(Get-TimeStamp) Error removing old Recording $($Recording.FullName): $($_.Exception.Message)"
        }
}