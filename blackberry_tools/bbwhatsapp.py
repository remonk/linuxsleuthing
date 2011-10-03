#!/usr/bin/env python3
#: Title        : bbmessenger
#: Author       : "John Lehr" <slo.sleuth@gmail.com>
#: Date         : 10/03/2011
#: Version      : 0.1.0
#: Description  : Decode BlackBerry WhatsApp databases
#: Options      : --no-header
#: License      : GPLv3

#: 10/04/2011   : v0.1.1 initial release

import sys, argparse, sqlite3
from time import strftime, localtime

def printdb(database):
    try: 
        conn = sqlite3.connect(database)
        c = conn.cursor()

        for key_remote_jid,key_from_me,key_id,status,needs_push,data,timestamp,media_url,media_mime_type,media_wa_type,media_size,media_name,latitude,longitude,thumb_image,gap_behind,media_filename,remote_resource in c.execute('select * from messages'):

            #interpret if message sent or received
            if key_from_me == 0:
                type = 'Recd'
            else:
                type = 'Sent'

            #interpret if message read or unread
            if status == 0 or status == 5:
                status = "Read"
            elif status == 4:
                status = "Unread"
            else:
                status = "Unknown"

            #isolate phone number from jid
            who = key_remote_jid.split('@')[0]
            
            #convert timestamp to local time    
            time = strftime('%Y-%m-%d %H:%M:%S (%Z)', localtime(timestamp/1000))

            #print csv formatted output to stdout
            print('{},{},{},"{}",{},{},{}'.format(time, type, who, data, status,media_mime_type,media_url))

    except:
        print('Error: not a WhatsApp db or an incompatible version')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Process WhatsApp SMS database.',
        epilog='Converts timestamps to local time and interprets field values.  Prints to stdout.')
    parser.add_argument('database', help='a WhatsApp messageStore.db database')
    parser.add_argument('-n', '--no-header', dest='noheader', action='store_true',help='do not print filename or column header')
    parser.add_argument('-V', '--version', action='version', version='%(prog)s v0.1.1')

    args = parser.parse_args()
    
    database = args.database
    noheader = args.noheader

    if noheader:
        printdb(database)
    else:
        print('File: "{}"'.format(database))
        print("Time,Type,To/From,Message,Status,Attachment(type),Attachment(URL)")
        printdb(database)
