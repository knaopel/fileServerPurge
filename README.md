# fileServerPurge
PowerShell 3.0 Script to cleanse and purge a series of sub folders.  
This script looks at a given directory, iterates through the directories it finds at that path and deletes all the contents of these Directories - but not the top directories themselves.
* Logging to Windows Event Viewer
* Notifications use Office 365 Email (Exchange Online) to send notifications upon any encountered errors.

## Setup
### Save Credentials
Office 365 Email needs credentials in order to send the email, so run the following command:  
`.\New-EncryptedCredentialsFile.ps1 [-Username "username@domain.com"]`  
If you don't supply the "-Username" it will prompt you for it.  
It will ultimately prompt the user for the password to the account and then save it in an encrypted form to a file named "encrypted-credentials.xml"
### Generate Test Data
There is a script to generate test data:  
`.\New-TestData.ps1 -Path DRIVE:\Path\to\directory`  
This creates 10 folders with random names with 0-6 subfolders each. Each folder and subfolder contains 10-20 text files ranging in size from 1k to 800k.
## Usage
To run this script - and/or run in the task scheduler - use the following command:  
`.\Purge-FileServerDirectories.ps1 -Path DRIVE:\Path\to\directory -EmailRecipient user@office365domain.com` 
If this is being run in the Task Scheduler, make sure the user which is running the task has the rights to write and delete from that directory.
### Parameters
#### -Path
Specifies the path on the computer from which to itereate through sub-folders and delete the contens therein.  
`Type: string`  
`Required: true`  
`Default value: none`
#### -EmailRecipient
Specifies the email or distribution list which to send any notification emails.  
`Type: string`  
`Required: true`  
`Default value: none`
