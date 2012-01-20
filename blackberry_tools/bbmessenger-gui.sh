#!/bin/bash
#: Title 	    : bbmessenger-gui.sh
#: Author	    : "John Lehr" <slo.sleuth@gmail.com>
#: Date		    : 08/17/2011
#: Version	    : 0.1.1
#: Description	: gui front end for bbmessenger.py 
#: Options	    : None

#: 08/17/2011   : expanded search for all text files by header, prepend output file with inode number
                

selections=$(yad --form \
    --title="BBmessenger GUI" \
    --image=gtk-index \
    --text="Checks search path for BlackBerry Messenger and Gtalk saved\nchats and interprets datecode.\n\nSelect your parameters:" \
    --field="Search Path":DIR \
    --field="Save Dir":DIR \
    --field="Open save location upon completion?":CHK)

[[ $? = 1 ]] && exit 0

for var in search save open
do
    eval $var="\${selections%%|*}"
    selections="${selections#*|}"
done

log=$(mktemp)

find "$search" -type f | \
while read chatfile
do
    textfile=$(file -bi "$chatfile")
    if [ "${textfile%%/*}" = "text" ]
    then
        head -1 "$chatfile" | grep -qE 'BlackBerry Messenger|Google Talk'
        if [ $? = 0 ]
        then
            filename="${chatfile##*/}"
            inode="$(stat -c %i "$chatfile")"
            bbmessenger.py "$chatfile" > "$save/${inode}-${filename}"
            echo -e "Processed: $chatfile,\n\tSaved as: $save/${inode}-${filename}" >> $log
        fi
    fi
done


cat $log | \
yad --text-info --title="BBmessenger GUI Log"  --button=gtk-ok --width=600 --height=400
cp $log "$save/bbm-gui_output.log"
rm $log

if [ "$open" = "TRUE" ]
then 
    nautilus "$save" & 
fi

exit 1
