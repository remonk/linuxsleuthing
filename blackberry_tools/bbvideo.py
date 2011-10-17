#!/usr/bin/env python3
#: Title        : bbvideo.py
#: Author       : "John Lehr" <slo.sleuth@gmail.com>
#: Date         : 10/17/2011
#: Version      : 0.1.0
#: Description  : Dump/interpret Black Berry videoart.dat sqlite table 
#: Options      : None
#: License      : GPLv3

import sqlite3, argparse, os
from time import strftime, localtime, gmtime

def printdb(args):
    '''Prints the rows from the BlackBerry videoart.dat, interpreting
    the fields and optionally exports thumbnail images.'''
    
    if not args.noheader:
        print('File: "{}"'.format(args.database))
        print('Date, Video Name, id, Source, Source Timestamp')
    
    try: 
        conn = sqlite3.connect(args.database)
        c = conn.cursor()

        for id, source, thumb, name, date, source_time in \
            c.execute('select  id, source, thumbnail, video_name, \
                time_stamp, source_time_stamp from video_art'):

            #convert timestamp to local time or utc
            if args.utc:
                time = strftime('%Y-%m-%d %H:%M:%S (UTC)', \
                    gmtime(date/1000))
            else:
                time = strftime('%Y-%m-%d %H:%M:%S (%Z)', \
                    localtime(date/1000))

            print('{},"{}",{},{},{}'.format(time, name[7:], id, source, 
                source_time))
        
            if args.dump:
                tname = name.split(os.path.sep)[-1] + '.jpg'
                with open(tname, 'wb') as output_file:
                    output_file.write(thumb)

    except sqlite3.Error:
            print('SQLite Error: wrong or incompatible database')

if __name__ == '__main__':
    
    parser = argparse.ArgumentParser(
        description='Process BlackBerry video_art table in videoart.dat \
            database.',
        epilog='Converts timestamps to local time and exports \
            thumbnails. Prints to stdout.')
    
    parser.add_argument('database', 
        help='a BlackBerry videoart.dat database')
    parser.add_argument('-d', '--dump_thumbs', 
        dest='dump', 
        action='store_true', 
        help='write thumbs to working directory')
    parser.add_argument('-n', '--no-header', 
        dest='noheader', 
        action='store_true', 
        help='do not print filename or column header')
    parser.add_argument('-u', '--utc', 
        dest='utc', 
        action='store_true', 
        help='Show UTC time instead of local')
    parser.add_argument('-V', '--version', 
        action='version', 
        version='%(prog)s v0.1.0')

    args = parser.parse_args()

    printdb(args)
