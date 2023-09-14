#!/usr/bin/env bash

# a script to monitor changes in a website and send an email alert if ANY change occurs
# intended to be used through a cronjob
# example crontab:
# */15 * * * * /Users/julian/bin/website_diff.sh

###############################
##########   CONFIG  ##########
PATH_TO_FILES="/path/to/tmp/website_diff"

#Enter urls here, each URL in quotes on a new line
URLS=(
	"https://example.com"
	)
#List emails that should receive alerts (comma separated)
EMAILS="anonymous@example.com"
########## END CONFIG ##########
################################

#Move to the files' path.  This is to facilitate running this script in cron.
cd $PATH_TO_FILES

for URL in "${URLS[@]}"
do
	#Make url into a valid filename (replaces chars in brackets with a dash)
	NEW_FILE="${URL//[:\/.?]/-}.new.html"
	OLD_FILE="${URL//[:\/.?]/-}.old.html"
	#Move the existing file, in preparation of a new file
	mv temp/$NEW_FILE  temp/$OLD_FILE
	#Download the url
	curl "$URL" -L --compressed -s > temp/$NEW_FILE
	#Compare the two files looking for any differences
	if ! diff temp/$NEW_FILE temp/$OLD_FILE; then
		#If differences are found, send an alert via email.
		MESSAGE="This is an alert that site ${URL} has changed.
Diff:
$(diff temp/$NEW_FILE temp/$OLD_FILE)"

            	for EMAIL in $(echo $EMAILS | tr "," " "); do
                	SUBJECT="$URL has changed"
                	echo "$MESSAGE" | mail -s "$SUBJECT" $EMAIL
                	echo $SUBJECT
                	echo "Alert sent to $EMAIL"
            done

		#Copy the new version of the webpage to the archive.
		cp temp/$NEW_FILE archive/$(date +%F-%T)-$NEW_FILE
	fi
done
