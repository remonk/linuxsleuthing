#!/usr/bin/env python3
#: Title        : bbmessenger
#: Author       : "John Lehr" <slo.sleuth@gmail.com>
#: Date         : 05/26/2011
#: Version      : 0.1.0
#: Description  : Decode BlackBerry Messenger/Gtalk save files
#: Options      : None
#: License      : GPLv3

import sys
from time import strftime, localtime

def main(csv):
    line_no = 0
    with open(csv) as db_file:
        for line in db_file:
            if line_no == 0:
                print(line)
                print('Date,DateCode,Sender,Receiver,Message')
                line_no += 1
            else:
                datecode, sender, receiver, message = line.split(',', 3)
                date = int(datecode[8:18])
                date = strftime('%Y-%m-%d %H:%M:%S (%Z)', localtime(date))
                print('"{}",{},"{}","{}","{}"'.format(date, datecode, sender, receiver, message.strip()))

if __name__ == '__main__':
    for file in sys.argv[1:]:
        main(file)
