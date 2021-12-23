#!/usr/bin/env python3
import urllib.error
import urllib.parse
import urllib.request

if __name__ == "__main__":
    tld_list = ['@"LOCAL"']
    for line in urllib.request.urlopen(
        "http://data.iana.org/TLD/tlds-alpha-by-domain.txt"
    ):
        line = line.decode()
        if line[0] == "#":
            continue
        line = '@"{0}"'.format(line.strip())
        tld_list.append(line)
    print(
        "Drop the following line into QSObject_StringHandling.m to update the "
        "TLDs Quicksilver registers\n"
    )
    print(("tldArray = @[{0}];".format(", ".join(tld_list))))
