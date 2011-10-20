#!/usr/bin/env python3
#: Title        : iphone_safariHist.py
#: Author       : "John Lehr" <slo.sleuth@gmail.com>
#: Date         : 10/19/2011
#: Version      : 0.1.1
#: Description  : Decode Safari History.plist files
#: Options      : --no-header, --utc, 
#: License      : GPLv3

from xml.dom import minidom
from time import strftime, localtime, gmtime
import sys, argparse, subprocess

def convert_bplist(file):
    '''Calls plutil in subprocess to decode binary plist.'''
    
    pipe = subprocess.Popen(['plutil', '-i', file], 
        stdout=subprocess.PIPE)
    plist = pipe.communicate()[0]
    plist = plist.decode()
        
    return plist

def BuildDict(dict_node):
    '''Parse safari history 'dict' nodes into dictionary.'''

    key = ""
    result = {}

    for element in dict_node.childNodes:
        contents = element.childNodes
        if element.nodeName == "key" and contents:
            key = contents[0].nodeValue
        elif element.nodeName == "string":
            result[key] = contents[0].nodeValue
            key = ""
        elif element.nodeName == "integer":
            result[key] = int(contents[0].nodeValue)
            key = ""

    return result

def main(plist):
    '''Parse xml string from Safari History.plist'''
    
    try:
        data = []
        
        xmldoc = minidom.parseString(plist)
        dict_list = xmldoc.getElementsByTagName('dict')
        
        if not args.noheader:
            print('"Last Visited","Page Title","Page URL","Visit Count"')

        for record in dict_list[1:]:
            item = (BuildDict(record))
            title = item.get('title','')
            url = item.get('','')
            visits = item.get('visitCount','')
            lastvisit = int(float(item.get('lastVisitedDate',''))) + \
                    978307200

            if args.utc:
                lastvisit = strftime('%Y-%m-%d %H:%M:%S (UTC)', \
                    gmtime(lastvisit))
            else:
                lastvisit = strftime('%Y-%m-%d %H:%M:%S (%Z)', \
                    localtime(lastvisit))
            
            data.append('{},"{}",{},{}'.format(lastvisit,title,url,\
                visits))

        data.sort()
        return data

    except:
        print('Error: "{}" is an incompatible or improper bplist file.'.\
            format(args.plist))

if __name__ == '__main__':
    
    parser = argparse.ArgumentParser(
        description='Process Apple Safari History.plist.',
        epilog='Converts timestamps to local time.  libplist required.')

    parser.add_argument('plist', 
        help='a Safari History.plist file')
    parser.add_argument('-n', '--no-header', 
        dest='noheader', 
        action='store_true',
        help='do not print file name, version, or column headers')
    parser.add_argument('-u', '--utc', 
        dest='utc', 
        action='store_true', 
        help='Show UTC time instead of local')
    parser.add_argument('-V', '--version', 
        action='version', 
        version='%(prog)s v0.1.2')

    args = parser.parse_args()
    plist = convert_bplist(args.plist)

    try:
        for line in main(plist):
            print(line)
    except TypeError:
        pass
