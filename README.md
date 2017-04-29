# SSL Yell

SSL Yell will read a list of domains from a Google Sheet and send Pagerduty notifications for those which are expiring soon.

## Getting Started

To run SSL Yell, you need:

 A Google Sheet (format detailed below)
 
 a JSON file containing your Google service account information
 
 a Pagerduty group,
 
 and the integration key associated with that group.
 
 For information on how to acquire these, see the "Links" section below.
 
## Running the Program

To run SSL Yell:

As ruby script:

```
./ssl_yell --sheet spreadsheet --json json_filename [--out outfile] [--scheduled seconds_per_run]
```
As docker image:
```
docker build -t ssl-yell .
docker run ssl-yell --sheet spreadsheet --json json_filename [--out outfile] [--scheduled seconds_per_run]
```

spreadsheet is a link to the sheet you wish to parse.
json_filename is the path to a file containing your Google service account information in JSON format.
--out will log output to outfile, or stdout if stdout is specified.
--scheduled N will make SSL Yell run once every N seconds. When this is set, the program will not stop until it is killed.
  
To acquire the JSON file, see https://github.com/gimite/google-drive-ruby/blob/master/doc/authorization.md
under the "On behalf of no existing users (service account)" heading.
Be sure to share your document with the client_email specified in the JSON file!

The spreadsheet should contain a series of rows with the following columns:

domain  pagerduty_integration_keys    days_away_to_notify

Where domain is the domain whose SSL certificate we wish to check, pagerduty_integration_keys is a CSV containing the keys 
of the services we wish to notify, and days_away_to_notify is a CSV containing how many days from expiry until
 we send a notification.
 
 The first row of the spreadsheet will be ignored, as it is assumed to be a header. Any columns past the third will be 
 ignored and may be used for notes.
 
Example:

|SSL Managed Domain   |   Pagerduty API Key            |   Expiry Alert Interval  |
|---------------------|--------------------------------|--------------------------|
|domain.com           |   pagerdutykey1,pagerdutykey2  |   30,20,5,4,3,2,1        |

This will send Pagerduty notifications to the groups corresponding to pagerdutykey1 and pagerdutykey2 if 
the SSL certificate of domain.com is any of 30, 20, 5, 4, 3, 2, 1, or <= 0 days from expiry.

If Expiry Alert Interval is empty, it will be set to: 45, 30, 15, 7, 6, 5, 4, 3, 2, 1. Otherwise, a notification
 will be sent if expiry_date - today == days_away, or if expiry_date - today <= 0 (i.e. certificate is overdue).
 
To suppress notifications for a domain, set the alert interval to 0.
 
## Links
 
 A sample Google Sheet for SSL Yell: https://docs.google.com/spreadsheets/d/1T2UXDidfu8f1w3DPHle-a-7b2fRU6M3UHdOFAL4xxRc/edit?usp=sharing
 
 Creating and sharing Google Sheets: https://gsuite.google.com/learning-center/products/sheets/get-started/
 
 Getting the JSON file containing your Google service account information: https://github.com/gimite/google-drive-ruby/blob/master/doc/authorization.md
 under "On behalf of no existing users (service account)"
 
 Configuring Pagerduty: https://support.pagerduty.com/hc/en-us/articles/202828690-PagerDuty-Quick-Start-Guide
 
 Getting your Pagerduty Integration Key: https://support.pagerduty.com/hc/en-us/articles/202829230-Triggering-an-Incident-with-Web-UI-Email-or-API
 under "Send an Event through the API"
 
 SSL Yell architecture diagram: https://drive.google.com/file/d/0BxNcxFvdDktWampiRm5wcHR2Y0E/view?usp=sharing
 
 ## Testing
 
 To run the notify_spec.rb test, please ensure that your PAGERDUTY_KEY environment variable is set to a vaild key to which
 notifications will be sent.
