#!/usr/bin/env python3
#: Title        : bbmessenger
#: Author       : "John Lehr" <slo.sleuth@gmail.com>
#: Date         : 08/18/2011
#: Version      : 0.1.1
#: Description  : Decode BlackBerry Messenger/Gtalk save files
#: Options      : --no-header, --utc
#: License      : GPLv3

#: 05/26/2011   : v0.1.0 initial release
#: 08/18/2011   : v0.1.1 fixed line ending issue where inline line feeds in text message caused error
#: 10/03/2011   : v0.1.2 added help and arguments
#: 10/03/2011   : v0.1.3 added UTC output option

import sys, io, argparse
from time import strftime, localtime, gmtime

def print_records(csv):
    try:
        with io.open(csv,newline="\r\n") as db_file:
            for line_no, line in enumerate(db_file):
                if noheader and line_no == 0:
                    pass
                elif line_no == 0:
                    print(line)
                    print('Date,DateCode,Sender,Receiver,Message')
                    line_no += 1
                else:
                    datecode, sender, receiver, message = line.split(',', 3)

                    zone = localtime
                    if utc:
                        zone = gmtime

                    date = int(datecode[8:18])
                    date = strftime('%Y-%m-%d %H:%M:%S (%Z)', zone(date))
                    print('{},{},{},{},"{}"'.format(date, datecode, sender, receiver, message.strip()))
    except:
        print('Error: not a BlackBerry Messenger/Gtalk save file or an incompatible version')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Process BlackBerry Messenger/Gtalk save files.',
        epilog='Converts timestamps to local time.  Prints to stdout.')
    parser.add_argument('csv', help='a BlackBerry Messenger/Gtalk csv file')
    parser.add_argument('-n', '--no-header', dest='noheader', action='store_true',help='do not print filename or column header')
    parser.add_argument('-u', '--utc', dest='utc', action='store_true', help='Show UTC time instead of local')
    parser.add_argument('-V', '--version', action='version', version='%(prog)s v0.1.3')
    
    args = parser.parse_args()
    
    csv = args.csv
    noheader = args.noheader
    utc = args.utc

    if noheader:
        print_records(csv)
    else:
        print('File: "{}"'.format(csv))
        print_records(csv)

