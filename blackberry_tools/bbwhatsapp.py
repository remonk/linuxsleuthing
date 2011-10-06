#!/usr/bin/env python3
#: Title        : bbwhatsapp.py
#: Author       : "John Lehr" <slo.sleuth@gmail.com>
#: Date         : 10/03/2011
#: Version      : 0.1.1
#: Description  : Decode BlackBerry WhatsApp databases
#: Options      : --no-header, --utc
#: License      : GPLv3

#: 10/03/2011   : v0.1.0 initial release
#: 10/03/2011   : v0.1.1 added UTC time output option
#: 10/04/2011   : v0.1.2 code cleanup

import argparse, sqlite3
from time import strftime, localtime, gmtime

type_flag = { 0 : 'Recd'}
status_flag = { 0 : 'Read locally', 4 : 'Unread by recipient ', 5 : 'Read by recipient' }

def printdb(args):
    '''Print BlackBerry WhatsApp messageStore.db with interpretted flags and timestamps.'''
    
    if not args.noheader:
        print('File: "{}"'.format(args.database))
        print('Time,Type,To/From,Message,Status,Attachment(type),Attachment(URL)')

    try: 
        conn = sqlite3.connect(args.database)
        c = conn.cursor()

        for key_remote_jid,key_from_me,key_id,status,needs_push,data,timestamp,media_url,media_mime_type,media_wa_type,media_size,media_name,latitude,longitude,thumb_image,gap_behind,media_filename,remote_resource in c.execute('select * from messages'):

            #interpret if message sent or received
            type = type_flag.get(key_from_me, 'Sent')

            #interpret if message read or unread
            status = status_flag.get(status, 'Unknown')

            #isolate phone number from jid
            who = key_remote_jid.split('@')[0]
            
            #convert timestamp to local time or utc
            if args.utc:
                time = strftime('%Y-%m-%d %H:%M:%S (UTC)', gmtime(timestamp/1000))
            else:
                time = strftime('%Y-%m-%d %H:%M:%S (%Z)', localtime(timestamp/1000))

            #print csv formatted output to stdout
            print('{},{},{},"{}",{},{},{}'.format(time, type, who, data, status,media_mime_type,media_url))

    except sqlite3.error:
        print('SQLite Error: wrong or incompatible database')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Process WhatsApp SMS database.',
        epilog='Converts timestamps to local time and interprets field values.  Prints to stdout.')
    parser.add_argument('database', help='a WhatsApp messageStore.db database')
    parser.add_argument('-n', '--no-header', dest='noheader', action='store_true', help='do not print filename or column header')
    parser.add_argument('-u', '--utc', dest='utc', action='store_true', help='Show UTC time instead of local')
    parser.add_argument('-V', '--version', action='version', version='%(prog)s v0.1.2')

    args = parser.parse_args()

    printdb(args)
