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
#: 10/05/2011   : v0.2.0 added directory recursion

import io, os, sys, argparse
from time import strftime, localtime, gmtime

def recurse_directory(dir):
    if os.path.isdir(dir):
        for root, dirs, files in os.walk(dir):
            for name in files:
                file = os.path.join(root,name)
                if file[-3:] == 'OLD' or file[-3:] == 'csv':
                    args.csv = file
                    print_records(args)
    else:
        print('Error: "{}" not a directory'.format(dir), file=sys.stderr)

def print_records(args):
    '''Print records from BlackBerry Messenger and Gtalk save files'''
    
    if not args.noheader:
        print('File: "{}"'.format(args.csv))
        print('Date,DateCode,Sender,Receiver,Message')

    try:
        with io.open(args.csv, newline="\r\n") as db_file:
            for line_no, line in enumerate(db_file):
                if line_no == 0:                    
                    line_no += 1
                else:
                    #create objects from row items
                    datecode, sender, receiver, message = line.split(',', 3)

                    #convert datecode to local time or UTC
                    date = int(datecode[8:18])
                    if args.utc:
                        date = strftime('%Y-%m-%d %H:%M:%S (UTC)', gmtime(date))
                    else:
                        date = strftime('%Y-%m-%d %H:%M:%S (%Z)', localtime(date))

                    #print results to stdout
                    print('{},{},{},{},"{}"'.format(date, datecode, sender, receiver, message.strip()))
    
    except IOError:
        print('Error: not a BlackBerry Messenger/Gtalk save file or an incompatible version', file=sys.stderr)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Process BlackBerry Messenger/Gtalk save files.',
        epilog='Converts timestamps to local time.  Prints to stdout.')
    
    parser.add_argument('csv', help='a BlackBerry Messenger/Gtalk csv file')
    parser.add_argument('-d', '--directory', dest='directory', action='store_true', help='treat csv argument as dir to recurse')
    parser.add_argument('-n', '--no-header', dest='noheader', action='store_true',help='do not print filename or column header')
    parser.add_argument('-u', '--utc', dest='utc', action='store_true', help='Show UTC time instead of local')
    parser.add_argument('-V', '--version', action='version', version='%(prog)s v0.2.0')
    
    args = parser.parse_args()

    if args.directory:
        recurse_directory(args.csv)
    else:
        print_records(args)

