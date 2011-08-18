#!/usr/bin/env python3
#: Title        : bbmessenger
#: Author       : "John Lehr" <slo.sleuth@gmail.com>
#: Date         : 08/18/2011
#: Version      : 0.1.1
#: Description  : Decode BlackBerry Messenger/Gtalk save files
#: Options      : None
#: License      : GPLv3

#: 05/26/2011   : v0.1.0 initial release
#: 08/18/2011   : v0.1.1 fixed line ending issue where inline line feeds in text message caused error

import sys, io
from time import strftime, localtime

def print_records(csv):
    with io.open(csv,newline="\r\n") as db_file:
        for line_no, line in enumerate(db_file):
            if line_no == 0:
                print(line)
                print('Date,DateCode,Sender,Receiver,Message')
                line_no += 1
            else:
                datecode, sender, receiver, message = line.split(',', 3)
                date = int(datecode[8:18])
                date = strftime('%Y-%m-%d %H:%M:%S (%Z)', localtime(date))
                print('"{}",{},"{}","{}","{!r}"'.format(date, datecode, sender, receiver, message.strip()))

if __name__ == '__main__':
    for file in sys.argv[1:]:
        print_records(file)
