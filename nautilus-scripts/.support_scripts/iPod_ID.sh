#!/bin/bash
#iPod_ID.sh
#by John Lehr (c) 2009

# This program depends on the 'ipod' package and sleuthkit.  It is recommended 
# that it be run under the CAINE investigative environment to ensure the device
# is mounted read-only.

ATOM_NAME="name[[:alpha:]]+[[:space:]][[:alpha:]]+"
ICON="/usr/share/icons/Human/scalable/devices/gnome-dev-ipod.svg"
TITLE="iPod_ID"
TMP="/tmp/iPod_ID"
START_TIME=$(date)

rm -rf $TMP # clean up any pre-existing files

# Program_start

zenity --info \
	--title "$TITLE" \
	--window-icon="$ICON" \
	--text "iPod_ID is a tool to assist criminal investigators in determining true ownership of iPod devices."

if [ "$(id -ru)" != "0" ]; then #check for root privileges

	zenity --error \
		--window-icon="$ICON" \
		--text "You must be superuser to run this script! \n\nThe program will halt."

	exit 1

fi

# Attach device
if [ -e "/usr/bin/ipod" ]; then

	zenity --question \
		--window-icon=$ICON \
		--title "Attach Device" \
		--text "This program is intended to be run from Previewer which attaches devices read-only by default. \n\n\Attach iPod device and mount read-only before continuing."

	if [ "$?" = 1 ]; then

		exit 0

	fi

	mkdir -p /tmp/iPod_ID	

	ipod --list | tee \
		>(zenity --text-info \
			--window-icon=$ICON \
			--title "iPod Information" \
			--height 400 \
			--width 500) \
		>$TMP/ipod_info.tmp 

	if [ "$(cat $TMP/ipod_info.tmp)" = "No iPod devices present" ]; then
	
		zenity --error \
			--text "Reconnect iPod device, mount read-only, and restart program."
			
		exit 1
		
	fi

else

	zenity --error \
		--window-icon="$ICON" \
		--text "This program depends on the ipod package. \nPlease install with... \n\nsudo apt-get install ipod \n\n...and then restart iPod_ID."

	exit 1

fi

# Allocated iTunes username discovery

zenity --question \
	--title "$TITLE" \
	--window-icon=$ICON \
	--text "Do you want to search the media files \nfor ownership information?"

if [ "$?" = 0 ]; then

	i=$(sed -ne '/Mount Point:/p' $TMP/ipod_info.tmp | sed  's/   Mount Point:      //')

	find "$i" -type f -iname *.m4[pv] -exec grep -abiEHo -m2 '(name[[:alpha:]]+[[:space:]][[:alpha:]]+)|([A-Z0-9._%+-]+@[A-Z0-9.-]+\.(aero|arpa|asia|biz|cat|com|coop|edu|gov|info|jobs|mil|mobi|museum|name|net|org|pro|tel|travel))' {} \; | tee \
		>(zenity --progress \
			--window-icon=$ICON \
			--pulsate \
			--text "Searching current media files..." \
			--auto-close) \
		>$TMP/alloc_itunes_user.tmp

	if [ "$(head -1 $TMP/alloc_itunes_user.tmp)" != "" ]; then

		sed "s/name//" $TMP/alloc_itunes_user.tmp | cut -d: -f3 | sort | uniq -c > $TMP/alloc_itunes_user_summary.tmp

		ASUM=$(cat $TMP/alloc_itunes_user_summary.tmp | awk '{ print "\"" $2 " " $3 "\"" " occurs " $1 " times in allocated mp4 media files.\n" }')

	else

		ASUM="No iTunes user information found."

	fi	

	zenity --info \
		--title "iTunes Username Summary" \
		--window-icon=$ICON \
		--text "$ASUM"
fi

# Unallocated iTunes Username Information
zenity --question \
	--title "iPod_ID" \
	--window-icon=$ICON \
	--text "Do you want to search deleted files \nfor ownership information? \n\n(This could take a long time.)"

if [ "$?" = 1 ]; then
	
	DSUM="Search not conducted."

else

	i=$(sed -ne '/Device Path:/p' $TMP/ipod_info.tmp | awk '{print $3}')

	blkls $i | srch_strings -td -9 | tee 1>/dev/null \
		>(zenity --progress --pulsate --title="$TITLE" --window-icon=$ICON --text="Searching deleted data..." --auto-close  --auto-kill) \
		>(grep -E 'name[[:alpha:]]+[[:space:]][[:alpha:]]+' >> $TMP/unalloc_itunes_user_unsorted.tmp) \
		>(grep -E '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9._%+-]+\.[a-zA-Z0-9]{2,5}' | grep -Ei '\.(aero|arpa|asia|biz|cat|com|coop|edu|gov|info|jobs|mil|mobi|museum|name|net|org|pro|tel|travel)' >> $TMP/unalloc_itunes_user_unsorted.tmp)
	
	sort $TMP/unalloc_itunes_user_unsorted.tmp > $TMP/unalloc_itunes_user.tmp

	if [ "$(head -1 $TMP/unalloc_itunes_user.tmp)" != "" ]; then

		sed "s/name//" $TMP/unalloc_itunes_user.tmp | awk '{ print  $2 " " $3 }' | sort | uniq -c > $TMP/unalloc_itunes_user_summary.tmp

		DSUM=$(cat $TMP/unalloc_itunes_user_summary.tmp | awk '{ print "\"" $2 " " $3 "\"" " occurs " $1 " times in deleted mp4 media files.\n" }')

	else

		DSUM="No deleted iTunes user information found."

	fi
	
	zenity --info \
		--title "iTunes Username Summary" \
		--window-icon=$ICON \
		--text "$DSUM"

fi

# Report Generation
zenity --question \
	--title="$TITLE" \
	--window-icon=$ICON \
	--text "Do you want to generate a report?"

if [ "$?" = 0 ]; then

	CASE_NO=$(zenity --entry \
		--title "Reporting" \
		--window-icon=$ICON \
		--text="Enter Case Number:")
	
	INVESTIGATOR=$(zenity --entry \
		--title "Reporting" \
		--window-icon=$ICON \
		--text="Enter Investigator's Name:")
	
	echo -e "Case Number: \t$CASE_NO" > $TMP/report.tmp
	echo -e "Investigator: \t$INVESTIGATOR" >> $TMP/report.tmp
	echo -e "Date of Exam: \t$START_TIME\n" >> $TMP/report.tmp
	echo -e "DEVICE INFORMATION:" >> $TMP/report.tmp
	echo -e "------------------\n" >> $TMP/report.tmp
	cat $TMP/ipod_info.tmp >> $TMP/report.tmp
	echo "" >> $TMP/report.tmp
	echo -e "ACTIVE FILES iTUNES USERNAME SUMMARY:" >> $TMP/report.tmp
	echo -e "-------------------------------------\n" >> $TMP/report.tmp
	echo -e "$ASUM" >> $TMP/report.tmp
	echo -e "" >> $TMP/report.tmp
	echo -e "ACTIVE FILES iTUNES USERNAME DETAILS:" >> $TMP/report.tmp
	echo -e "-------------------------------------\n" >> $TMP/report.tmp
	echo -e "<Filename>:<File Offset>:<Matching String>\n" >> $TMP/report.tmp
	cat $TMP/alloc_itunes_user.tmp >> $TMP/report.tmp
	echo -e "" >> $TMP/report.tmp
	echo -e "DELETED FILES iTUNES USERNAME SUMMARY:" >> $TMP/report.tmp
	echo -e "--------------------------------------\n" >> $TMP/report.tmp
	echo -e "$DSUM" >> $TMP/report.tmp
	echo "" >> $TMP/report.tmp
	echo -e "DELETED FILES iTUNES USERNAME DETAILS:" >> $TMP/report.tmp
	echo -e "--------------------------------------\n" >> $TMP/report.tmp
	echo -e "<Unallocated Offset>:<Matching String>\n" >> $TMP/report.tmp
	cat $TMP/unalloc_itunes_user.tmp >> $TMP/report.tmp

	mkdir -p $HOME/Desktop/Evidence/
	cp $TMP/report.tmp $HOME/Desktop/Evidence/iPod_Report.txt
	gedit $HOME/Desktop/Evidence/iPod_Report.txt
	
fi	 

exit 0
